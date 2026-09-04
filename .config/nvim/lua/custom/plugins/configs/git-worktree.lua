-- ==========================================
-- Worktrees via worktrunk (https://github.com/max-sixty/worktrunk)
--
-- Replaces ThePrimeagen/git-worktree.nvim. worktrunk owns worktree layout
-- (paths come from its configurable template), branch creation, and hooks;
-- this file just shells out to `wt` and moves Neovim's cwd/buffers.
--
-- Every `wt` call is async with a spinner — `wt list` walks each worktree's
-- git status and `wt switch --create` runs hooks, so neither should block the
-- UI.
--
-- Requires: `brew install worktrunk` (or cargo/pacman). The shell `cd`
-- integration is irrelevant here — we always pass --no-cd and read the
-- resulting path out of `--format json`.
-- ==========================================

-- Files copied from the source worktree into a freshly created one. Prefer
-- moving these to a worktrunk post-create hook (see `wt hook --help` and
-- `wt step copy-ignored`); set to {} once you do.
local COPY_ON_CREATE = { '.env*', '.husky' }

local SPINNER = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }
local SPINNER_ID = 'worktrunk-progress'

--- Spin until the returned function is called.
---@param msg string
---@return fun() stop
local function progress(msg)
  local ok, snacks = pcall(require, 'snacks')
  local notifier = ok and snacks.notifier or nil
  local timer = vim.uv.new_timer()
  local frame = 0

  local function render()
    frame = frame % #SPINNER + 1
    local text = SPINNER[frame] .. '  ' .. msg
    if notifier then
      -- Same id every tick, so the notification updates instead of stacking.
      notifier.notify(text, 'info', { id = SPINNER_ID, title = 'worktrunk', timeout = false })
    else
      vim.api.nvim_echo({ { text } }, false, {})
    end
  end

  render()
  if timer then
    timer:start(80, 80, vim.schedule_wrap(render))
  end

  return function()
    if timer then
      timer:stop()
      if not timer:is_closing() then
        timer:close()
      end
    end
    if notifier then
      notifier.hide(SPINNER_ID)
    else
      vim.api.nvim_echo({ { '' } }, false, {})
    end
  end
end

local function wt_bin()
  return vim.g.worktrunk_bin or 'wt'
end

--- Run `wt` asynchronously; calls `on_done` with stdout, or nil on failure.
---@param args string[]
---@param on_done fun(stdout: string|nil)
local function wt(args, on_done)
  local bin = wt_bin()
  if vim.fn.executable(bin) ~= 1 then
    vim.notify('worktrunk not found on PATH (`brew install worktrunk`)', vim.log.levels.ERROR)
    return on_done(nil)
  end

  local cmd = vim.list_extend({ bin }, args)
  vim.system(
    cmd,
    { text = true },
    vim.schedule_wrap(function(res)
      if res.code ~= 0 then
        vim.notify('wt ' .. table.concat(args, ' ') .. '\n' .. vim.trim(res.stderr or ''), vim.log.levels.ERROR)
        return on_done(nil)
      end
      on_done(res.stdout or '')
    end)
  )
end

--- `wt list --format json`, worktrees only.
---@param on_done fun(worktrees: table[])
local function list_worktrees(on_done)
  -- json-schema is pinned: worktrunk warns that a future release defaults to
  -- schema 2, which may rename the fields read below. full=false keeps the
  -- picker off the network — --full adds CI status and LLM summaries.
  local args = {
    '--config-set',
    'list.json-schema=1',
    '--config-set',
    'list.full=false',
    'list',
    '--format',
    'json',
    '--no-progressive',
  }

  wt(args, function(out)
    if not out then
      return on_done {}
    end

    local ok, decoded = pcall(vim.json.decode, out)
    if not ok or type(decoded) ~= 'table' then
      vim.notify('Could not parse `wt list --format json`', vim.log.levels.ERROR)
      return on_done {}
    end

    on_done(vim.tbl_filter(function(entry)
      return entry.path ~= nil and entry.kind == 'worktree'
    end, decoded))
  end)
end

--- Load the worktree list behind a spinner.
---@param msg string
---@param on_done fun(worktrees: table[])
local function with_worktrees(msg, on_done)
  local stop = progress(msg)
  list_worktrees(function(worktrees)
    stop()
    on_done(worktrees)
  end)
end

--- Point Neovim at `path`: cwd, plus any buffer that has a counterpart there.
---@param path string
local function enter_worktree(path)
  local old_root = vim.fn.getcwd()
  if vim.fn.isdirectory(path) == 0 then
    vim.notify('Worktree path does not exist: ' .. path, vim.log.levels.ERROR)
    return
  end

  vim.api.nvim_set_current_dir(path)

  -- Re-point clean, loaded buffers at the same file in the new worktree.
  -- Modified buffers and files with no counterpart are left alone.
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_name(buf) or ''
    local rel = name ~= '' and name:sub(1, #old_root + 1) == old_root .. '/' and name:sub(#old_root + 2) or nil

    if rel and not vim.bo[buf].modified and vim.fn.filereadable(path .. '/' .. rel) == 1 then
      vim.api.nvim_buf_set_name(buf, path .. '/' .. rel)
      vim.api.nvim_buf_call(buf, function()
        vim.cmd 'silent! edit!'
      end)
    end
  end

  vim.notify('Worktree: ' .. vim.fn.fnamemodify(path, ':~'), vim.log.levels.INFO)
  vim.api.nvim_exec_autocmds('User', { pattern = 'WorktrunkSwitch', data = { path = path } })
end

--- `wt switch` with JSON output; calls `on_done` with the resolved path.
---@param args string[] extra args after `switch`
---@param on_done fun(path: string|nil, result: table|nil)
local function switch(args, on_done)
  local argv = vim.list_extend({ 'switch' }, args)
  vim.list_extend(argv, { '--format', 'json', '--no-cd', '--yes' })

  wt(argv, function(out)
    if not out then
      return on_done(nil)
    end

    local ok, result = pcall(vim.json.decode, vim.trim(out))
    if not ok or type(result) ~= 'table' or not result.path then
      vim.notify('Unexpected `wt switch` output:\n' .. out, vim.log.levels.ERROR)
      return on_done(nil)
    end

    on_done(result.path, result)
  end)
end

--- Prompt for a branch, then create (or attach to) its worktree.
---@param base string worktrunk base selector: `^` default branch, `@` current
local function create_worktree(base)
  local source_root = vim.fn.getcwd()

  vim.ui.input({ prompt = 'Worktree branch (base: ' .. base .. '): ' }, function(input)
    input = input and vim.trim(input) or ''
    if input == '' then
      return
    end

    -- worktrunk's --create fails on an existing branch; plain switch attaches
    -- a worktree to it instead.
    local exists = vim.system({ 'git', 'rev-parse', '--verify', '--quiet', input }, { text = true }):wait().code == 0
    local args = exists and { input } or { '--create', input, '--base', base }
    local stop = progress((exists and 'Attaching worktree to ' or 'Creating worktree ') .. input .. '…')

    switch(args, function(path, result)
      stop()
      if not path then
        return
      end

      if result and result.action == 'created' then
        for _, item in ipairs(COPY_ON_CREATE) do
          for _, src in ipairs(vim.fn.glob(source_root .. '/' .. item, false, true)) do
            vim.system({ 'cp', '-R', src, path .. '/' }):wait()
          end
        end
      end

      enter_worktree(path)
    end)
  end)
end

local function pick_worktree()
  with_worktrees('Loading worktrees…', function(worktrees)
    if vim.tbl_isempty(worktrees) then
      vim.notify('No worktrees found', vim.log.levels.WARN)
      return
    end

    vim.ui.select(worktrees, {
      prompt = 'Worktrees',
      format_item = function(entry)
        local tree = entry.working_tree or {}
        local dirty = (tree.modified or tree.staged or tree.untracked or tree.deleted) and ' ●' or ''
        local marker = entry.is_current and '* ' or '  '
        return marker .. (entry.branch or '(detached)') .. dirty .. '  ' .. vim.fn.fnamemodify(entry.path, ':~')
      end,
    }, function(choice)
      if choice then
        enter_worktree(choice.path)
      end
    end)
  end)
end

local function remove_worktree()
  local cwd = vim.fn.getcwd()

  -- Resolve the main worktree *before* removing: `wt remove` moves the target
  -- into .git/wt/trash, so anything run from cwd afterwards (including
  -- `wt list`) is running in a directory that no longer exists.
  with_worktrees('Loading worktrees…', function(worktrees)
    local main
    for _, entry in ipairs(worktrees) do
      if entry.is_main then
        main = entry
      end
      if entry.is_current and entry.is_main then
        vim.notify('Refusing to remove the main worktree', vim.log.levels.WARN)
        return
      end
    end
    if not main then
      return
    end

    vim.ui.select({ 'No', 'Yes' }, { prompt = 'Remove worktree ' .. vim.fn.fnamemodify(cwd, ':~') .. '?' }, function(choice)
      if choice ~= 'Yes' then
        return
      end

      -- Run from the main worktree so the removal survives its own cwd going
      -- away. worktrunk deletes the branch too if it has been merged.
      local stop = progress 'Removing worktree…'
      wt({ '-C', main.path, 'remove', '--yes', cwd }, function(out)
        stop()
        if out then
          enter_worktree(main.path)
        end
      end)
    end)
  end)
end

-- ==========================================
-- Plugin Configuration
--
-- No worktree plugin is needed anymore — worktrunk is the backend and the
-- pickers/prompts go through vim.ui.select / vim.ui.input (telescope-ui-select
-- and snacks.input respectively). The keymaps hang off snacks so lazy.nvim
-- still owns them.
-- ==========================================
return {
  'folke/snacks.nvim',
  opts = { input = { enabled = true } },
  keys = {
    {
      '<leader>gwl',
      pick_worktree,
      desc = 'List Worktrees',
    },
    {
      '<leader>gwc',
      function()
        -- `^` is worktrunk's shortcut for the repo's default branch.
        create_worktree '^'
      end,
      desc = 'Create Worktree (From default branch)',
    },
    {
      '<leader>gwC',
      function()
        -- `@` is worktrunk's shortcut for the current branch.
        create_worktree '@'
      end,
      desc = 'Create Worktree (From Current Branch)',
    },
    {
      '<leader>gwy',
      function()
        local res = vim.system({ 'git', 'rev-parse', '--abbrev-ref', 'HEAD' }, { text = true }):wait()
        local branch = vim.trim(res.stdout or '')
        if res.code ~= 0 or branch == '' then
          vim.notify('Not in a git repository', vim.log.levels.WARN)
          return
        end
        vim.fn.setreg('+', branch)
        vim.notify('Copied: ' .. branch, vim.log.levels.INFO)
      end,
      desc = 'Copy Worktree/Branch Name',
    },
    {
      '<leader>gwd',
      remove_worktree,
      desc = 'Remove Current Worktree',
    },
  },
}

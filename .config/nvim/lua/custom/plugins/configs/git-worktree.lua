local function create_smart_worktree(base_branch)
  local git_root = vim.fn.system('git rev-parse --show-toplevel 2>/dev/null'):gsub('%s+', '')
  if git_root == '' then
    vim.notify('Not in a git repository', vim.log.levels.WARN)
    return
  end

  vim.ui.input({ prompt = 'Worktree Name (base: ' .. base_branch .. '): ' }, function(input)
    if not input or input == '' then
      return
    end

    local parent_dir = vim.fn.fnamemodify(git_root, ':h')
    local worktrees_dir = parent_dir .. '/worktrees'
    local target_path = worktrees_dir .. '/' .. input

    if vim.fn.isdirectory(worktrees_dir) == 0 then
      vim.fn.mkdir(worktrees_dir, 'p')
    end

    local check_branch = vim.fn.system('git rev-parse --verify ' .. input .. ' 2>/dev/null'):gsub('%s+', '')

    local cmd = ''
    if check_branch ~= '' then
      vim.notify('Attaching worktree to existing branch: ' .. input, vim.log.levels.INFO)
      cmd = string.format('git worktree add %s %s', target_path, input)
    else
      vim.notify('Creating new branch from ' .. base_branch, vim.log.levels.INFO)
      cmd = string.format('git worktree add -b %s %s %s', input, target_path, base_branch)
    end

    local out = vim.fn.system(cmd)

    if vim.v.shell_error ~= 0 then
      vim.notify('Git Error: ' .. out, vim.log.levels.ERROR)
      return
    end

    local ignored_items = { '.env*', '.husky' }
    for _, item in ipairs(ignored_items) do
      local src = git_root .. '/' .. item
      if vim.fn.empty(vim.fn.glob(src)) == 0 then
        vim.fn.system(string.format('cp -R %s %s/', src, target_path))
      end
    end

    require('git-worktree').switch_worktree(target_path)
  end)
end

-- ==========================================
-- Plugin Configuration
-- ==========================================
return {
  'ThePrimeagen/git-worktree.nvim',
  dependencies = {
    { 'folke/snacks.nvim', opts = { input = { enabled = true } } },
  },
  config = function()
    require('telescope').load_extension 'git_worktree'
    require('git-worktree').setup {}
  end,
  keys = {
    {
      '<leader>gwl',
      function()
        require('telescope').extensions.git_worktree.git_worktrees()
      end,
      desc = 'List Worktrees',
    },
    {
      '<leader>gwc',
      function()
        local base_branch = 'master'
        local has_main = vim.fn.system('git show-ref --verify refs/heads/main 2>/dev/null'):gsub('%s+', '')
        if has_main ~= '' then
          base_branch = 'main'
        end
        create_smart_worktree(base_branch)
      end,
      desc = 'Create Worktree (From main/master)',
    },
    {
      '<leader>gwC',
      function()
        local base_branch = vim.fn.system('git rev-parse --abbrev-ref HEAD 2>/dev/null'):gsub('%s+', '')
        create_smart_worktree(base_branch)
      end,
      desc = 'Create Worktree (From Current Branch)',
    },
    {
      '<leader>gwy',
      function()
        local branch = vim.fn.system('git rev-parse --abbrev-ref HEAD 2>/dev/null'):gsub('%s+', '')
        if branch == '' then
          vim.notify('Not in a git repository', vim.log.levels.WARN)
          return
        end
        vim.fn.setreg('+', branch)
        vim.notify('Copied: ' .. branch, vim.log.levels.INFO)
      end,
      desc = 'Copy Worktree/Branch Name',
    },
  },
}

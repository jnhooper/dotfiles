-- Builds browsable git web URLs (GitHub-shaped) for a path on disk.
-- Shared by the oil keymaps and the global yank-reference keymaps.

local M = {}

-- Run git in the file's own directory, so results describe the file's repo
-- rather than whatever nvim's cwd happens to be.
local function git(dir, ...)
  local ok, res = pcall(function(...)
    return vim.system({ 'git', '-C', dir, ... }, { text = true }):wait()
  end, ...)
  if not ok or res.code ~= 0 then
    return nil
  end
  local out = vim.trim(res.stdout or '')
  return out ~= '' and out or nil
end

-- Default branch, preferring what the remote actually says over what we happen
-- to have checked out locally.
local function default_branch(dir)
  local head = git(dir, 'symbolic-ref', '--short', 'refs/remotes/origin/HEAD')
  if head then
    return (head:gsub('^origin/', ''))
  end
  for _, name in ipairs { 'main', 'master' } do
    -- No --quiet: we detect success by the sha it prints.
    if git(dir, 'show-ref', '--verify', 'refs/remotes/origin/' .. name) then
      return name
    end
  end
  return git(dir, 'rev-parse', '--abbrev-ref', 'HEAD')
end

---@param abspath string absolute path to the file or directory
---@param opts? { default_branch?: boolean, lstart?: integer, lend?: integer }
---@return string|nil url, string|nil err
function M.url(abspath, opts)
  opts = opts or {}
  local dir = vim.fs.dirname(abspath)

  local root = git(dir, 'rev-parse', '--show-toplevel')
  if not root then
    return nil, 'Not in a git repository'
  end

  local remote = git(dir, 'config', '--get', 'remote.origin.url')
  if not remote then
    return nil, 'No remote origin found'
  end

  local branch
  if opts.default_branch then
    branch = default_branch(dir)
  else
    branch = git(dir, 'rev-parse', '--abbrev-ref', 'HEAD')
  end
  if not branch then
    return nil, 'Could not determine branch'
  end

  -- Normalize the remote into a browsable https URL
  local web = remote:gsub('%.git$', '')
  web = web:gsub('^ssh://git@', 'https://'):gsub('^git@([^:]+):', 'https://%1/')

  local relative = vim.fs.relpath(root, abspath) or abspath:sub(#root + 2)
  local url = string.format('%s/blob/%s/%s', web, branch, (relative:gsub(' ', '%%20')))

  -- GitHub repeats the L on the end of a range: #L42-L58
  if opts.lstart then
    url = url .. '#L' .. opts.lstart
    if opts.lend and opts.lend ~= opts.lstart then
      url = url .. '-L' .. opts.lend
    end
  end

  return url
end

return M

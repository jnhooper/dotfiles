-- return to normal mode
vim.keymap.set('i', 'jj', '<Esc>')

-- remap semicolon to colon for faster commands
vim.keymap.set('n', ';', ':')

-- move to the next buffer
vim.keymap.set('n', '<Tab>', '<cmd>bnext<CR>')
vim.keymap.set('n', '<S-Tab>', '<cmd>bprev<CR>')

-- close buffer
vim.keymap.set('n', '<leader>x', '<cmd>enew<bar>bd #<CR>', { desc = '[x] out of buffer' })
vim.keymap.set('n', '<leader>cb', '<cmd>%bd|e#|bd# <CR>', { desc = '[c]lose all [b]uffers' })

vim.keymap.set('n', 'D', vim.diagnostic.open_float, { desc = 'open Float diagnostics' })

vim.keymap.set('n', '-', '<CMD>Oil --float <CR>', { desc = 'Open parent directory in oil' })
vim.keymap.set('n', '<leader>ci', 'i- [ ]', { desc = '[c]heckbox [i]nsert' })

-- ==========================================
-- Yank a reference to the current buffer + line(s)
-- ==========================================
local function cursor_range(visual)
  if not visual then
    local line = vim.fn.line '.'
    return line, line
  end
  -- The '< and '> marks are only set after leaving visual mode, so read the
  -- live selection instead.
  local first, last = vim.fn.line 'v', vim.fn.line '.'
  if first > last then
    first, last = last, first
  end
  return first, last
end

local function yank_ref(visual, as_url)
  local abs = vim.api.nvim_buf_get_name(0)
  if abs == '' then
    vim.notify('No file in this buffer', vim.log.levels.WARN)
    return
  end

  local lstart, lend = cursor_range(visual)
  if visual then
    -- Leave visual mode like a real yank does, now that the range is captured.
    vim.api.nvim_feedkeys(vim.keycode '<Esc>', 'n', false)
  end
  local ref, err

  if as_url then
    ref, err = require('custom.utils.gitweb').url(abs, {
      default_branch = true,
      lstart = lstart,
      lend = lend,
    })
  else
    -- Prefer a git-root-relative path so the ref still resolves for an agent
    -- running at the repo root, even when nvim was launched from a subdirectory.
    local root = vim.fs.root(0, '.git')
    local path = (root and vim.fs.relpath(root, abs)) or vim.fn.fnamemodify(abs, ':.')
    -- Claude ranges do not repeat the L: #L42-58
    ref = (lstart == lend) and string.format('@%s#L%d', path, lstart) or string.format('@%s#L%d-%d', path, lstart, lend)
  end

  if not ref then
    vim.notify(err or 'Could not build reference', vim.log.levels.WARN)
    return
  end

  vim.fn.setreg('+', ref)
  vim.notify('Copied: ' .. ref, vim.log.levels.INFO)
end

-- Normal mode keeps the bare `yc`/`yg` mnemonics from oil: `y` is an operator
-- already awaiting a motion there, so nothing is shadowed. Visual mode uses
-- <leader> because a bare `yc` would make every plain visual `y` wait out
-- 'timeoutlen' first.
vim.keymap.set('n', 'yc', function()
  yank_ref(false, false)
end, { desc = '[y]ank [c]laude ref (@file#Lline)' })

vim.keymap.set('x', '<leader>yc', function()
  yank_ref(true, false)
end, { desc = '[y]ank [c]laude ref for selection' })

vim.keymap.set('n', 'yg', function()
  yank_ref(false, true)
end, { desc = '[y]ank [g]ithub url (main/master)' })

vim.keymap.set('x', '<leader>yg', function()
  yank_ref(true, true)
end, { desc = '[y]ank [g]ithub url for selection' })

-- Common function to set up mappings for each case
local function setup_textcase_keymaps(key, case, desc, op_desc)
  -- Normal mode: Convert current word
  vim.keymap.set('n', 'ga' .. key, function()
    require('textcase').current_word(case)
  end, { noremap = true, silent = true, desc = 'Convert to ' .. desc })
  -- Normal mode: LSP rename
  vim.keymap.set('n', 'ga' .. key:upper(), function()
    require('textcase').current_word(case)
  end, { noremap = true, silent = true, desc = 'LSP rename to ' .. desc })
  -- Normal mode: Operator
  vim.keymap.set('n', 'gao' .. key, function()
    require('textcase').operator(case)
  end, { noremap = true, silent = true, desc = op_desc })
  -- Visual mode: Operator
  vim.keymap.set('x', 'ga' .. key, function()
    require('textcase').operator(case)
  end, { noremap = true, silent = true, desc = 'Convert to ' .. desc })
end

-- Define key mappings for various cases
setup_textcase_keymaps('k', 'to_dash_case', 'kebab-case', 'to-kebab-case')
setup_textcase_keymaps('d', 'to_dot_case', 'dot.case', 'to.dot.case')
setup_textcase_keymaps('t', 'to_title_case', 'Title Case', 'To Title Case')
setup_textcase_keymaps('/', 'to_path_case', 'path/case', 'to/path/case')
setup_textcase_keymaps('<space>', 'to_phrase_case', 'phrase case', 'to phrase case')

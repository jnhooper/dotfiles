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

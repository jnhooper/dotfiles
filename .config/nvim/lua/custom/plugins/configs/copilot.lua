return {
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',
  event = 'InsertEnter',
  config = function()
    require('copilot').setup {
      suggestion = {
        enabled = true,
        auto_trigger = true,
        keymap = {
          accept = '<C-space>',
          accept_word = '<C-l>',
          accept_line = '<C-j>',
        },
      },
      panel = { enabled = false },
      filetypes = {
        ['*'] = true, -- Disable Copilot for all file types by default
        markdown = false, -- Disable Copilot for Markdown files
      },
    }
  end,
}

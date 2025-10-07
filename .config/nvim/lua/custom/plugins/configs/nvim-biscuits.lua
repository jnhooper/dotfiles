return {
  'code-biscuits/nvim-biscuits',
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
  },
  config = function()
    require('nvim-biscuits').setup {
      ensure_installed = 'maintained',
      cursor_line_only = true,
    }
  end,
}

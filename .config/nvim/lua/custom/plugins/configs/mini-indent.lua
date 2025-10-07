return {
  'echasnovski/mini.indentscope',
  version = '*',
  config = function()
    -- Example mapping to toggle outline

    require('mini.indentscope').setup {
      delay = 50,
      -- Your setup opts here (leave empty to use defaults)
    }

    local f = function(args)
      vim.b[args.buf].miniindentscope_disable = true
    end

    vim.api.nvim_create_autocmd('Filetype', { pattern = 'help', callback = f })
    vim.api.nvim_create_autocmd('Filetype', { pattern = 'alpha', callback = f })
  end,
}

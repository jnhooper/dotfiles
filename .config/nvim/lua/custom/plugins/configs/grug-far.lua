return {
  'MagicDuck/grug-far.nvim',
  -- Note (lazy loading): grug-far.lua defers all it's requires so it's lazy by default
  -- additional lazy config to defer loading is not really needed...
  --- Ensure existing keymaps and opts remain unaffected
  config = function(_, opts)
    require('grug-far').setup(opts)
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'grug-far',
      callback = function()
        -- Map <Esc> to quit after ensuring we're in normal mode
        vim.keymap.set({ 'i', 'n' }, '<Esc>', '<Cmd>stopinsert | bd!<CR>', { buffer = true })
      end,
    })
  end,
  keys = {
    {
      '<leader>fr',
      function()
        local grug = require 'grug-far'
        local ext = vim.bo.buftype == '' and vim.fn.expand '%:e'
        grug.open {
          transient = true,
          prefills = {
            filesFilter = ext and ext ~= '' and '*.' .. ext or nil,
          },
        }
      end,
      mode = { 'n', 'v' },
      desc = 'Find and Replace',
    },
  },
}

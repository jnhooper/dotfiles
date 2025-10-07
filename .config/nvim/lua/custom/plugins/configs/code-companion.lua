return {
  'olimorris/codecompanion.nvim', -- The KING of AI programming
  cmd = { 'CodeCompanion', 'CodeCompanionChat', 'CodeCompanionActions' },
  -- keys = {
  --   {
  --     '<leader>bc', -- Example keybinding for Chat
  --     function()
  --       require('codecompanion').chat()
  --     end,
  --     { desc = 'chat companion' },
  --   },
  --   {
  --     '<leader>bi', -- Example keybinding for Inline
  --     function()
  --       require('codecompanion').inline()
  --     end,
  --     mode = { 'n', 'v' },
  --     desc = 'Code Companion Inline',
  --   },
  -- },
  Lazy = false,
  config = function()
    require('codecompanion').setup {
      strategies = {
        chat = { adapter = 'ollama' },
        inline = { adapter = 'ollama' },
      },
      adapters = {
        ollama = function()
          return require('codecompanion.adapters').extend('ollama', {
            schema = {
              model = {
                default = 'qwen2.5-coder',
              },
            },
            env = {
              url = 'http://localhost:11434', -- local endpoint
              api_key = '', -- leave empty if not needed
            },
            headers = {
              ['Content-Type'] = 'application/json',
            },
            parameters = {
              sync = true,
            },
          })
        end,
      },
    }
  end,
  -- opts = {
  --   adapters = {
  --     ollama = function()
  --       return require('codecompanion.adapters').extend('ollama', {
  --         schema = {
  --           model = {
  --             default = 'qwen2.5-coder',
  --           },
  --         },
  --         env = {
  --           url = 'http://localhost:11434', -- local endpoint
  --           api_key = '', -- leave empty if not needed
  --         },
  --         headers = {
  --           ['Content-Type'] = 'application/json',
  --         },
  --         parameters = {
  --           sync = true,
  --         },
  --       })
  --     end,
  --   },
  -- },
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
    {
      'MeanderingProgrammer/render-markdown.nvim',
      ft = { 'markdown', 'codecompanion' },
    },
  },
  {
    'echasnovski/mini.diff',
    config = function()
      local diff = require 'mini.diff'
      diff.setup {
        -- Disabled by default
        source = diff.gen_source.none(),
      }
    end,
  },
}

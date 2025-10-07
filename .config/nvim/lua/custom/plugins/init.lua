-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
---
return {
  'tpope/vim-rails',
  {
    'isak102/ghostty.nvim',
    config = function()
      require('ghostty').setup()
    end,
  },
  -- {
  --   'ggandor/leap.nvim',
  --   config = function()
  --     require('leap').set_default_keymaps()
  --   end,
  -- },
  {
    'ThePrimeagen/harpoon',
    branch = 'harpoon2',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local harpoon = require 'harpoon'
      harpoon:setup {}
      local conf = require('telescope.config').values
      local function toggle_telescope(harpoon_files)
        local file_paths = {}
        for _, item in ipairs(harpoon_files.items) do
          table.insert(file_paths, item.value)
        end
        local finder = function()
          local paths = {}
          for _, item in ipairs(harpoon_files.items) do
            table.insert(paths, item.value)
          end

          return require('telescope.finders').new_table {
            results = paths,
          }
        end

        local function remove_mark(prompt_bufnr)
          local state = require 'telescope.actions.state'
          local selected_entry = state.get_selected_entry()
          local current_picker = state.get_current_picker(prompt_bufnr)

          table.remove(harpoon_files.items, selected_entry.index)
          current_picker:refresh(finder())
        end

        require('telescope.pickers')
          .new({}, {
            prompt_title = 'Harpoon',
            finder = require('telescope.finders').new_table {
              results = file_paths,
            },
            previewer = conf.file_previewer {},
            sorter = conf.generic_sorter {},
            attach_mappings = function(prompt_bufnr, map)
              map('i', '<C-d>', function()
                remove_mark(prompt_bufnr)
              end)
              map('n', '<C-d>', function()
                remove_mark(prompt_bufnr)
              end)
              map('n', 'd', function()
                remove_mark(prompt_bufnr)
              end)
              return true
            end,
          })
          :find()
      end

      vim.keymap.set('n', '<leader>hx', function()
        harpoon:list():add()
      end, { desc = '[h]arpoon [x] marks the spot' })
      vim.keymap.set('n', '<leader>hl', function()
        harpoon:list():next { ui_nav_wrap = true }
      end, { desc = '[h]arpoon next [l] ' })
      vim.keymap.set('n', '<leader>hh', function()
        harpoon:list():prev { ui_nav_wrap = true }
      end, { desc = '[h]arpoon previous [h]' })
      vim.keymap.set('n', '<leader>hm', function()
        toggle_telescope(harpoon:list())
      end, { desc = '[h]arpoon [m]arks' })
    end,
  },

  {
    'Wansmer/treesj',
    keys = {
      { '<leader>m', '<cmd>TSJToggle<cr>' },
    },
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
    },
    config = function()
      require('treesj').setup {--[[ your config ]]
      }
    end,
  },
  {
    'ojroques/nvim-bufdel',
    config = function()
      require('bufdel').setup {
        next = 'tabs',
        quit = true, -- quit Neovim when last buffer is closed
      }
      vim.keymap.set('n', '<leader>x', '<cmd>BufDel<CR>', { desc = '[x] out of buffer' })
    end,
  },
  'nvim-lua/plenary.nvim',

  {
    'nvchad/ui',
    lazy = true,
    config = function()
      require 'nvchad'
      vim.keymap.set('n', '<leader>tp', function()
        require('nvchad.themes'):open()
      end, { desc = '[T]eme [p]icker' })
    end,
  },
  {
    'nvim-tree/nvim-web-devicons',
    lazy = true,
    opts = function()
      return { override = require 'nvchad.icons.devicons' }
    end,
    config = function(_, opts)
      dofile(vim.g.base46_cache .. 'devicons')
      require('nvim-web-devicons').setup(opts)
    end,
  },

  {
    'nvchad/base46',
    lazy = true,
    build = function()
      require('base46').load_all_highlights()
    end,
  },
  'nvchad/volt',
  {
    'goolord/alpha-nvim',
    lazy = false,
    -- dependencies = { 'echasnovski/mini.icons' },
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require 'custom.plugins.configs.alpha'
    end,
  },
  -- needed for mini.ai to get function and tags etc
  'nvim-treesitter/nvim-treesitter-textobjects',

  'tpope/vim-fugitive',
  {
    'nvim-web-devicons',
    override_by_extension = {
      ['tsx'] = {
        icon = '󰜈 ',
        name = 'react',
      },
      ['jsx'] = {
        icon = '󰜈 ',
        name = 'react',
      },
      ['ts'] = {
        icon = '',
        name = 'react',
      },
    },
  },
  -- {
  --   'nvim-tree/nvim-tree.lua',
  --   version = '*',
  --   lazy = false,
  --   dependencies = {
  --     'nvim-tree/nvim-web-devicons',
  --   },
  --   config = function()
  --     require('nvim-tree').setup {
  --       update_focused_file = {
  --         enable = true,
  --         update_root = true,
  --       },
  --     }
  --   end,
  --   keys = {
  --     { '<leader>e', '::NvimTreeFocus <CR>', desc = 'nvimTree focus', silent = true },
  --     { '<C-n>', ':NvimTreeToggle <CR>', desc = 'nvimTree collapse', silent = true },
  --   },
  -- },

  -- assumes ollama is setup
  -- {
  --   'robitx/gp.nvim',
  --   config = function()
  --     require 'custom.plugins.configs.gp'
  --   end,
  -- },
  require 'custom.plugins.configs.snacks',
  require 'custom.plugins.configs.copilot',
  -- require 'custom.plugins.configs.copilot-cmp',
  require 'custom.plugins.configs.text-case',
  require 'custom.plugins.configs.oil',
  require 'custom.plugins.configs.render-markdown',
  require 'custom.plugins.configs.autolist',
  require 'custom.plugins.configs.debugging',
  require 'custom.plugins.configs.nvim-biscuits',
  require 'custom.plugins.configs.twilight',
  -- require 'custom.plugins.configs.smear',
  -- require 'custom.plugins.configs.avante',
  -- require 'custom.plugins.configs.code-companion',
  require 'custom.plugins.configs.outline',
  -- require 'custom.plugins.configs.mini-indent',
  require 'custom.plugins.configs.flash',
  require 'custom.plugins.configs.grug-far',
  require 'custom.plugins.configs.mini-files',
  require 'custom.plugins.configs.trouble',
  require 'custom.plugins.configs.neotest',
  require 'custom.plugins.configs.peekup',
}

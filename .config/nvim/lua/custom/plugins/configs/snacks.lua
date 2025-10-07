---@module "snacks"
return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    scroll = {},
    toggle = {},
    -- dim = {
    --   opts = {
    --     scope = {
    --       min_size = 5,
    --       max_size = 20,
    --       siblings = true,
    --       cursor = false,
    --       edge = true, -- include the edge of the scope (typically the line above and below with smaller indent)
    --       debounce = 30,
    --       filter = function(buf)
    --         return vim.bo[buf].buftype == '' and vim.b[buf].snacks_scope ~= false and vim.g.snacks_scope ~= false
    --       end,
    --       treesitter = {
    --         enabled = true,
    --         injections = true, -- include language injections when detecting scope (useful for languages like `vue`)
    --         ---@type string[]|{enabled?:boolean}
    --         blocks = {
    --           enabled = false, -- enable to use the following blocks
    --           'function_declaration',
    --           'function_definition',
    --           'method_declaration',
    --           'method_definition',
    --           'class_declaration',
    --           'class_definition',
    --           'do_statement',
    --           'while_statement',
    --           'repeat_statement',
    --           'if_statement',
    --           'for_statement',
    --         },
    --         -- these treesitter fields will be considered as blocks
    --         field_blocks = {
    --           'local_declaration',
    --         },
    --       },
    --     },
    --   },
    -- },
    animate = {},
    terminal = {},
    image = {
      enabled = true,
      doc = {
        -- Personally I set this to false, I don't want to render all the
        -- images in the file, only when I hover over them
        -- render the image inline in the buffer
        -- if your env doesn't support unicode placeholders, this will be disabled
        -- takes precedence over `opts.float` on supported terminals
        inline = vim.g.neovim_mode == 'skitty' and true or false,
        -- only_render_image_at_cursor = vim.g.neovim_mode == "skitty" and false or true,
        -- render the image in a floating window
        -- only used if `opts.inline` is disabled
        float = true,
        -- Sets the size of the image
        -- max_width = 60,
        -- max_width = vim.g.neovim_mode == "skitty" and 20 or 60,
        -- max_height = vim.g.neovim_mode == "skitty" and 10 or 30,
        max_width = vim.g.neovim_mode == 'skitty' and 5 or 60,
        max_height = vim.g.neovim_mode == 'skitty' and 2.5 or 30,
        -- max_height = 30,
        -- Apparently, all the images that you preview in neovim are converted
        -- to .png and they're cached, original image remains the same, but
        -- the preview you see is a png converted version of that image
        --
        -- Where are the cached images stored?
        -- This path is found in the docs
        -- :lua print(vim.fn.stdpath("cache") .. "/snacks/image")
        -- For me returns `~/.cache/neobean/snacks/image`
        -- Go 1 dir above and check `sudo du -sh ./* | sort -hr | head -n 5`
      },
    },
    notifier = {
      history = true,
    },
    gitbrowse = {},
    lazygit = {},
    -- zen = {
    --   enabled = true,
    --   win = {
    --     backdrop = {
    --       transparent = false,
    --     },
    --   },
    --   toggles = {
    --     dim = true,
    --     git_signs = false,
    --     diagnostics = true,
    --     line_number = true,
    --     relative_number = false,
    --     signcolumn = 'no',
    --     indent = false,
    --   },
    -- },
  },
  keys = {
    {
      '<leader>n',
      function()
        Snacks.notifier.show_history()
      end,
      desc = 'Notification History',
    },
    {
      '<leader>gB',
      function()
        Snacks.gitbrowse()
      end,
      desc = 'Git Browse',
      mode = { 'n', 'v' },
    },
    {
      '<leader>gg',
      function()
        Snacks.lazygit()
      end,
      desc = 'Lazygit',
    },
    {
      '<leader>qt',
      function()
        Snacks.terminal.toggle()
      end,
      desc = '[Q]uick [T]erminal',
    },
    {
      '<leader>zm',
      function()
        require('twilight').toggle()
      end,
      desc = '[z]en [m]ode',
    },
  },
  init = function()
    vim.api.nvim_create_autocmd('User', {
      pattern = 'VeryLazy',
      callback = function()
        -- Setup some globals for debugging (lazy-loaded)
        _G.dd = function(...)
          Snacks.debug.inspect(...)
        end
        _G.bt = function()
          Snacks.debug.backtrace()
        end
        vim.print = _G.dd -- Override print to use snacks for `:=` command

        -- Create some toggle mappings
        Snacks.toggle.option('spell', { name = '[S]pell [C]heck' }):map '<leader>sc'

        Snacks.toggle.option('', { name = '[S]pell [C]heck' }):map '<leader>sc'
        local copilot_exists = pcall(require, 'copilot')

        if copilot_exists then
          Snacks.toggle({
            name = '[C]opilot [C]ompletion',
            color = {
              enabled = 'azure',
              disabled = 'orange',
            },
            get = function()
              return not require('copilot.client').is_disabled()
            end,
            set = function(state)
              if state then
                require('copilot.command').enable()
              else
                require('copilot.command').disable()
              end
            end,
          }):map '<leader>cc'
        end

        local biscuits_exits = pcall(require, 'nvim-biscuits')
        if biscuits_exits then
          Snacks.toggle({
            name = '[B]iscuits [T]oggle',
            color = {
              enabled = 'azure',
              disabled = 'orange',
            },
            get = function()
              return require('nvim-biscuits').is_enabled()
            end,
            set = function(state)
              if state then
                require('nvim-biscuits').enable()
              else
                require('nvim-biscuits').disable()
              end
            end,
          }):map '<leader>bt'
        end
        -- local twilight_exists = pcall(require, 'twilight')
        -- if twilight_exists then
        --   Snacks.toggle({
        --     name = '[Z]en [M]ode',
        --     color = {
        --       enabled = 'azure',
        --       disabled = 'orange',
        --     },
        --     get = function()
        --       return require('twilight').is_enabled()
        --     end,
        --     set = function(state)
        --       if state then
        --         require('twilight').enable()
        --       else
        --         require('twilight').disable()
        --       end
        --     end,
        --   }):map '<leader>zm'
        -- end

        -- Snacks.toggle.dim():map '<leader>zm'
      end,
    })
  end,
  -- config = function(_, opts)
  --   require('snacks').setup(opts)
  -- end,
}

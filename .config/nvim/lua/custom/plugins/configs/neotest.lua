return {
  'nvim-neotest/neotest',
  dependencies = {
    'nvim-neotest/nvim-nio',
    'nvim-lua/plenary.nvim',
    'antoinemadec/FixCursorHold.nvim',
    'nvim-treesitter/nvim-treesitter',
    'marilari88/neotest-vitest',
    'olimorris/neotest-rspec',
    'nvim-neotest/neotest-jest',
    'thenbe/neotest-playwright',
    'markemmons/neotest-deno',
  },
  -- do we need this?
  event = { 'BufReadPost', 'BufNewFile' },
  keys = {
    {
      '<leader>t',
      group = '🧪 Test',
      nowait = true,
      remap = false,
    },
    {
      '<leader>tr',
      "<cmd>lua require('neotest').run.run()<cr>",
      desc = '[t]est [r]un',
    },
    {
      '<leader>tf',
      "<cmd>lua require('neotest').run.run(vim.fn.expand('%'))<cr>",
      desc = '[t]est [f]ile',
    },
    {
      '<leader>ta',
      "<cmd>lua require('neotest').run.run({ suite = true })<cr>",
      desc = '[t]est [a]ll',
    },
    {
      '<leader>td',
      "<cmd>lua require('neotest').run.run({strategy = 'dap'})<cr>",
      desc = '[t]est [d]ebug',
    },
    {
      '<leader>tS',
      "<cmd>lua require('neotest').run.stop()<cr>",
      desc = '[t]est [S]top',
    },
    {
      '<leader>tn',
      "<cmd>lua require('neotest').run.attach()<cr>",
      desc = '[t]est attach to [n]earest test',
    },
    {
      '<leader>to',
      "<cmd>lua require('neotest').output.open()<cr>",
      desc = '[t]est [o]utput',
    },
    {
      '<leader>tt',
      "<cmd>lua require('neotest').output_panel.toggle()<cr>",
      desc = '[T]oggle [t]est panel',
    },
    {
      '<leader>ts',
      "<cmd>lua require('neotest').summary.toggle()<cr>",
      desc = 'Toggle [t]est [s]ummary',
    },
    {
      '<leader>tc',
      "<cmd>lua require('neotest').run.run({ suite = true, env = { CI = true } })<cr>",
      desc = 'Run all [t]ests with [C]I',
    },
  },

  config = function(_, opts)
    local status_ok, neotest = pcall(require, 'neotest')
    if not status_ok then
      return
    end

    local jest = require 'neotest-jest'
    require('neotest').setup {
      floating = opts.floating,
      strategies = opts.strategies,
      run = opts.run,
      output = opts.output,
      output_panel = opts.output_panel,
      quickfix = opts.quickfix,
      status = opts.status,
      state = opts.state,
      watch = opts.watch,
      diagnostic = opts.diagnostic,
      projects = opts.projects,
      discovery = opts.discovery,
      running = opts.running,
      default_strategy = opts.default_strategy,
      highlights = opts.highlights,
      icons = opts.icons,
      consumers = opts.consumers or {},
      log_level = opts.log_level or 3,
      summary = {
        count = true,
        open = 'botright vsplit | vertical resize 80',
        enabled = true,
        animated = true,
        follow = true,
        expand_errors = true,
        mappings = {
          attach = 'a',
          clear_marked = 'M',
          clear_target = 'T',
          debug = 'd',
          debug_marked = 'D',
          expand = { '<CR>', '<2-LeftMouse>' },
          expand_all = 'e',
          jumpto = 'i',
          mark = 'm',
          next_failed = 'J',
          output = 'o',
          prev_failed = 'K',
          run = 'r',
          run_marked = 'R',
          short = 'O',
          stop = 'u',
          target = 't',
        },
      },
      adapters = {
        require 'neotest-vitest' {
          -- Filter directories when searching for test files. Useful in large projects (see Filter directories notes).
          filter_dir = function(name)
            return name ~= 'node_modules'
          end,
        },
        require 'neotest-rspec',
        require 'neotest-deno',
        require('neotest-playwright').adapter {
          options = {
            persist_project_selection = true,
            enable_dynamic_test_discovery = true,
          },
        },
        jest {
          jestCommand = 'npm test --',
          cwd = function(path)
            return vim.fn.getcwd()
          end,
        },
      },
    }
  end,
}

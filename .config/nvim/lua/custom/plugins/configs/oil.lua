return {
  'stevearc/oil.nvim',
  ---@module 'oil'
  ---@type oil.SetupOpts
  opts = {},
  config = function()
    local oil = require 'oil'

    -- ==========================================
    -- Helper 1: Get the Neovim-relative filepath
    -- ==========================================
    local function get_relative_path()
      local dir = oil.get_current_dir()
      local entry = oil.get_cursor_entry()
      if not dir or not entry then
        return nil
      end

      local absolute_path = dir .. entry.name
      return vim.fn.fnamemodify(absolute_path, ':.')
    end

    -- ==========================================
    -- Helper 2: Get the Git Web URL
    -- ==========================================
    local gitweb = require 'custom.utils.gitweb'

    local function get_git_url(use_default_branch)
      local dir = oil.get_current_dir()
      local entry = oil.get_cursor_entry()
      if not dir or not entry then
        vim.notify('Could not get filepath', vim.log.levels.WARN)
        return nil
      end

      local url, err = gitweb.url(dir .. entry.name, { default_branch = use_default_branch })
      if not url then
        vim.notify(err, vim.log.levels.WARN)
      end
      return url
    end

    -- ==========================================
    -- Oil Setup & Keymaps
    -- ==========================================
    oil.setup {
      keymaps = {
        -- Your existing grug-far search
        fr = {
          desc = 'oil: Search in directory',
          callback = function()
            local prefills = { paths = oil.get_current_dir() }
            local grug_far = require 'grug-far'
            if not grug_far.has_instance 'explorer' then
              grug_far.open {
                instanceName = 'explorer',
                prefills = prefills,
                staticTitle = 'Find and Replace from Explorer',
              }
            else
              grug_far.get_instance('explorer'):open()
              grug_far.get_instance('explorer'):update_input_values(prefills, false)
            end
          end,
        },

        -- The DRY Filepath Commands
        yp = {
          desc = 'Copy relative filepath to system clipboard',
          callback = function()
            local path = get_relative_path()
            if path then
              vim.fn.setreg('+', path)
              vim.notify('Copied: ' .. path, vim.log.levels.INFO)
            else
              vim.notify('Could not copy filepath', vim.log.levels.WARN)
            end
          end,
        },
        yc = {
          desc = 'Copy claude syntax filepath to system clipboard',
          callback = function()
            local path = get_relative_path()
            if path then
              local claude_path = '@' .. path
              vim.fn.setreg('+', claude_path)
              vim.notify('Copied: ' .. claude_path, vim.log.levels.INFO)
            else
              vim.notify('Could not copy filepath', vim.log.levels.WARN)
            end
          end,
        },
        yb = {
          desc = 'Copy git web URL for current branch to system clipboard',
          callback = function()
            local url = get_git_url(false)
            if url then
              vim.fn.setreg('+', url)
              vim.notify('Copied Git URL: ' .. url, vim.log.levels.INFO)
            end
          end,
        },
        yg = {
          desc = 'Copy git web URL (main/master) to system clipboard',
          callback = function()
            local url = get_git_url(true) -- Passes 'true' to use default branch
            if url then
              vim.fn.setreg('+', url)
              vim.notify('Copied Git URL: ' .. url, vim.log.levels.INFO)
            end
          end,
        },
        gb = {
          desc = 'Open file in git web browser (main/master)',
          callback = function()
            local url = get_git_url(true) -- Get URL for main/master
            if url then
              -- This uses Neovim's native system opener
              local _, err = vim.ui.open(url)
              if err then
                vim.notify('Could not open browser: ' .. err, vim.log.levels.ERROR)
              else
                vim.notify('Opening: ' .. url, vim.log.levels.INFO)
              end
            end
          end,
        },
      },
    }
  end,
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  lazy = false,
}

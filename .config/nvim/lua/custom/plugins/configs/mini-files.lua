return {
  'echasnovski/mini.files',
  version = '*',
  config = function()
    -- Example mapping to toggle outline

    require('mini.files').setup {
      windows = {
        -- Maximum number of windows to show side by side
        max_number = math.huge,
        -- Whether to show preview of file/directory under cursor
        preview = true,
        -- Width of focused window
        width_focus = 50,
        -- Width of non-focused window
        width_nofocus = 15,
        -- Width of preview window
        width_preview = 50,
      },
      custom_keymaps = {
        copy_to_clipboard = '<space>yy',
        copy_path = 'Y',
      },
    }
    local files_grug_far_replace = function()
      -- works only if cursor is on the valid file system entry
      local cur_entry_path = MiniFiles.get_fs_entry().path
      local prefills = { paths = vim.fs.dirname(cur_entry_path) }

      local grug_far = require 'grug-far'

      -- instance check
      if not grug_far.has_instance 'explorer' then
        grug_far.open {
          instanceName = 'explorer',
          prefills = prefills,
          staticTitle = 'Find and Replace from Explorer',
        }
      else
        grug_far.get_instance('explorer'):open()
        -- updating the prefills without crealing the search and other fields
        grug_far.get_instance('explorer'):update_input_values(prefills, false)
      end
    end

    vim.api.nvim_create_autocmd('User', {
      pattern = 'MiniFilesBufferCreate',
      callback = function(args)
        vim.keymap.set('n', 'fr', files_grug_far_replace, { buffer = args.data.buf_id, desc = 'Search in directory' })
      end,
    })
  end,

  keys = {
    {
      '<leader>e',
      function()
        local buf_name = vim.api.nvim_buf_get_name(0)
        local dir_name = vim.fn.fnamemodify(buf_name, ':p:h')
        if vim.fn.filereadable(buf_name) == 1 then
          -- Pass the full file path to highlight the file
          require('mini.files').open(buf_name, true)
        elseif vim.fn.isdirectory(dir_name) == 1 then
          -- If the directory exists but the file doesn't, open the directory
          require('mini.files').open(dir_name, true)
        else
          -- If neither exists, fallback to the current working directory
          require('mini.files').open(vim.uv.cwd(), true)
        end
      end,
      desc = 'Open mini.files (Directory of Current File or CWD if not exists)',
    },
    {
      '<leader>E',
      function()
        require('mini.files').open(vim.uv.cwd(), true)
      end,
      desc = 'Open mini.files (cwd)',
    },
  },
}

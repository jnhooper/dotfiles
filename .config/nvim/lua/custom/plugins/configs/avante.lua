return {
  'yetone/avante.nvim',
  event = 'VeryLazy',
  version = false, -- Never set this value to "*"! Never!
  opts = {
    -- add any opts here
    -- for example
    provider = 'gemini',
    -- ollama = {
    --   model = 'qwen2.5-coder',
    -- },
    providers = {
      ollama = {
        endpoint = 'http://localhost:11434',
        model = 'qwen2.5-coder',
      },
    },

    -- behaviour = {
    --   --- ... existing behaviours
    --   enable_cursor_planning_mode = true, -- enable cursor planning mode!
    -- },
    -- rag_service = {
    --   enabled = true, -- Enables the RAG service
    --   host_mount = os.getenv 'HOME', -- Host mount path for the rag service
    --   provider = 'openai', -- The provider to use for RAG service (e.g. openai or ollama)
    --   llm_model = 'qwen2.5-coder', -- The LLM model to use for RAG service
    --   embed_model = 'qwen2.5-coder', -- The embedding model to use for RAG service
    --   endpoint = 'http://localhost:11434', -- The API endpoint for RAG service
    -- },
    --
    rag_service = { -- RAG Service configuration
      enabled = false, -- Enables the RAG service
      host_mount = os.getenv 'HOME' .. '/projects', -- Host mount path for the rag service (Docker will mount this path)
      runner = 'docker', -- Runner for the RAG service (can use docker or nix)
      llm = { -- Configuration for the Language Model (LLM) used by the RAG service
        provider = 'ollama', -- The LLM provider ("ollama")
        endpoint = 'http://localhost:11434', -- The LLM API endpoint for Ollama
        api_key = '', -- Ollama typically does not require an API key
        model = 'llama2', -- The LLM model name (e.g., "llama2", "mistral")
        extra = nil, -- Extra configuration options for the LLM (optional) Kristin", -- Extra configuration options for the LLM (optional)
      },
      embed = { -- Configuration for the Embedding Model used by the RAG service
        provider = 'ollama', -- The Embedding provider ("ollama")
        endpoint = 'http://localhost:11434', -- The Embedding API endpoint for Ollama
        api_key = '', -- Ollama typically does not require an API key
        model = 'nomic-embed-text', -- The Embedding model name (e.g., "nomic-embed-text")
        extra = { -- Extra configuration options for the Embedding model (optional)
          embed_batch_size = 10,
        },
      },
      docker_extra_args = '', -- Extra arguments to pass to the docker command
    },
  },
  -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
  build = function()
    -- conditionally use the correct build system for the current OS
    if vim.fn.has 'win32' == 1 then
      return 'powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false'
    else
      return 'make'
    end
  end,
  -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'stevearc/dressing.nvim',
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
    --- The below dependencies are optional,
    'echasnovski/mini.pick', -- for file_selector provider mini.pick
    'nvim-telescope/telescope.nvim', -- for file_selector provider telescope
    'hrsh7th/nvim-cmp', -- autocompletion for avante commands and mentions
    'ibhagwan/fzf-lua', -- for file_selector provider fzf
    'nvim-tree/nvim-web-devicons', -- or echasnovski/mini.icons
    -- 'zbirenbaum/copilot.lua', -- for providers='copilot'
    {
      -- support for image pasting
      'HakonHarnes/img-clip.nvim',
      event = 'VeryLazy',
      opts = {
        -- recommended settings
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
          -- required for Windows users
          use_absolute_path = true,
        },
      },
    },
    {
      -- Make sure to set this up properly if you have lazy=true
      'MeanderingProgrammer/render-markdown.nvim',
      opts = {
        file_types = { 'markdown', 'Avante' },
      },
      ft = { 'markdown', 'Avante' },
    },
  },
}

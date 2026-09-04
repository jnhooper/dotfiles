-- Per-server LSP configuration.
--
-- Why this lives outside init.lua's kickstart block: we're on mason-lspconfig v2,
-- which removed the `handlers` option that kickstart used to configure servers. What
-- still works there is *installation* -- the keys of the `servers` table feed
-- mason-tool-installer's ensure_installed, and `automatic_enable = true` calls
-- vim.lsp.enable() for every installed server. The per-server value tables are never
-- read. Anything that actually has to reach a server goes through vim.lsp.config(),
-- which is what this file is for.

local M = {}

--- @param capabilities lsp.ClientCapabilities cmp-augmented capabilities, from init.lua
function M.setup(capabilities)
  -- Applies to every server automatic_enable starts. Without this, none of them get
  -- cmp's capabilities: cmp-nvim-lsp ships no plugin/ directory of its own, and the
  -- merge that used to happen inside mason-lspconfig's `handlers` is gone.
  vim.lsp.config('*', { capabilities = capabilities })

  -- Moved out of init.lua's `servers` table, where it had no effect.
  vim.lsp.config('lua_ls', {
    settings = {
      Lua = {
        completion = { callSnippet = 'Replace' },
        -- Toggle below to ignore lua_ls's noisy `missing-fields` warnings
        -- diagnostics = { disable = { 'missing-fields' } },
      },
    },
  })

  vim.lsp.config('denols', {
    root_markers = { 'deno.json', 'deno.jsonc' },
  })
  vim.lsp.enable 'denols'

  vim.lsp.config('harper_ls', {
    settings = {
      ['harper-ls'] = {
        userDictPath = '~/dict.txt',
      },
    },
  })
  vim.lsp.enable 'harper_ls'

  -- ts_ls + @vue/typescript-plugin, i.e. Volar "hybrid mode": ts_ls owns TypeScript
  -- intelligence inside .vue files while vue_ls owns the template. vue_ls's hover is
  -- switched off in init.lua's LspAttach so ts_ls wins for documentation.
  local vue_language_server_path = vim.fn.stdpath 'data' .. '/mason/packages/vue-language-server/node_modules/@vue/language-server'

  local ts_capabilities = vim.tbl_deep_extend('force', capabilities or vim.lsp.protocol.make_client_capabilities(), { offsetEncoding = { 'utf-16' } })

  -- Deep merge onto lspconfig's shipped ts_ls config so nothing gets dropped.
  vim.lsp.config.ts_ls = vim.tbl_deep_extend('force', vim.lsp.config.ts_ls or {}, {
    -- Native 0.11 root detection
    root_markers = { 'package.json', '.git' },
    single_file_support = false,
    filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
    capabilities = ts_capabilities,
    init_options = {
      plugins = {
        {
          name = '@vue/typescript-plugin',
          location = vue_language_server_path,
          languages = { 'vue' },
        },
      },
    },
  })

  -- Carried over verbatim from init.lua, but note it is a no-op: indexing
  -- vim.lsp.config returns a freshly merged copy, so assigning into it changes
  -- nothing. lspconfig's root_dir function is still what resolves the root, not
  -- the root_markers above. Left in place so this move stays behaviour-preserving.
  vim.lsp.config.ts_ls.root_dir = nil

  vim.lsp.enable 'ts_ls'

  -- oxlint needs no config here: mason installs it, automatic_enable turns it on, and
  -- nvim-lspconfig ships lsp/oxlint.lua. That config is workspace_required with
  -- root_markers { '.oxlintrc.json', 'oxlint.config.ts' }, so it only attaches in repos
  -- that actually use oxlint. Its on_attach is what creates :LspOxlintFixAll.
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('custom-lsp-servers', { clear = true }),
    callback = function(event)
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if client and client.name == 'oxlint' then
        vim.keymap.set('n', '<leader>cx', '<cmd>LspOxlintFixAll<cr>', { buffer = event.buf, desc = 'LSP: oxlint fi[x] all' })
      end
    end,
  })
end

return M

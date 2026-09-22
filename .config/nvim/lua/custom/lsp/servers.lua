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

  -- ruby-lsp reports RuboCop offences as diagnostics and offers each autocorrect as
  -- a code action (<leader>ca), with `source.fixAll` for the whole file. Like oxlint
  -- it isn't in mason-lspconfig's mappings.lua, so automatic_enable won't start it.
  --
  -- Not installed through mason: its package is a gem shim bound to whichever Ruby
  -- was active at install time, which breaks the moment that Ruby goes away. Use the
  -- gem under the mise-managed Ruby instead (`gem install ruby-lsp`). ruby-lsp builds
  -- a composed bundle in the project's .ruby-lsp/ that evals the app's own Gemfile,
  -- so project cops -- including the custom ones in lib/custom_cops -- resolve.
  -- `rubocop_internal` rather than `rubocop`: since RuboCop v1.70 the bare `rubocop`
  -- identifier hands over to the add-on shipped in the rubocop gem, and ruby-lsp
  -- announces that swap through window/showMessage on every start. Both produce
  -- identical diagnostics here, so take the one that doesn't warn.
  vim.lsp.config('ruby_lsp', {
    init_options = {
      formatter = 'rubocop_internal',
      linters = { 'rubocop_internal' },
    },
  })
  vim.lsp.enable 'ruby_lsp'

  -- ts_ls + @vue/typescript-plugin, i.e. Volar "hybrid mode": ts_ls owns TypeScript
  -- intelligence inside .vue files while vue_ls owns the template. vue_ls's hover is
  -- switched off in init.lua's LspAttach so ts_ls wins for documentation.
  local vue_language_server_path = vim.fn.stdpath 'data' .. '/mason/packages/vue-language-server/node_modules/@vue/language-server'

  -- Use the vim.lsp.config() setter, not `vim.lsp.config.ts_ls = ...`. Indexing
  -- vim.lsp.config returns a freshly merged copy, so assigning a whole table into it
  -- bakes lspconfig's current defaults into our config and shadows future updates to
  -- them -- and assigning a single field into it does nothing at all. The setter
  -- registers overrides that get merged on read, on top of '*' and lsp/ts_ls.lua.
  --
  -- root_dir is deliberately left to lspconfig. Its function skips files that belong
  -- to a Deno project, which is what keeps ts_ls from attaching alongside denols, and
  -- it roots at the package-manager lockfile so a monorepo gets one server at the
  -- workspace root rather than one per package. Overriding it with root_markers of
  -- { 'package.json', '.git' } would lose both. If it ever needs to go, root_markers
  -- alone won't do it -- vim.lsp.start only consults them when root_dir is falsy, so
  -- it takes an explicit `root_dir = false`.
  vim.lsp.config('ts_ls', {
    single_file_support = false,
    filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
    -- Merges over the capabilities set on '*' above.
    capabilities = { offsetEncoding = { 'utf-16' } },
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

  vim.lsp.enable 'ts_ls'

  -- oxlint needs no config -- nvim-lspconfig ships lsp/oxlint.lua -- but it does need
  -- enabling by hand: mason-lspconfig's automatic_enable only covers servers listed in
  -- its mappings.lua, and oxlint isn't in there, so installing the mason package alone
  -- never starts it. The shipped config is workspace_required with root_markers
  -- { '.oxlintrc.json', 'oxlint.config.ts' }, so it still only attaches in repos that
  -- actually use oxlint. Its on_attach is what creates :LspOxlintFixAll.
  vim.lsp.enable 'oxlint'
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

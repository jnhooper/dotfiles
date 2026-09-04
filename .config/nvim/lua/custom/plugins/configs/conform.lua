-- Extends the conform.nvim spec in init.lua with the oxc/vize toolchain.
--
-- This works as a separate file because kickstart configures conform with `opts`,
-- which lazy.nvim merges across spec fragments. (nvim-lspconfig and nvim-lint use
-- `config` functions, which lazy OVERWRITES rather than merges -- so those two can't
-- be extended this way without clobbering kickstart's setup.)

return {
  'stevearc/conform.nvim',
  optional = true,
  opts = function(_, opts)
    opts.formatters = vim.tbl_deep_extend('force', opts.formatters or {}, {
      -- `vize fmt` has no stdin mode, hence stdin = false. conform's tmpfile keeps
      -- the extension, so vize still sees a .vue file. Inert until a `vize` binary
      -- exists on PATH -- stop_after_first skips formatters that aren't executable.
      vize_fmt = {
        command = 'vize',
        args = { 'fmt', '--write', '$FILENAME' },
        stdin = false,
      },
    })

    -- tbl_extend, not tbl_deep_extend: these are lists, and a deep merge would splice
    -- them together index by index instead of replacing them.
    opts.formatters_by_ft = vim.tbl_extend('force', opts.formatters_by_ft or {}, {
      vue = { 'vize_fmt', 'oxfmt', 'eslint_d', 'deno_fmt', stop_after_first = true },
      javascript = { 'oxfmt', 'eslint_d', 'deno_fmt', 'prettierd', 'prettier', stop_after_first = true },
      javascriptreact = { 'oxfmt', 'eslint_d', 'deno_fmt', stop_after_first = true },
      typescript = { 'oxfmt', 'eslint_d', 'deno_fmt', stop_after_first = true },
      typescriptreact = { 'oxfmt', 'eslint_d', 'deno_fmt', stop_after_first = true },
    })

    return opts
  end,
}

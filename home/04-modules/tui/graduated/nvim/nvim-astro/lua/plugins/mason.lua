-- Disable Mason and all bridge plugins.
-- All LSP servers, formatters, linters, and debuggers are installed via Nix
-- (see lsp-tools.nix). Mason is not needed and would duplicate installations.

---@type LazySpec
return {
  { "williamboman/mason.nvim", enabled = false },
  { "williamboman/mason-lspconfig.nvim", enabled = false },
  { "jay-babu/mason-null-ls.nvim", enabled = false },
  { "jay-babu/mason-nvim-dap.nvim", enabled = false },
  { "WhoIsSethDaniel/mason-tool-installer.nvim", enabled = false },
}

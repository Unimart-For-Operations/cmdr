-- Conform.nvim: formatter integration
-- Formatters are installed globally via Nix (lsp-tools.nix), not Mason.
-- This file tells neovim which formatter to use for each filetype.

---@type LazySpec
return {
  "stevearc/conform.nvim",
  opts = {
    formatters = {
      prettier_markdown = {
        inherit = false,
        command = "prettier",
        args = { "--prose-wrap", "preserve", "--stdin-filepath", "$FILENAME" },
      },
    },
    formatters_by_ft = {
      lua = { "stylua" },
      nix = { "nixpkgs_fmt" },
      python = { "black" },
      sh = { "shfmt" },
      bash = { "shfmt" },
      zsh = { "shfmt" },
      javascript = { "prettier" },
      typescript = { "prettier" },
      javascriptreact = { "prettier" },
      typescriptreact = { "prettier" },
      json = { "prettier" },
      yaml = { "prettier" },
      markdown = { "prettier_markdown" },
      html = { "prettier" },
      css = { "prettier" },
    },
    -- Format on save (2 second timeout for large files)
    format_on_save = {
      timeout_ms = 2000,
      lsp_format = "fallback",
    },
  },
}

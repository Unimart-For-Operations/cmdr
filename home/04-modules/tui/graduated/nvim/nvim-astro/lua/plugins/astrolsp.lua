-- AstroLSP: LSP engine configuration
-- LSP servers are installed via Nix (lsp-tools.nix), not Mason.
-- This file declares which servers are available and configures LSP behavior.

---@type LazySpec
return {
  "AstroNvim/astrolsp",
  ---@type AstroLSPOpts
  opts = {
    features = {
      codelens = false,
      inlay_hints = false,
      semantic_tokens = true,
    },

    -- Formatting is handled by conform.nvim (see conform.lua).
    -- Disable LSP formatting to avoid conflicts.
    formatting = {
      disabled = true,
    },

    -- Declare Nix-installed servers so AstroNvim attaches them without Mason.
    -- These binaries are on PATH via lsp-tools.nix.
    servers = {
      "lua_ls",
      "nil_ls",
      "ts_ls",
      "bashls",
      "pyright",
      "yamlls",
      "html",
      "cssls",
      "jsonls",
      "gopls",
      "dockerls",
      "markdown_oxide", -- Obsidian-aware markdown LSP (replaces marksman)
    },

    -- Per-server config overrides passed to lspconfig
    ---@diagnostic disable: missing-fields
    config = {
      lua_ls = {
        settings = {
          Lua = {
            workspace = { checkThirdParty = false },
            completion = { callSnippet = "Replace" },
          },
        },
      },

      -- markdown-oxide needs dynamicRegistration for file watching (code actions,
      -- unresolved file creation, completion for unindexed blocks).
      markdown_oxide = {
        capabilities = {
          workspace = {
            didChangeWatchedFiles = {
              dynamicRegistration = true,
            },
          },
        },
      },
    },

    -- LSP-attached keymaps
    mappings = {
      n = {
        gD = {
          function() vim.lsp.buf.declaration() end,
          desc = "Declaration of current symbol",
          cond = "textDocument/declaration",
        },
        ["<Leader>lf"] = {
          function() require("conform").format({ async = true, lsp_format = "fallback" }) end,
          desc = "Format buffer",
        },
        ["<Leader>uY"] = {
          function() require("astrolsp.toggles").buffer_semantic_tokens() end,
          desc = "Toggle LSP semantic highlight (buffer)",
          cond = function(client)
            return client:supports_method "textDocument/semanticTokens/full" and vim.lsp.semantic_tokens ~= nil
          end,
        },
      },
    },

    -- Server-specific on_attach overrides
    on_attach = function(client, bufnr)
      -- markdown-oxide: register :Daily command for natural-language daily note navigation
      -- Usage: :Daily next monday, :Daily two days ago, :Daily prev, :Daily +7
      if client.name == "markdown_oxide" then
        vim.api.nvim_create_user_command("Daily", function(args)
          local input = args.args
          vim.lsp.buf.execute_command({ command = "jump", arguments = { input } })
        end, { desc = "Open daily note (markdown-oxide)", nargs = "*" })

        -- Auto-refresh code lenses (reference counts, etc.)
        if client.server_capabilities and client.server_capabilities.codeLensProvider then
          local function refresh_codelens()
            vim.lsp.codelens.enable(true, { bufnr = bufnr })
          end
          vim.api.nvim_create_autocmd(
            { "TextChanged", "InsertLeave", "CursorHold", "BufEnter" },
            {
              buffer = bufnr,
              callback = function()
                refresh_codelens()
              end,
            }
          )
          refresh_codelens()
        end
      end
    end,
  },
}

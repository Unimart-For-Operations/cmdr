-- AstroCore compatibility tweaks for newer Neovim releases.

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@param _ LazyPlugin
  ---@param opts AstroCoreOpts
  opts = function(_, opts)
    opts.diagnostics = opts.diagnostics or {}

    opts.diagnostics.jump = {
      on_jump = function(_, bufnr)
        vim.diagnostic.open_float({
          border = "rounded",
          bufnr = bufnr,
          focus = false,
          header = "",
          prefix = "",
          scope = "cursor",
          source = true,
          style = "minimal",
        })
      end,
    }
  end,
}

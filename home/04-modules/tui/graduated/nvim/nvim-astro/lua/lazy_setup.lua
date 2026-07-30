require("lazy").setup({
  {
    "AstroNvim/AstroNvim",
    version = "^5", -- Remove version tracking to elect for nightly AstroNvim
    import = "astronvim.plugins",
    opts = { -- AstroNvim options must be set here with the `import` key
      mapleader = " ", -- This ensures the leader key must be configured before Lazy is set up
      maplocalleader = ",", -- This ensures the localleader key must be configured before Lazy is set up
      icons_enabled = true, -- Set to false to disable icons (if no Nerd Font is available)
      pin_plugins = nil, -- Default will pin plugins when tracking `version` of AstroNvim, set to true/false to override
      update_notifications = true, -- Enable/disable notification about running `:Lazy update` twice to update pinned plugins
    },
  },
  { import = "community" },
  { import = "plugins" },
} --[[@as LazySpec]], {
  -- Configure any other `lazy.nvim` configuration options here

  -- Redirect lock file to the writable XDG data directory.
  -- ~/.config/nvim-astro/ is deployed by Home Manager as Nix store symlinks
  -- (read-only). Lazy.nvim must write lazy-lock.json at runtime on :Lazy update,
  -- so we redirect it to ~/.local/share/nvim-astro/ which is always writable.
  -- Home Manager seeds this file from the repo copy
  -- (home/04-modules/tui/graduated/nvim/default.nix).
  -- After :Lazy update, copy it back:
  --   cp ~/.local/share/nvim-astro/lazy-lock.json \
  --      home/04-modules/tui/graduated/nvim/nvim-astro/lazy-lock.json
  lockfile = vim.fn.stdpath("data") .. "/lazy-lock.json",

  install = { colorscheme = { "astrotheme", "habamax" } },
  ui = { backdrop = 100 },
  performance = {
    rtp = {
      -- disable some rtp plugins, add more to your liking
      disabled_plugins = {
        "gzip",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "zipPlugin",
      },
    },
  },
} --[[@as LazyConfig]])

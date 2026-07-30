-- User plugins: additional plugins and overrides for AstroNvim defaults.

---@type LazySpec
return {

  -- == Telescope (Fuzzy Finder) ==
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    opts = function(_, opts)
      local actions = require "telescope.actions"
      return require("astrocore").extend_tbl(opts, {
        defaults = {
          mappings = {
            i = {
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
            },
          },
        },
        extensions = {
          fzf = {},
        },
      })
    end,
  },

  -- == Catppuccin Theme ==
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = {
      flavour = "frappe",
    },
  },

  -- == Render Markdown (Inline Markdown Preview) ==
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = "markdown",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      file_types = { "markdown" },
      code = {
        sign = false,
        width = "block",
        right_pad = 1,
      },
      heading = {
        sign = false,
        icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
      },
    },
  },

  -- == Treesitter markdown parsers ==
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    commit = "61df84986b4b4ec469ee745a182e433d49f8c27e",
    main = "nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      local wanted = { "markdown", "markdown_inline" }
      for _, parser in ipairs(wanted) do
        if not vim.tbl_contains(opts.ensure_installed, parser) then table.insert(opts.ensure_installed, parser) end
      end
    end,
    config = function(_, opts)
      require("nvim-treesitter").setup(opts)
    end,
  },

  -- == Aerial (Neovim 0.12 compatibility) ==
  {
    "stevearc/aerial.nvim",
    commit = "28fe6e822ae344544c379d60fcb13c9519a1f08a",
  },

  -- == Obsidian.nvim ==
  {
    "epwalsh/obsidian.nvim",
    version = "*",
    lazy = true,
    ft = "markdown",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      workspaces = {
        {
          name = "cmdr",
          path = "~/Documents/cmdr",
        },
      },

      daily_notes = {
        folder = "daily",
        date_format = "%Y-%m-%d",
        alias_format = "%B %-d, %Y",
      },

      templates = {
        folder = "templates",
        date_format = "%Y-%m-%d",
        time_format = "%H:%M",
      },

      -- Disable nvim-cmp source; completion is handled via blink.compat below.
      completion = {
        nvim_cmp = false,
        min_chars = 2,
      },

      note_id_func = function(title)
        local suffix = ""
        if title ~= nil then
          suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
        else
          suffix = tostring(os.time())
        end
        return suffix
      end,

      note_path_func = function(spec)
        local path = spec.dir / tostring(spec.id)
        return path:with_suffix(".md")
      end,

      follow_url_func = function(url)
        local sys = (vim.uv or vim.loop).os_uname().sysname
        local opener = sys == "Darwin" and "open" or "xdg-open"
        vim.fn.jobstart({ opener, url }, { detach = true })
      end,

      attachments = {
        img_folder = "assets/imgs",
      },

      ui = {
        enable = true,
        update_debounce = 200,
        checkboxes = {
          [" "] = { char = "󰄱", hl_group = "ObsidianTodo" },
          ["x"] = { char = "", hl_group = "ObsidianDone" },
          [">"] = { char = "", hl_group = "ObsidianRightArrow" },
          ["~"] = { char = "󰰱", hl_group = "ObsidianTilde" },
        },
        bullets = { char = "•", hl_group = "ObsidianBullet" },
        external_link_icon = { char = "", hl_group = "ObsidianExtLinkIcon" },
        reference_text = { hl_group = "ObsidianRefText" },
        highlight_text = { hl_group = "ObsidianHighlightText" },
        tags = { hl_group = "ObsidianTag" },
        block_ids = { hl_group = "ObsidianBlockID" },
        hl_groups = {
          ObsidianTodo = { bold = true, fg = "#f78c6c" },
          ObsidianDone = { bold = true, fg = "#89ddff" },
          ObsidianRightArrow = { bold = true, fg = "#f78c6c" },
          ObsidianTilde = { bold = true, fg = "#ff5370" },
          ObsidianBullet = { bold = true, fg = "#89ddff" },
          ObsidianRefText = { underline = true, fg = "#c792ea" },
          ObsidianExtLinkIcon = { fg = "#c792ea" },
          ObsidianTag = { italic = true, fg = "#89ddff" },
          ObsidianBlockID = { italic = true, fg = "#89ddff" },
          ObsidianHighlightText = { bg = "#75662e" },
        },
      },
    },
  },

  -- == Obsidian completion via blink.compat ==
  -- AstroNvim v5 uses blink.cmp, not nvim-cmp. Register obsidian's cmp source
  -- through blink.compat so wiki-link / tag completion works.
  {
    "saghen/blink.cmp",
    dependencies = { "saghen/blink.compat" },
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      opts.sources.providers = opts.sources.providers or {}
      opts.sources.per_filetype = opts.sources.per_filetype or {}

      opts.sources.providers.obsidian = { name = "obsidian", module = "blink.compat.source" }
      opts.sources.providers.obsidian_new = { name = "obsidian_new", module = "blink.compat.source" }
      opts.sources.providers.obsidian_tags = { name = "obsidian_tags", module = "blink.compat.source" }

      local markdown_sources = opts.sources.per_filetype.markdown or {}
      for _, source in ipairs({ "obsidian", "obsidian_new", "obsidian_tags" }) do
        if not vim.tbl_contains(markdown_sources, source) then table.insert(markdown_sources, source) end
      end
      opts.sources.per_filetype.markdown = markdown_sources
    end,
  },

  -- == Dashboard ==
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        preset = {
          header = table.concat({
            " █████  ███████ ████████ ██████   ██████ ",
            "██   ██ ██         ██    ██   ██ ██    ██",
            "███████ ███████    ██    ██████  ██    ██",
            "██   ██      ██    ██    ██   ██ ██    ██",
            "██   ██ ███████    ██    ██   ██  ██████ ",
            "",
            "███    ██ ██    ██ ██ ███    ███",
            "████   ██ ██    ██ ██ ████  ████",
            "██ ██  ██ ██    ██ ██ ██ ████ ██",
            "██  ██ ██  ██  ██  ██ ██  ██  ██",
            "██   ████   ████   ██ ██      ██",
          }, "\n"),
        },
      },
    },
  },

  -- == Disabled defaults ==
  { "max397574/better-escape.nvim", enabled = false },
  { "nvim-treesitter/nvim-treesitter-textobjects", enabled = false },

  -- == LuaSnip: extend JS snippets to JSX ==
  {
    "L3MON4D3/LuaSnip",
    config = function(plugin, opts)
      require "astronvim.plugins.configs.luasnip"(plugin, opts)
      require("luasnip").filetype_extend("javascript", { "javascriptreact" })
    end,
  },
}

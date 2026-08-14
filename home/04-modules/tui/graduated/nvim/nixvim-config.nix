# Comprehensive Nixvim configuration
# Designed to provide feature parity with AstroNvim (minus Obsidian.nvim)
# Colorscheme: stock (nvim default). On DMS hosts matugen generates a dms
# colorscheme handled by the nvim-astro distro, not this nixvim binary.

{ ... }:

{
  # Core Neovim options
  opts = {
    number = true; # Show line numbers
    relativenumber = true; # Relative line numbers
    wrap = false; # Don't wrap lines

    # Indentation
    tabstop = 2;
    shiftwidth = 2;
    expandtab = true;

    # Search
    ignorecase = true;
    smartcase = true;

    # UI
    termguicolors = true;
    signcolumn = "yes";
    cursorline = true;

    # Behavior
    mouse = "a";
    clipboard = "unnamedplus";

    # Splits
    splitbelow = true;
    splitright = true;

    # Completion
    completeopt = "menu,menuone,noselect";
  };

  # Leader keys
  globals = {
    mapleader = " "; # Space as leader
    maplocalleader = ","; # Local comma as leader
  };

  # Plugin configuration
  plugins = {
    # Core functionality
    treesitter = {
      enable = true;
      settings = {
        highlight.enable = true;
        indent.enable = true;
        incremental_selection.enable = true;
      };
    };

    # Telescope fuzzy finder
    telescope = {
      enable = true;
      extensions = {
        fzf-native.enable = true;
      };
      keymaps = {
        "<leader>ff" = {
          action = "find_files";
          options.desc = "Find files";
        };
        "<leader>fg" = {
          action = "live_grep";
          options.desc = "Live grep";
        };
        "<leader>fb" = {
          action = "buffers";
          options.desc = "Find buffers";
        };
        "<leader>fh" = {
          action = "help_tags";
          options.desc = "Help tags";
        };
        "<leader>fw" = {
          action = "grep_string";
          options.desc = "Find word under cursor";
        };
        "<leader>fo" = {
          action = "oldfiles";
          options.desc = "Old files";
        };
        "<leader>fc" = {
          action = "commands";
          options.desc = "Commands";
        };
      };
    };

    # LSP configuration
    lsp = {
      enable = true;
      servers = {
        lua_ls.enable = true; # Lua
        nil_ls.enable = true; # Nix
        ts_ls.enable = true; # TypeScript/JavaScript
        bashls.enable = true; # Bash
        pyright.enable = true; # Python
        terraformls.enable = true; # Terraform
        yamlls.enable = true; # YAML
        html.enable = true; # HTML
        cssls.enable = true; # CSS
        jsonls.enable = true; # JSON
      };
      keymaps = {
        diagnostic = {
          "[d" = "goto_prev";
          "]d" = "goto_next";
        };
        lspBuf = {
          "gd" = "definition";
          "gD" = "declaration";
          "gr" = "references";
          "gi" = "implementation";
          "K" = "hover";
          "<leader>lr" = "rename";
          "<leader>la" = "code_action";
          "<leader>lf" = "format";
        };
      };
    };

    # LSP extras
    lsp-signature = {
      enable = true;
    };

    # Completion
    cmp = {
      enable = true;
      autoEnableSources = true;
      settings = {
        mapping = {
          "<C-Space>" = "cmp.mapping.complete()";
          "<C-d>" = "cmp.mapping.scroll_docs(-4)";
          "<C-f>" = "cmp.mapping.scroll_docs(4)";
          "<C-e>" = "cmp.mapping.close()";
          "<CR>" = "cmp.mapping.confirm({ select = true })";
          "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
          "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
        };
        sources = [
          { name = "nvim_lsp"; }
          { name = "luasnip"; }
          { name = "buffer"; }
          { name = "path"; }
        ];
      };
    };

    # Snippets
    luasnip.enable = true;

    # File explorer
    neo-tree = {
      enable = true;
      settings = {
        enable_git_status = true;
        enable_diagnostics = true;
      };
    };

    # Git integration
    gitsigns = {
      enable = true;
      settings = {
        current_line_blame = false;
        signs = {
          add.text = "│";
          change.text = "│";
          delete.text = "_";
          topdelete.text = "‾";
          changedelete.text = "~";
          untracked.text = "┆";
        };
      };
    };

    # UI enhancements
    lualine = {
      enable = true;
      settings = {
        options = {
          theme = "auto"; # follow the active colorscheme
          globalstatus = true;
        };
      };
    };

    bufferline = {
      enable = true;
    };

    which-key = {
      enable = true;
    };

    indent-blankline = {
      enable = true;
    };

    # Editing helpers
    nvim-autopairs.enable = true;

    comment.enable = true;

    nvim-surround.enable = true;

    # Markdown rendering
    render-markdown.enable = true;

    # Terminal
    toggleterm = {
      enable = true;
      settings = {
        open_mapping = "[[<C-\\>]]";
        direction = "float";
      };
    };

    # Additional utilities
    web-devicons.enable = true;

    # Presence (Discord) - optional
    # presence-nvim.enable = true;  # Uncomment if desired
  };

  # Custom keybindings
  keymaps = [
    # Buffer navigation
    {
      mode = "n";
      key = "]b";
      action = ":bnext<CR>";
      options = {
        desc = "Next buffer";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "[b";
      action = ":bprevious<CR>";
      options = {
        desc = "Previous buffer";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>bd";
      action = ":bdelete<CR>";
      options = {
        desc = "Delete buffer";
        silent = true;
      };
    }

    # Window navigation
    {
      mode = "n";
      key = "<C-h>";
      action = "<C-w>h";
      options = {
        desc = "Move to left window";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<C-j>";
      action = "<C-w>j";
      options = {
        desc = "Move to bottom window";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<C-k>";
      action = "<C-w>k";
      options = {
        desc = "Move to top window";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<C-l>";
      action = "<C-w>l";
      options = {
        desc = "Move to right window";
        silent = true;
      };
    }

    # File explorer
    {
      mode = "n";
      key = "<leader>e";
      action = ":Neotree toggle<CR>";
      options = {
        desc = "Toggle file explorer";
        silent = true;
      };
    }

    # Save file
    {
      mode = "n";
      key = "<C-s>";
      action = ":w<CR>";
      options = {
        desc = "Save file";
        silent = true;
      };
    }
  ];
}

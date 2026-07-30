# LSP servers, formatters, linters, and related tools for Neovim.
# These are installed globally via Nix and available to all Neovim distributions.
# Mason is disabled (see nvim-astro/lua/plugins/mason.lua) — Nix is the sole provider.
# The matching server list in astrolsp.lua must stay in sync with this file.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Language Servers
    lua-language-server # Lua
    nil # Nix
    typescript-language-server # TypeScript/JavaScript
    bash-language-server # Bash
    pyright # Python
    # terraform-ls is installed by cli/terraform — not duplicated here
    yaml-language-server # YAML
    vscode-langservers-extracted # HTML/CSS/JSON/ESLint
    gopls # Go
    dockerfile-language-server # Dockerfile
    markdown-oxide # Markdown (Obsidian-aware: wikilinks, backlinks, tags, daily notes)

    # Formatters
    stylua # Lua
    nixpkgs-fmt # Nix
    prettier # JS/TS/JSON/YAML/MD/HTML/CSS
    black # Python
    shfmt # Shell

    # Linters
    shellcheck # Shell

    # Other tools
    tree-sitter # Parser generator (Treesitter)
    # ripgrep, fd — required by Telescope; installed globally in packages.nix
  ];
}

# AstroNvim Configuration

The primary Neovim distribution in cmdr, built on [AstroNvim](https://github.com/AstroNvim/AstroNvim) v5+.

## Location

Source files live in `home/04-modules/tui/graduated/nvim/nvim-astro/` and are deployed by Home Manager to `~/.config/nvim-astro/` via `xdg.configFile`.

## Usage

```bash
nvim             # AstroNvim (default, via NVIM_APPNAME=nvim-astro)
nvim-astro       # Explicit alias
```

## Key Customizations

All user configuration lives under `nvim-astro/lua/`:

| File | Purpose |
|------|---------|
| `plugins/astrocore.lua` | Core keymaps, options, autocmds |
| `plugins/astrolsp.lua` | LSP server settings and on_attach |
| `plugins/user.lua` | Additional plugin specs (blink.cmp, conform.nvim, etc.) |
| `plugins/conform.lua` | Formatter configuration |
| `plugins/mason.lua` | Mason overrides (disabled — LSP tools managed globally via Nix) |
| `polish.lua` | Post-setup polish (deleted — functionality moved to astrocore) |

## LSP Tools

LSP servers, formatters, and linters are installed globally via Nix in `home/04-modules/tui/graduated/nvim/lsp-tools.nix` — **not** per-distribution with Mason. This ensures both nvim-astro and nixvim share identical tooling.

## Plugin Management

Plugins are managed by Lazy.nvim. The lock file (`lazy-lock.json`) is committed for reproducibility.

**To update plugins:**

```bash
# Inside nvim-astro:
:Lazy update

# Copy lock file back to source:
cp ~/.local/share/nvim-astro/lazy-lock.json \
   home/04-modules/tui/graduated/nvim/nvim-astro/lazy-lock.json

git add home/04-modules/tui/graduated/nvim/nvim-astro/lazy-lock.json
git commit -m "chore: update nvim-astro lazy-lock"
```

## Related Docs

- [nvim.md](nvim.md) — Full Neovim setup (both distributions, LSP tools, wrapper scripts)
- [nvim-astro-obsidian.md](nvim-astro-obsidian.md) — Obsidian/markdown-oxide integration in AstroNvim
- [nvim-astro-stabilization-phase.md](nvim-astro-stabilization-phase.md) — Neovim 0.12 stabilization, lockfile hygiene, and compatibility notes

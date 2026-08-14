---
source: idpbuilder-org
synced: 2026-03-30
---
# Modules

Documentation for each module category, mirroring the `home/04-modules/` structure.

## Categories

| Module | Description | Docs |
|--------|-------------|------|
| **Hosts** | Host discovery and configuration | [Hosts](Hosts/README.md) |
| **Containers** | Docker/Kind runtime and container testing | [Containers](Containers/README.md) |
| **TUI** | Terminal UI tools (Neovim, tmux) | [Neovim](TUI/nvim.md), [AstroNvim](TUI/nvim-astro.md), [Obsidian](TUI/nvim-astro-obsidian.md) |

## Structure

```
home/04-modules/
├── _shared/fonts/ # Shared font config (terminal metrics)
├── cli/
│   ├── graduated/ # Stable CLI tools (core-utils, git, zsh, starship, atuin, ...)
│   ├── incubating/
│   └── sandbox/
├── tui/
│   ├── graduated/ # Terminal UI (nvim, tmux, lazygit, yazi)
│   └── incubating/ # Under evaluation (sesh, k9s)
├── gui/
│   ├── graduated/ # Desktop apps (ghostty, hyprland, dms)
│   ├── incubating/ # Under evaluation (kitty, alacritty)
│   └── sandbox/   # Experimental (wezterm)
```

Each module is a Nix file or directory that declares packages and Home Manager options. Modules are composed into features (`home/03-features/`), which are enabled per-host.

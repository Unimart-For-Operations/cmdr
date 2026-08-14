---
source: idpbuilder-org
synced: 2026-03-30
---
# Architecture

Understanding the design, philosophy, and implementation of cmdr.

## Core Concepts

### The Agnostic Layer

This project manages the **"agnostic layer"** - tools and configurations that should be identical regardless of OS. Your terminal experience is the same on macOS and Linux.

**Managed**: Shell, CLI tools, editor, dotfiles, TUI applications
**Not Managed**: Kernel, drivers, boot, system services

### Modular Composition

Configuration follows a strict hierarchy:
```
Tool -> Module -> Feature -> Host
```

- **Tool**: Individual program (git, tmux, neovim)
- **Module**: Tool's configuration (in `home/04-modules/<category>/<tier>/`)
- **Feature**: Capability bundle (cli, tui, gui)
- **Host**: Machine-specific overrides (in `home/02-hosts/`)

### CNCF-Style Tier System

Modules are organized into adoption tiers within each category:

```
home/04-modules/
├── _shared/fonts/        # Shared font config (terminal metrics)
├── cli/
│   ├── graduated/        # Stable, daily-use (20 modules)
│   ├── incubating/       # Under evaluation
│   └── sandbox/          # Experimental, opt-in
├── tui/
│   ├── graduated/        # nvim, tmux, lazygit, yazi
│   └── incubating/       # sesh, k9s
├── gui/
│   ├── graduated/        # ghostty, hyprland, dms
│   ├── incubating/       # kitty, alacritty
│   └── sandbox/          # wezterm
```

### Layered System

Five layers assemble in order:
1. **Base** - Foundation (all hosts)
2. **Platform** - OS-specific (darwin vs linux)
3. **Features** - Capability bundles (cli, tui, gui)
4. **Desktop** - Window managers (optional)
5. **Host** - Machine-specific overrides

### Platform Isolation

Platform differences live in dedicated files:
- `home/01-platforms/darwin.nix` - macOS settings
- `home/01-platforms/linux.nix` - Linux settings

Shared modules never use platform conditionals.

## Design Principles

1. **Declarative over imperative** - No manual steps
2. **Reproducible** - `flake.lock` pins everything
3. **Modular** - One tool = one module
4. **Platform logic isolated** - No platform conditionals in shared code
5. **Promote when truly shared** - Start in host, move to shared when 2+ hosts need it

## Further Reading

- [Module System](../Modules/README.md) - Module categories and structure
- [Hosts](../Modules/Hosts/README.md) - Host discovery and configuration
- [Platforms Reference](../Reference/platforms.md) - Supported platforms and architectures

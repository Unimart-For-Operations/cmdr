---
source: idpbuilder-org
synced: 2026-03-30
---
# Dev Control Plane Documentation

**Complete documentation for a declarative, modular, cross-platform development environment.**

This documentation structure mirrors the Nix implementation - organized into the same modular, layered architecture as the codebase itself.

---

## Quick Navigation

### Getting Started
**New to this project? Start here:**
- [Bootstrap Guide](Getting-Started/bootstrap.md) - Install from scratch
- [Quick Start](Getting-Started/quickstart.md) - Rapid reference

### Architecture
**Understand how it works:**
- Host Discovery - Auto-discovery engine (`home/02-hosts/default.nix`)
- Evaluation Flow - Flake to deployment
- Tier System - Graduated / Incubating / Sandbox adoption model

### Reference
**Look things up:**
- [Platform Support](Reference/platforms.md) - macOS, Linux, architectures
- Command Reference - All Makefile targets (`make help`)
- Directory Structure - Repo organization (see below)

### Guides
**Learn by doing:**
- Adding Packages - Universal vs platform-specific
- Creating Modules - Build new tool configs
- Platform-Specific Config - Handle OS differences
- Secrets Management - Secure credential handling

### Modules
**Deep dive into each component:**

#### Platforms
- Linux Platform - Linux-specific configuration (`home/01-platforms/linux.nix`)
- Darwin Platform - macOS-specific configuration (`home/01-platforms/darwin.nix`)

#### Hosts
- [Hosts Overview](Modules/Hosts/README.md) - Per-machine configurations

#### Features
- Base Feature - Universal foundation (`home/03-features/base.nix`)
- CLI Feature - Shell, utilities, cloud CLIs (`home/03-features/cli.nix`)
- TUI Feature - Terminal UIs: editor, multiplexer, file manager (`home/03-features/tui.nix`)
- GUI Feature - Display-server applications (`home/03-features/gui.nix`)

#### CLI Tools
- Core Utils, Git, ZSH, Starship, Atuin, Direnv, FZF, Zoxide, Bat, Eza
- SSH, Fonts, AWS, Terraform, Kubernetes (graduated)
- OpenCode, Python, Containers, Azure (incubating)
- Pulumi (sandbox)

#### TUI Tools
- [Neovim](Modules/TUI/nvim.md) - Editor configurations
- [AstroNvim](Modules/TUI/nvim-astro.md) - AstroNvim distribution
- [AstroNvim + Obsidian](Modules/TUI/nvim-astro-obsidian.md) - Obsidian integration
- Tmux, Lazygit, Yazi (graduated)
- Sesh, K9s (incubating)

#### GUI Tools
- Ghostty, Hyprland, DMS (graduated)
- Kitty, Alacritty (incubating)
- WezTerm (sandbox)

#### Containers
- [Container Testing](Modules/Containers/README.md) - Docker testing workflow

### Roadmap
**Where we've been and where we're going:**
- [Roadmap Overview](Roadmap/README.md) - Current status, future plans, IDP integration
- [Tier Migration v1](Roadmap/tier-migration-v1.md) - Original migration plan (historical reference)
- [IDP Builder Analysis](Roadmap/idpbuilder-analysis.md) - CNOE IDP Builder codebase analysis

### Contributing
**Help improve this project:**
- [Contributing Guide](Contributing/README.md) - Development guidelines (AI agents)

---

## Directory Structure

Documentation structure mirrors the Nix implementation:
```
home/01-platforms/               →  Platforms (darwin, linux)
home/02-hosts/                   →  Hosts (per-machine meta.nix + overrides)
home/03-features/                →  Features (base, cli, tui, gui)
home/04-modules/cli/graduated/   →  CLI tools (stable)
home/04-modules/cli/incubating/  →  CLI tools (maturing)
home/04-modules/cli/sandbox/     →  CLI tools (experimental, opt-in)
home/04-modules/tui/graduated/   →  TUI tools (stable)
home/04-modules/tui/incubating/  →  TUI tools (maturing)
home/04-modules/gui/graduated/   →  GUI tools (stable)
home/04-modules/gui/incubating/  →  GUI tools (maturing)
home/04-modules/gui/sandbox/     →  GUI tools (experimental, opt-in)
home/04-modules/_shared/theme/   →  Shared theme system (Catppuccin Frappe)
```

### Tier System (CNCF-style)

| Tier | Meaning | Inclusion |
|------|---------|-----------|
| **Graduated** | Stable, daily-use tools | Auto-included by feature |
| **Incubating** | Maturing, approaching promotion | Auto-included by feature |
| **Sandbox** | Experimental, testing | Opt-in per host via `sandbox` in `meta.nix` |

Run `make tiers` to see all modules and their current tiers.
Run `make promote MODULE=<name> FROM=<tier> TO=<tier>` to move a module between tiers.

---

## Common Tasks

### New Machine Setup
```bash
# 1. Clone and bootstrap
git clone --recurse-submodules <repo> ~/dev-control-plane
cd ~/dev-control-plane
make bootstrap

# 2. Create or use existing host
make new-host DISTRO=macos NAME=my-macbook  # New machine
# or
make switch                                  # Known machine (auto-detects)

# 3. Verify
exec zsh
make doctor
```

### Daily Workflow
```bash
make switch                # Apply configuration (auto-detects host)
make apply HOST=<name>     # Apply specific host configuration
make diff                  # Preview changes (auto-detects host)
make diff HOST=<name>      # Preview changes for specific host
make doctor                # Health check
make tiers                 # View module adoption tiers
```

### Adding Features
1. Edit `home/02-hosts/<distro>/<name>/meta.nix`
2. Add feature to `features` list (available: `cli`, `tui`, `gui`)
3. Optionally add `sandbox = [ "pulumi" "wezterm" ];` for experimental modules
4. Run `make switch`

---

## Project Statistics

- **Modules**: 32 (26 graduated, 5 incubating, 1 sandbox)
- **Hosts**: 4 active (2 macOS, 2 Arch Linux)
- **Platforms**: 2 (macOS, Linux)
- **Features**: 3 core (cli, tui, gui) + base
-- **Theme**: Catppuccin Frappe (now documented in `docs/Reference/theme.md`)
- **Neovim Distributions**: 2 (AstroNvim, Nixvim)

---

## External Resources

- [Nix Manual](https://nixos.org/manual/nix/stable/) - Official Nix documentation
- [Home Manager Manual](https://nix-community.github.io/home-manager/) - Home Manager docs
- [nix-darwin Manual](https://daiderd.com/nix-darwin/) - macOS system management
- [Nix Pills](https://nixos.org/guides/nix-pills/) - Learn Nix language
- [NixOS Wiki](https://wiki.nixos.org/) - Community knowledge base

---

## About This Documentation

**Structure**: Mirrors Nix module organization (1:1 mapping)
**Sync**: Copied to Obsidian vault via `make sync-docs`
**Location**: `docs/` directory in repository root
**Version Control**: All documentation tracked in git

**Obsidian Users**: Run `make sync-docs` to copy this documentation to `~/Documents/cmdr/Professional/organizations/idpbuilder/cmdr/`. Run `make pull-docs` to pull Obsidian edits back.

**Last Updated**: 2026-03-22

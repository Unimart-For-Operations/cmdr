# cmdr

Declarative development environment management across macOS and Linux using Nix flakes, Home Manager, and nix-darwin.

## Quick Start

```bash
# 1. Bootstrap prerequisites
make bootstrap

# 2. Create or apply a host configuration
make new-host DISTRO=macos NAME=my-macbook
make switch    # Auto-detects current host

# 3. Verify installation
exec zsh
make doctor
```

## What This Does

Provides a consistent terminal experience across all your machines:
- Same CLI tools (git, tmux, neovim, ripgrep, fd, etc.)
- Same shell configuration (zsh, starship, atuin)
- Same editor setup (AstroNvim, Nixvim)
- Same cloud tooling (kubectl, k9s, pulumi, aws-cli)
- Declarative and reproducible via Nix flakes

## Key Features

- **Platform Agnostic** - Works on macOS (Intel/Apple Silicon) and Linux (any distro)
- **Modular** - Feature-based composition, enable only what you need
- **Reproducible** - Flake lock ensures identical environments
- **Host-Specific Overrides** - Per-machine customization without breaking shared config
- **GUI Support** - Optional desktop environments (Hyprland, DWM, Sway) on Linux

## Managed Hosts

| Host | Platform | Architecture | Status |
|------|----------|--------------|--------|
| apple-studio-m2-max | macOS | aarch64 | Active |
| apple-macbook-m3-pro | macOS | aarch64 | Active |
| cmdr | Arch Linux | x86_64 | Active |
| cachyos | CachyOS | x86_64 | Active |

## Common Commands

```bash
make help                       # Show all available commands
make bootstrap                  # Install prerequisites
make new-host DISTRO=... NAME=...  # Scaffold new host
make list                       # List all available hosts
make switch                     # Apply config (auto-detects current host)
make apply HOST=<name>          # Apply specific host configuration
make diff                       # Preview changes (auto-detects current host)
make diff HOST=<name>           # Preview changes for specific host
make rollback                   # Roll back to previous generation
make doctor                     # Verify environment health
make sync-docs                  # Sync docs to Obsidian vault
make pull-docs                  # Pull Obsidian edits back to repo
```

## Documentation

Comprehensive documentation organized into modular sections (mirrors the Nix structure):

### [Getting Started](docs/Getting-Started/)
- [Bootstrap Guide](docs/Getting-Started/bootstrap.md) - Installation from scratch
- [Quick Start](docs/Getting-Started/quickstart.md) - Rapid reference

### [Architecture](docs/Architecture/)
- The agnostic layer concept, modular composition, and layered system

### [Reference](docs/Reference/)
- [CI Strategy](docs/Reference/ci.md) - Local CI checks and pre-commit hooks
- [Platform Support](docs/Reference/platforms.md) - Supported OS and architectures
- [Documentation Organization](docs/Reference/docs-organization.md) - Sync pipeline
- [Secret Management](docs/Reference/secrets.md) - sops-nix guide

### [Guides](docs/Guides/)
- Adding packages, creating modules, platform-specific config

### [Modules](docs/Modules/)
- Platform, host, feature, CLI, TUI, GUI, and container documentation

### [Contributing](docs/Contributing/)
- [Development Guidelines](docs/Contributing/README.md) - For developers and AI agents

**[Full Documentation Index](docs/README.md)** - Complete navigation and overview

## Architecture Overview

Configuration flows through a layered system:

1. **Base** - Home Manager foundations (all hosts)
2. **Platform** - macOS (darwin.nix) or Linux (linux.nix)
3. **Features** - Modular capabilities (cli, tui, gui)
4. **Desktop** - Optional window managers (Hyprland, DWM, etc.)
5. **Host Overrides** - Machine-specific customizations

See [docs/README.md](docs/README.md) for complete architecture details.

## Philosophy

This project manages the **agnostic layer** - tools and configurations that should be identical regardless of OS. Your terminal experience is the same on macOS and Linux. OS-level concerns (kernel, drivers, boot) are left to the host system.

**Design Principles:**
- Declarative over imperative
- Reproducible via flake.lock
- Modular composition (tool -> module -> feature -> host)
- Platform logic isolated to platform files
- Machine-specific config starts in host directory, promoted when truly shared

## Project Structure

```
cmdr/
├── flake.nix              # Entry point, exposes homeConfigurations & darwinConfigurations
├── home/
│   ├── 01-platforms/      # darwin.nix, linux.nix
│   ├── 02-hosts/          # Host configurations (macos/, arch/, nixos/, ubuntu/)
│   ├── 03-features/       # Feature modules (base.nix, cli.nix, tui.nix, gui.nix)
│   └── 04-modules/        # Tool modules organized by tier
│       ├── _shared/theme/ # Global Catppuccin Frappe palette
│       ├── cli/graduated/ # TTY-safe CLI tools (20 modules)
│       ├── tui/graduated/ # Terminal UI (nvim, tmux, lazygit, yazi)
│       ├── gui/graduated/ # Desktop apps (ghostty, hyprland, dms)
├── darwin/                # nix-darwin system configuration (macOS only)
├── scripts/               # Bootstrap, hook installer, frontmatter injection
├── docs/                  # Complete documentation
└── Makefile               # User-facing command interface
```

## Contributing

This is a personal dotfiles repository, but feel free to reference it or fork it for your own use. See the [Contributing Guide](docs/Contributing/README.md) for development guidelines.

## Resources

- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [nix-darwin Manual](https://daiderd.com/nix-darwin/)
- [Nix Flakes Book](https://nixos-and-flakes.thiscute.world/)

## License

This configuration is personal and provided as-is. Use at your own discretion.

---

**Obsidian Users:** Run `make sync-docs` to sync documentation to `~/Documents/cmdr/Professional/organizations/idpbuilder/cmdr/`. Run `make pull-docs` to pull Obsidian edits back.

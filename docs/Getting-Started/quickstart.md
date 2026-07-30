---
source: idpbuilder-org
synced: 2026-03-30
---
# Dev Control Plane - Quick Start

## What This Repository Does

A Nix flake + Home Manager based development environment control plane that provides:
- Reproducible development environments across macOS (Apple Silicon) and Linux (CachyOS/Arch, x86_64)
- Declarative management of dotfiles, CLI tools, shell config, and editor setups
- Safe configuration testing via containerized Ubuntu environments
- Host-based Home Manager layout with auto-discovery

## Current Status

**What's Implemented:**
- Nix flake with development shell
- Makefile wrapper commands
- Linux Podman container for testing
- Host-based Home Manager layout (apple-studio-m2-max, apple-macbook-m3-pro, cmdr, cachyos)
- CachyOS desktop with DMS/Hyprland
- macOS platform support

**What's NOT Implemented Yet:**
- Advanced health checks for specific tools
- CI/CD integration

## Prerequisites

1. **Nix** with flakes enabled
2. **Docker Engine** on Linux or **Colima** on macOS for local container workflows
3. **Git**
4. **(Optional) direnv** — for automatic devShell activation (`use flake` in `.envrc`)

## Quick Commands

### Apply Configuration

```bash
# List available hosts
make list

# Apply configuration (auto-detects current host)
make switch

# Apply specific host by name
make apply HOST=cachyos               # CachyOS / Arch Linux
make apply HOST=cmdr                  # cmdr (Arch Linux)
make apply HOST=apple-studio-m2-max  # Apple Studio M2 Max (cmdr)
make apply HOST=apple-macbook-m3-pro # Apple MacBook M3 Pro (mortimera)

# Preview changes before applying (auto-detects current host)
make diff

# Preview changes for specific host
make diff HOST=cachyos

# Roll back to previous generation
make rollback
```

### Container Testing

```bash
# Build and start Ubuntu test container (Linux only)
make test

# Enter interactive shell in container (Linux only)
make test-shell

# Clean up completely (Linux only)
make test-clean
```

**Note:** Container tests are blocked on macOS due to emulation limitations. These tests are designed for native Linux systems only.

### Development Shell

```bash
# Enter development shell (loads home-manager, nixpkgs-fmt, nil, jq)
make dev
# or: nix develop

# With direnv (one-time setup — already configured via .envrc)
direnv allow
```

### Code Quality

```bash
# Format Nix code
make fmt

# Check flake validity
nix flake check

# Update all flake inputs
make update
```

## Cold-Start Workflow (Fresh Machine)

```bash
# 1. Install Nix (Determinate Systems installer recommended)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# 2. Clone repository
git clone git@github.com:idpbuilder/cmdr.git ~/cmdr
cd ~/cmdr

# 3. Bootstrap prerequisites
make bootstrap

# 4. List hosts and apply one
make list
make switch                          # Auto-detects current host
# or
make apply HOST=cachyos               # CachyOS
make apply HOST=cmdr                  # cmdr (Arch Linux)
make apply HOST=apple-studio-m2-max  # Apple Studio M2 Max
make apply HOST=apple-macbook-m3-pro # Apple MacBook M3 Pro

# 5. Reload shell
exec zsh
```

## Project Structure

```
cmdr/
├── flake.nix              # Nix flake — inputs, homeConfigurations, devShells
├── flake.lock             # Locked dependencies
├── Makefile               # Convenience commands
│
├── containers/            # Podman testing environment
│   ├── Dockerfile         # Ubuntu 24.04 + Nix
│   ├── compose.yml        # Container orchestration
│   └── README.md          # Container usage docs
│
├── home/
│   ├── 01-platforms/      # OS-family modules
│   ├── 02-hosts/          # Host inventory (grouped by distro)
│   ├── 03-features/       # base.nix (universal) + composable features (cli, tui, gui)
│   └── 04-modules/        # Tool-specific configs organised by UI capability
│       ├── _shared/       # Cross-module resources (theme/)
│       ├── cli/           # TTY-safe, non-interactive tools
│       │   └── graduated/ # atuin, aws, azure, bat, containerization, core-utils, direnv, eza, fonts, fzf, git, go, opencode, pulumi, python, ssh, starship, terraform, zoxide, zsh
│       ├── tui/           # TTY-safe, full-screen (tmux, nvim, lazygit, yazi, + incubating: k9s, sesh)
│       │   ├── graduated/
│       │   └── incubating/
│       ├── gui/           # Requires display server (ghostty, hyprland, dms, + incubating: kitty, alacritty, + sandbox: wezterm)
│       │   ├── graduated/
│       │   ├── incubating/
│       │   └── sandbox/
│
├── scripts/               # Automation (bootstrap.sh, inject-frontmatter.sh)
│
└── docs/                  # Project documentation
```

## Docker Setup

Docker CLI and Kind are configured declaratively via Home Manager. On Linux, Docker Engine is a system daemon managed by the OS package manager:

```bash
systemctl status docker
docker run hello-world
```

### For Users (Deploying Configs)

Current host workflow:
- List hosts: `make list`
- Apply to current host: `make switch` (auto-detects host based on username)
- Apply specific host: `make apply HOST=<name>`
- Preview changes: `make diff` (auto-detects) or `make diff HOST=<name>`
- Test in container first (Linux only), deploy to real systems later
- Declarative package and config management

## Troubleshooting

### Flake check fails

Files must be tracked by Git:
```bash
git add .
nix flake check
```

### Container won't start

```bash
systemctl status docker
make test-clean  # Clean rebuild
make test
```

### DevShell issues

```bash
make clean
nix develop --refresh
```

## Architecture Notes

**Orchestration:** Nix Flakes + Home Manager
- Flakes provide reproducible dependencies
- Home Manager manages user environments
- Makefile provides ergonomic wrapper commands

**Testing Strategy:**
- Develop on one host
- Test Linux changes in containers before rollout
- Deploy via host-specific entries from `home/02-hosts/`
- Promote duplicate host logic upward only when it is shared

## See Also

- `../README.md` — Full project documentation
- `make help` — All available Makefile commands

---
source: idpbuilder-org
synced: 2026-03-30
---
# Getting Started

New to cmdr? Start here to get up and running.

## Quick Links

- **[Bootstrap Guide](bootstrap.md)** - Complete installation from bare OS
- **[Quick Start](quickstart.md)** - Rapid reference for common tasks

## Overview

This project provides a declarative, reproducible development environment across macOS and Linux. Get the same terminal experience on every machine.

## Prerequisites

Before you begin, ensure you have:
- macOS 10.15+ or any modern Linux distribution
- Internet connection
- Basic terminal access (`bash` or `zsh`)
- `git` and `curl` installed

## Installation Flow

```bash
# 1. Clone the repository
git clone git@github.com:412andrewmortimer/cmdr.git ~/cmdr
cd ~/cmdr

# 2. Bootstrap prerequisites
make bootstrap

# 3. Create or apply host configuration
make new-host DISTRO=macos NAME=my-macbook  # New machine
# OR
make apply HOST=existing-host                # Known machine

# 4. Verify installation
exec zsh
make doctor
```

## What You'll Get

After setup, you'll have:
- 200+ CLI tools (ripgrep, fd, jq, neovim, tmux, etc.)
- 2 Neovim distributions (AstroNvim + Nixvim)
- ZSH with Starship prompt and Atuin history
- Git with custom configuration
- Terminal emulators (Ghostty, Kitty, Alacritty)
- Docker/Kind container stack for local IDP workflows
- All dotfiles managed declaratively

## Next Steps

Once installed:
1. Read the [Architecture](../Architecture/README.md) docs to understand how it works
2. Browse [Modules](../Modules/README.md) to see what's available
3. Check [Guides](../Guides/README.md) for customization tutorials
4. Run `make help` for all available commands

## Need Help?

- [Platforms Reference](../Reference/platforms.md) - Supported systems
- [CI Strategy](../Reference/ci.md) - Local CI and pre-commit hooks
- Run `make doctor` to diagnose issues

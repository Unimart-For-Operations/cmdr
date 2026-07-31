---
source: idpbuilder-org
synced: 2026-03-30
---
# Bootstrap Guide: New Machine Setup

This guide walks through setting up a brand new machine using this repository, from a clean OS installation to a fully configured development environment.

## Prerequisites

Before starting, ensure you have:
- A fresh macOS or Linux installation
- Internet connection
- Basic terminal access (bash or zsh)
- `git` installed (comes with macOS via Xcode CLT, install via package manager on Linux)
- `curl` installed (comes with macOS, pre-installed on most Linux distributions)

## What Gets Installed

By the end of this process, you'll have:
- Nix package manager with flakes enabled
- 200+ CLI tools (ripgrep, fd, jq, neovim, tmux, etc.)
- 2 Neovim distributions (AstroNvim + Nixvim)
- ZSH with modular configuration
- Starship prompt, Atuin history, direnv
- Git with custom config and commit templates
- Ghostty/Kitty/Alacritty terminal configurations
- Docker/Kind container stack for local IDP workflows
- All dotfiles managed declaratively

---

## Quick Start

### Known host (re-imaging a machine that already has a config):

```bash
git clone git@github.com:Unimart-For-Operations/cmdr.git ~/cmdr
cd ~/cmdr
make bootstrap
make switch    # Auto-detects current host
exec zsh
make doctor
```

### New machine (first time, new host identity):

```bash
git clone git@github.com:Unimart-For-Operations/cmdr.git ~/cmdr
cd ~/cmdr
make bootstrap
make new-host DISTRO=<distro> NAME=<name>
make switch    # Auto-detects current host
exec zsh
make doctor
```

---

## Step-by-Step Walkthrough

### Step 1: Clone This Repository

```bash
git clone git@github.com:Unimart-For-Operations/cmdr.git ~/cmdr
cd ~/cmdr
```

---

### Step 2: Bootstrap Prerequisites

```bash
make bootstrap
```

This is an idempotent script that installs everything needed before Nix can take over:

| Step | macOS | Linux | NixOS |
|------|-------|-------|-------|
| Xcode Command Line Tools | Installs if missing | N/A | N/A |
| Homebrew | Installs if missing | N/A | N/A |
| Nix (Determinate Systems) | Installs if missing | Installs if missing | Already present, skipped |

**What the Determinate Systems Nix installer provides:**
- Nix package manager at `/nix/store/`
- Flakes and `nix-command` enabled by default
- Nix added to your shell profile
- Binary caching for faster downloads

**After bootstrap, restart your shell:**
```bash
exec zsh   # or: exec bash
```

**Verify:**
```bash
nix --version
```

**Why Homebrew on macOS?** The nix-darwin configuration in `darwin/system.nix` declares GUI applications (Ghostty, Firefox, VS Code, etc.) as Homebrew casks. Homebrew must be installed before `darwin-rebuild switch` can manage these apps.

---

### Step 3: Choose or Create a Host Configuration

**List existing hosts:**
```bash
make list
```

If your machine already has a host config, skip to Step 4.

**Create a new host:**
```bash
make new-host DISTRO=<distro> NAME=<name>
```

This scaffolds a host directory from the template and auto-fills `meta.nix` with detected values (system architecture, username, home directory).

**Parameters:**

| Parameter | Required | Values | Description |
|-----------|----------|--------|-------------|
| `DISTRO` | Yes | `macos`, `arch`, `nixos`, `ubuntu` | Distro directory (determines platform) |
| `NAME` | Yes | Any valid directory name | Machine identifier |
| `PROFILE` | No | `desktop` (default), `tty` | Feature preset |
| `FEATURES` | No | Space-separated feature names | Override profile features |
| `WORK` | No | `true` | Load employer module |
| `DESKTOP` | No | Space-separated desktop names | Desktop environments (e.g. `"hyprland dms"`) |

**Profiles:**

| Profile | Features | Use case |
|---------|----------|----------|
| `desktop` (default) | `cli tui gui` | Workstation with a display server |
| `tty` | `cli tui` | Headless server, VM, SSH-only box |

**Examples:**

```bash
# macOS workstation (default desktop profile)
make new-host DISTRO=macos NAME=my-macbook

# Arch Linux workstation with Hyprland
make new-host DISTRO=arch NAME=my-desktop DESKTOP="hyprland dms"

# TTY-only Linux server
make new-host DISTRO=ubuntu NAME=dev-vm PROFILE=tty

# Work macOS laptop
make new-host DISTRO=macos NAME=work-macbook WORK=true

# Custom feature set
make new-host DISTRO=arch NAME=minimal-box FEATURES="cli"
```

The command creates the host directory, generates `meta.nix` and `default.nix`, and opens `meta.nix` in `$EDITOR` for review. The generated config is valid and apply-ready — editing is optional.

---

### Step 4: Apply Your Configuration

```bash
make switch    # Auto-detects current host
# or
make apply HOST=<name>    # Apply specific host
```

**What happens during this step:**

1. **Nix reads `flake.nix`** and evaluates your host configuration
2. **macOS hosts** use nix-darwin (`darwin-rebuild switch`), managing both system-level settings (Homebrew casks, Nix daemon) and Home Manager in one command
3. **Linux hosts** use Home Manager directly (`home-manager switch`)
4. **Downloads and builds all packages** (universal + platform-specific)
5. **Installs everything** to `~/.nix-profile/`
6. **Writes all dotfiles** to `~/.config/`
7. **Updates shell profile** to source Home Manager configs

**First-time macOS note:** If `darwin-rebuild` is not yet in PATH, the Makefile automatically runs the nix-darwin bootstrap command with `sudo`. No separate manual step needed.

**This step takes 5-15 minutes on first run** (downloads packages). Subsequent runs take 30-60 seconds.

---

### Step 5: Reload Shell and Verify

```bash
exec zsh
cmdr-bootstrap-docker-engine
make doctor
```

`cmdr-bootstrap-docker-engine` handles the Docker daemon boundary that Home Manager cannot own on non-NixOS Linux. It installs/enables Docker Engine with the OS package manager and adds your user to the `docker` group. Log out and back in after the group change. On macOS, it starts Colima.

On Arch/CachyOS, installing Docker Engine may require a full pacman sync/upgrade. The helper does not run that implicitly because it can upgrade unrelated system packages. If Docker is missing, run `sudo pacman -Syu --needed docker` yourself, then rerun `cmdr-bootstrap-docker-engine` to enable the service and configure group membership.

#### Non-NixOS Linux Maintenance Model

On Arch/CachyOS, there are two package management layers:

- `pacman` owns the operating system: kernel, systemd, firmware, desktop packages, bootloader integration, and rootful daemons like Docker Engine.
- Nix/Home Manager owns the user environment: shells, dotfiles, editors, CLI tools, `unimart`, Docker CLI, Kind, and developer configuration.

Use this operating rhythm:

```bash
# OS maintenance, run intentionally and reboot after kernel/systemd upgrades
sudo pacman -Syu
reboot

# User environment convergence
unimart deli switch
unimart deli doctor
```

Do not treat `nix flake update` as routine OS maintenance. Run it only when intentionally updating cmdr's pinned Nix inputs.

`make doctor` validates your environment:
- Prerequisites (git, Homebrew, Nix, flakes)
- Repository state (flake.nix, flake.lock, submodules)
- Shell configuration (ZSH, XDG directories)
- Managed tools (nvim, tmux, starship, direnv, rg, fd, bat, eza, zoxide, atuin)
- Home Manager and darwin-rebuild availability

---

### Step 6: (Optional) Enable Development Shell

If you plan to work ON this repository (modifying configs, contributing):

```bash
cd ~/cmdr
direnv allow
```

The devShell provides pinned development tools: `nixpkgs-fmt`, `nil` (Nix LSP), `jq`.

---

## Bootstrap Flow Diagram

```
Fresh machine (has: bash, curl, git)
         |
         v
git clone git@github.com:Unimart-For-Operations/cmdr.git ~/cmdr
cd ~/cmdr
         |
         v
make bootstrap
  |-- [macOS] Xcode CLT (if missing)
  |-- [macOS] Homebrew   (if missing)
  \-- [all]   Nix        (if missing)
         |
         v
exec zsh (reload shell to pick up Nix)
         |
         v
make new-host DISTRO=... NAME=...  (if new machine identity)
  |-- Scaffolds host from _template
  |-- Auto-fills system, username, homeDirectory
  \-- Opens $EDITOR for review
         |
         v
make apply HOST=<name>
  |-- [macOS]  darwin-rebuild switch (nix-darwin + Home Manager)
  |-- [Linux]  home-manager switch   (standalone Home Manager)
  |-- Downloads/builds all packages
  |-- Writes dotfiles to ~/.config/
  \-- Updates shell profile
         |
         v
exec zsh (reload shell with new config)
         |
         v
make doctor (verify everything)
```

---

## Updating Your Configuration

After the initial setup:

```bash
cd ~/cmdr
nvim home/04-modules/cli/graduated/zsh/default.nix   # edit something
make switch                                 # apply changes (auto-detects host)
exec zsh                                     # reload shell
make diff                                    # preview changes before applying
```

---

## Rollback

If something goes wrong after applying:

```bash
make rollback
```

This works on both Linux and macOS.

---

## Troubleshooting

### Bootstrap Issues

**`curl: command not found`**
- Install curl: `brew install curl` (macOS) or `apt install curl` (Debian/Ubuntu)

**`/nix` directory already exists**
- Remove it: `sudo rm -rf /nix` (this deletes all Nix packages)

**Nix not in PATH after bootstrap**
- Restart your shell: `exec zsh`
- Or source manually: `. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh`

### Apply Issues

**`error: file 'nixpkgs' was not found`**
- Ensure you're in the repo directory: `cd ~/cmdr`

**`Git tree has uncommitted changes`**
- This is a warning, not an error. The build will still work.

**Empty Neovim config directories**
- AstroNvim config lives directly in the repo at `home/04-modules/tui/graduated/nvim/nvim-astro/` — no submodules needed.

### Post-Apply Issues

**Tools not in PATH**
- Reload your shell: `exec zsh`
- Run `make doctor` to diagnose

**direnv not working**
- direnv is installed BY Home Manager. Complete Steps 4-5 first, then `direnv allow`.

---

## Key Concepts

### You Don't Need to Pre-install Home Manager or nix-darwin

**Linux:** `home-manager switch --flake .#<host>` works because Nix fetches home-manager from the flake input and runs it directly from `/nix/store/`.

**macOS:** The Makefile auto-detects when `darwin-rebuild` is missing and runs the nix-darwin bootstrap command automatically. No separate manual step.

### direnv is Installed BY Home Manager

The `.envrc` file in this repo is ignored until Home Manager installs direnv (Step 4), you reload your shell (Step 5), and you run `direnv allow` (Step 6).

### Two Modes of Operation

| Mode | Goal | Tools needed | Commands |
|------|------|-------------|----------|
| **User** | Get a configured system | Just Nix | `make apply HOST=...` |
| **Developer** | Work on this repo | Nix + direnv + devShell | `make fmt`, `make test`, `make check` |

---

## Neovim Distributions

Two Neovim configurations run side-by-side using `NVIM_APPNAME`:

```bash
nvim          # AstroNvim (default)
nixvim        # Nixvim (declarative Nix-managed)
```

LSP servers, formatters, and linters are installed globally via Nix — not per-distribution with Mason.

---

## Command Reference

```bash
make help           # Show all available commands
make bootstrap      # Install prerequisites (Homebrew + Nix)
make new-host ...   # Scaffold a new host from template
make doctor         # Verify environment health
make list           # List available hosts
make switch         # Apply config (auto-detects current host)
make apply HOST=... # Apply specific host configuration
make diff           # Preview changes (auto-detects current host)
make diff HOST=...  # Preview changes for specific host
make rollback       # Roll back to previous generation
make fmt            # Format Nix code
make check          # Validate flake
make update         # Update flake inputs
make test-shell     # Enter Linux test container (Linux only)
```

---

## Additional Resources

- **Main README:** `../README.md` — Full feature documentation
- **Host System:** `../Modules/Hosts/README.md` — How hosts and the discovery engine work
- **Neovim Setup:** `../Modules/TUI/nvim.md` — Neovim details
- **Agent Guidelines:** `../Contributing/README.md` — AI agent context

---

**Last Updated:** March 2026

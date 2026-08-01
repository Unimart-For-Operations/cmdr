---
source: idpbuilder-org
synced: 2026-03-30
---
# Contributing Guide

This document provides comprehensive context for contributing to the cmdr codebase, including project architecture, development workflows, and code style guidelines.

## Project Overview

**Dev Control Plane** is a declarative development environment management system built on Nix flakes, Home Manager, and nix-darwin. It provides an identical development experience across macOS (Apple Silicon) and Linux (x86_64) by managing CLI tools, dotfiles, shell configurations, and editor setups in a completely reproducible manner.

### Core Philosophy

The project manages the **"agnostic layer"** (tools, configs, shell, editors) while leaving OS-level concerns (kernel, drivers, systemd) to the host system. Opening a terminal should provide an identical experience regardless of host OS.

## Technology Stack

- **Primary Language**: Nix expression language (2,616 lines)
- **Core Technologies**: Nix Flakes, Home Manager, nix-darwin, Nixvim
- **Shell**: ZSH with modular configuration
- **Editor**: 2 Neovim configurations via NVIM_APPNAME (AstroNvim + Nixvim)
- **Terminal**: Ghostty (primary), Kitty, Alacritty
- **Theme**: Catppuccin Frappe everywhere
- **Supported Platforms**: macOS (aarch64-darwin), Linux (x86_64-linux)

## Project Structure

```
cmdr/
├── flake.nix                    # Main flake definition with system configs
├── flake.lock                   # Pinned dependency versions
├── Makefile                     # Ergonomic wrapper commands
├── darwin/                      # nix-darwin system configuration
│   └── system.nix               # Shared macOS system config (Homebrew casks, Nix daemon, stateVersion)
├── home/                        # Home Manager configurations
│   ├── 01-platforms/
│   │   ├── linux.nix            # Linux platform settings
│   │   ├── linux-packages.nix   # Linux-only Nix packages
│   │   ├── darwin.nix           # macOS platform settings
│   │   └── darwin-packages.nix  # macOS-only Nix packages
│   ├── 02-hosts/                # Per-machine configurations (grouped by distro)
│   │   ├── macos/
│   │   │   ├── apple-macbook-m3-pro/
│   │   │   └── apple-studio-m2-max/
│   │   ├── arch/
│   │   │   ├── cachyos/         # CachyOS workstation
│   │   │   └── cmdr/            # cmdr — Arch Linux primary workstation
│   │   ├── nixos/               # Future
│   │   ├── ubuntu/              # Future
│   │   └── _template/           # Scaffold for new hosts
│   ├── 03-features/
│   │   ├── base.nix             # Universal baseline (stateVersion + home-manager, always loaded)
│   │   ├── cli.nix              # TTY-safe, non-interactive tools (shell, git, core-utils, cloud CLIs, runtimes)
│   │   ├── tui.nix              # TTY-safe, full-screen terminal apps (tmux, nvim, lazygit, yazi)
│   │   └── gui.nix              # GPU-accelerated terminal emulators (require display server)
│   └── 04-modules/              # Modular tool configurations (CNCF-style tiers)
│       ├── _shared/             # Cross-module resources
│       │   └── theme/           # Catppuccin Frappe palette, semantic colors, fonts
│       ├── cli/                 # TTY-safe, non-interactive tools
│       │   └── graduated/       # 20 modules: atuin, aws, azure, bat, containerization, core-utils, direnv, eza, fonts, fzf, git, go, opencode, pulumi, python, ssh, starship, terraform, zoxide, zsh
│       ├── tui/                 # TTY-safe, full-screen terminal apps
│       │   ├── graduated/       # lazygit, nvim, tmux, yazi
│       │   └── incubating/      # k9s, sesh
│       ├── gui/                 # Requires a display server
│       │   ├── graduated/       # dms, ghostty, hyprland
│       │   ├── incubating/      # alacritty, kitty
│       │   └── sandbox/         # wezterm
├── scripts/                     # Automation scripts
│   ├── bootstrap.sh             # Idempotent prerequisites installer (Xcode CLT, Homebrew, Nix)
│   └── inject-frontmatter.sh   # Obsidian frontmatter injection for docs sync
├── containers/                  # Docker testing environment
│   ├── Dockerfile               # Ubuntu 24.04 test image
│   └── compose.yml              # Container orchestration
└── docs/                        # Project documentation
```

## Key Architectural Patterns

### 1. Package Installation Strategy

**Goal**: Maximize Nix-managed packages while handling platform-specific installation methods.

**Three-tier package organization:**

1. **Universal packages** (`home/04-modules/cli/graduated/core-utils/`)
   - Pure Nix packages that work identically on both platforms
   - Examples: ripgrep, fd, jq, yq, tree, wget, curl, neovim
   - No platform conditionals or `lib.optionals` logic

2. **Platform-specific packages** (`home/01-platforms/{linux,darwin}-packages.nix`)
   - Linux-only: `slirp4netns`, `fuse-overlayfs`
   - macOS-only: Currently empty (most GUI apps use Homebrew)
   - **Why separate**: Nix can't install them on the other platform

3. **Alternative installation methods** (`darwin/system.nix` for macOS)
   - Homebrew for macOS GUI applications (Ghostty, Firefox, VSCode, etc.)
   - Declared via nix-darwin's `homebrew.casks` option in `darwin/system.nix`
   - Used when Nix packages aren't suitable for GUI apps on macOS

**When adding packages:**
- Try `home/04-modules/cli/graduated/core-utils/` first (universal Nix packages)
- If it only works on one platform, add to `01-platforms/{linux,darwin}-packages.nix`
- Document *why* it's platform-specific in comments
- Avoid `lib.optionals` in modules — keep platform logic in platform files

### 2. Platform File Responsibilities

**Goal**: Keep platform files focused on OS-level settings and imports, not inline configuration.

**Platform files (`home/01-platforms/{linux,darwin}.nix`) should contain:**
- ✅ OS-level environment variables (PATH, platform-specific exports)
- ✅ System defaults and preferences
- ✅ Import statements for platform-specific packages and shell configs
- ✅ Minimal, OS-specific settings

**Platform files should NOT contain:**
- ❌ Large blocks of inline shell configuration (→ `04-modules/cli/graduated/zsh/platform-*.zsh.nix`)
- ❌ Duplicated functions across platforms (→ extract to shared modules)
- ❌ Hardcoded username paths (use `$HOME` or `config.home.homeDirectory`)

**Example - Good platform file structure:**
```nix
# home/01-platforms/darwin.nix (24 lines - CLEAN!)
{ config, pkgs, ... }:

{
  imports = [
    ./darwin-packages.nix
    ../04-modules/cli/graduated/zsh/platform-darwin.zsh.nix
  ];

  home.sessionPath = [
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
  ];

  # macOS-specific settings only
  targets.darwin.defaults = { ... };
}
```

**Platform-specific shell configuration pattern:**

Create separate files for platform-specific shell configs:
- `home/04-modules/cli/graduated/zsh/platform-darwin.zsh.nix` - macOS shell config
- `home/04-modules/cli/graduated/zsh/platform-linux.zsh.nix` - Linux shell config (if needed)

**Platform-specific module variants pattern:**

For modules with platform-specific implementations, keep shared logic in `default.nix`
and split OS-specific logic into `platform-darwin.nix` and `platform-linux.nix` files.

This approach:
- Avoids infinite recursion (can't reference `pkgs` in module imports)
- Keeps platform-specific implementations (e.g., BSD vs GNU date syntax)
- Isolates platform settings from shared module logic

### 3. Modular Configuration

Each tool gets its own module in `home/04-modules/`. This provides:
- Easy enable/disable of features
- Clear ownership and organization
- Testability in isolation
- Reusability across roles

**Module responsibilities:**
- Configuration only (settings, dotfiles, xdg.configFile)
- Universal package installation (works on both platforms)
- Platform-specific package installation should be in platform files
- NO platform detection or conditionals (use platform files or platform variants)

**When adding a new tool:**
1. Create `home/04-modules/<category>/<toolname>/default.nix`
2. Import in the appropriate feature file under `home/03-features/`:
   - `cli.nix` — shell tools, core-utils, cloud CLIs, language runtimes
   - `tui.nix` — full-screen terminal apps (tmux, nvim, lazygit, yazi)
   - `gui.nix` — tools that require a display server
3. Add universal packages to `home/04-modules/cli/graduated/core-utils/default.nix` or the tool's own module
4. Add platform-specific packages to `01-platforms/{linux,darwin}-packages.nix`
5. Follow XDG base directory standards
6. If platform-specific config needed, create `platform-{darwin,linux}.nix` variants

### 4. Two-Configuration Neovim

Two Neovim configurations run side-by-side using `NVIM_APPNAME`:

| Distribution | Manager | Alias | Config Location |
|--------------|---------|-------|-----------------|
| AstroNvim (default) | Lazy.nvim | `nvim`, `nvim-astro` | `~/.config/nvim-astro/` |
| Nixvim | Nix | `nixvim` | Nix store |

**Important**: LSP servers, formatters, and linters are installed globally via Nix (see `home/04-modules/tui/graduated/nvim/lsp-tools.nix`) rather than per-distribution with Mason. This ensures consistency across all configurations.

### 5. Layered Shell Configuration

ZSH configuration loads in numerical order from `~/.config/zsh/`:
1. `01-completion.zsh` - Completion system
2. `02-env.zsh` - Environment variables
3. `03-aliases.zsh` - Command shortcuts
4. `04-aws.zsh` - AWS-specific functions
5. `05-functions.zsh` - Utility functions (Vault SSH, etc.)
6. `99-integrations.zsh` - Tool activations

This provides clear load order, easy debugging, and modular editing.

### 6. XDG Base Directory Compliance

All configurations use XDG paths:
- Config: `$XDG_CONFIG_HOME` (~/.config)
- Data: `$XDG_DATA_HOME` (~/.local/share)
- State: `$XDG_STATE_HOME` (~/.local/state)
- Cache: `$XDG_CACHE_HOME` (~/.cache)

**Always use XDG paths when adding new configurations.**

### 7. AstroNvim Configuration

AstroNvim config lives directly in this repo at `home/04-modules/tui/graduated/nvim/nvim-astro/` and is deployed by Home Manager to `~/.config/nvim-astro/`. Lazy-lock.json is committed for reproducibility.

**To update AstroNvim config:**
```bash
# Edit files in home/04-modules/tui/graduated/nvim/nvim-astro/
# After :Lazy update inside nvim, the lazy-lock.json is written to
# ~/.local/share/nvim-astro/lazy-lock.json (writable XDG data dir).
# Copy it back:
cp ~/.local/share/nvim-astro/lazy-lock.json home/04-modules/tui/graduated/nvim/nvim-astro/lazy-lock.json
git add home/04-modules/tui/graduated/nvim/nvim-astro
git commit -m "chore: update nvim-astro"
```

### 8. Smart Tmux Layout Scripts

Located in `home/04-modules/tui/graduated/tmux/layouts/`:
- `_tmux-helpers.sh` - Shared library functions
- `dev-session.sh` - Development layout (editor | terminal | git)
- `ai-session.sh` - AI-assisted development layout

These scripts:
- Auto-detect project types (nix, node, go, rust, python, terraform, etc.)
- Integrate with Zoxide for path resolution
- Sanitize session names
- Use attach-or-create pattern to avoid duplicates

## Bootstrap & Provisioning

### Prerequisites

Only `bash`, `curl`, and `git` are required on the host. Everything else is installed by the bootstrap script.

### Bootstrap Workflow

The provisioning sequence for a new machine:

```bash
git clone git@github.com:Unimart-For-Operations/cmdr.git ~/cmdr
cd ~/cmdr
make bootstrap       # Installs Xcode CLT + Homebrew (macOS), Nix (all platforms)
exec zsh             # Reload shell to pick up Nix in PATH
make new-host DISTRO=<distro> NAME=<name>   # Scaffold host (skip for existing hosts)
make apply HOST=<name>                       # Apply configuration
exec zsh             # Reload shell
make doctor          # Verify everything
```

### `make bootstrap`

Delegates to `scripts/bootstrap.sh`. Idempotent — every step checks before acting. Handles:
- **macOS**: Xcode Command Line Tools, Homebrew, Nix (Determinate Systems installer)
- **Linux**: Nix (Determinate Systems installer)
- **NixOS**: Detects Nix already present, skips installation

### `make new-host`

Scaffolds a new host directory under `home/02-hosts/<distro>/<name>/` with auto-filled `meta.nix` and an empty `default.nix`. Auto-detects system architecture, username, and home directory.

**Parameters:**
- `DISTRO` (required): `macos`, `arch`, `nixos`, `ubuntu`
- `NAME` (required): Machine identifier (becomes directory name and HOST value)
- `PROFILE` (optional): `desktop` (default) or `tty` — controls the initial feature list
- `FEATURES` (optional): Override profile with explicit space-separated feature list
- `WORK` (optional): Set to `true` to enable employer module
- `DESKTOP` (optional): Desktop environments, space-separated (e.g. `"hyprland dms"`)

**Precedence:** `FEATURES=` (explicit) > `PROFILE=` > default (`desktop`)

**Profile defaults:**
- `desktop`: `cli tui gui`
- `tty`: `cli tui`

### `make doctor`

Health check that verifies 18 items across:
- **Prerequisites**: git, Homebrew (macOS), Nix, flakes
- **Repository**: flake.nix, flake.lock
- **Shell**: default shell is zsh, XDG config directory exists
- **Managed tools**: nvim, tmux, starship, direnv, rg, fd, bat, eza, zoxide, atuin
- **Home Manager**: home-manager in PATH, generation count, darwin-rebuild (macOS)

Reports pass/fail/warn with colored output and total error count.

### `make apply`

Auto-detects platform:
- **macOS**: Uses `darwin-rebuild switch` (auto-bootstraps nix-darwin on first run if `darwin-rebuild` is not in PATH)
- **Linux**: Uses `home-manager switch`

### Important Notes

- **Homebrew is a macOS prerequisite**: `darwin/system.nix` declares Homebrew casks. Without Homebrew, `darwin-rebuild` will fail on cask installation.
- **First-time macOS apply**: If `darwin-rebuild` is not found, `make apply` automatically runs `sudo nix run nix-darwin/master#darwin-rebuild -- switch` to bootstrap nix-darwin.
- **Host discovery is automatic**: Creating the directory + `meta.nix` is sufficient. No edits to `flake.nix` or `home/02-hosts/default.nix` are needed.
- **`make new-host` opens `$EDITOR`**: After scaffolding, it opens `meta.nix` for review.

---

## Development Workflow

### Making Changes

1. **Edit Nix files** in `home/04-modules/`
2. **Test in container** (optional but recommended):
   ```bash
   make test-shell
   cd /workspace
    home-manager switch --flake .#cmdr
   ```
3. **Apply locally**:
   ```bash
    make switch               # auto-detects host
    # or: make apply HOST=<name>
   ```
   - **macOS** hosts use `darwin-rebuild switch` (via nix-darwin), managing both system-level settings (Homebrew casks, Nix daemon) and Home Manager in one command.
   - **Linux** hosts use `home-manager switch` as before.
4. **Verify**: Open new shell and test changes

### Common Commands

```bash
make help              # Show all available commands
make bootstrap         # Install prerequisites (Xcode CLT + Homebrew on macOS, Nix)
make new-host ...      # Scaffold a new host from template
make doctor            # Verify environment health (18 checks)
make ci                # Run full local CI suite
make apply HOST=<name> # Deploy to any host (auto-detects platform)
make switch            # Deploy to current host (auto-detects)
make switch-studio     # Deploy to Apple Studio M2 Max
make switch-macbook    # Deploy to Apple MacBook M3 Pro
make switch-cmdr       # Deploy to cmdr (Arch Linux)
make switch-cachyos    # Deploy to CachyOS
make diff HOST=<name>  # Preview pending changes
make list              # Show discovered hosts
make tiers             # Show tier breakdown of all modules
make promote           # Promote a module to a higher tier
make test              # Start test container
make test-run          # Automated provision + verify + teardown
make test-shell        # Enter test container shell
make test-tty          # TTY test
make ci                # Run all local checks
make ci-full           # ci + automated container test
make fmt               # Format Nix code
make update            # Update flake inputs
make check             # Validate flake
make sync-docs         # Sync docs to org-level docs repo
make pull-docs         # Pull docs from org-level docs repo
```

### Adding New Packages

**For universal packages (work on both platforms):**

Add to `home/04-modules/cli/graduated/core-utils/default.nix`:
```nix
home.packages = with pkgs; [
  # ... existing packages
  newtool
];
```

**For platform-specific packages:**

Add to `home/01-platforms/linux-packages.nix` or `home/01-platforms/darwin-packages.nix`:
```nix
home.packages = with pkgs; [
  # ... existing packages
  linux-only-tool  # Document why it's Linux-only
];
```

Then apply: `make apply HOST=<host>`

### Adding New Program Configurations

Create `home/04-modules/<category>/<toolname>/default.nix`:
```nix
{ config, pkgs, ... }:

{
  programs.newtool = {
    enable = true;
    # ... configuration options
  };

  # Or for manual config files:
  xdg.configFile."newtool/config.yml".text = ''
    # configuration content
  '';
}
```

Import in the appropriate feature file (e.g. `home/03-features/cli.nix`):
```nix
imports = [
  # ... existing imports
  ../04-modules/<category>/<toolname>
];
```

## Code Style Guidelines

### Nix Code

1. **Use nixpkgs-fmt**: Run `make fmt` before committing
2. **Attribute ordering**:
   - imports first
   - options/config declarations
   - packages
   - programs
   - services
   - xdg configuration
   - home.file/xdg.configFile last
3. **Comments**: Explain *why*, not *what*
4. **Module pattern**:
   ```nix
   { config, pkgs, lib, ... }:

   {
     # Module content
   }
   ```

### Shell Scripts

1. **Shebang**: `#!/usr/bin/env bash`
2. **Set strict mode**: `set -euo pipefail`
3. **Use local variables**: `local var_name="value"`
4. **Quote variables**: `"${variable}"`
5. **Function pattern**:
   ```bash
   function_name() {
     local arg1="$1"
     # function body
   }
   ```

### Git Commits

Follow conventional commits (template in `home/04-modules/cli/git/conventional-commits`):
```
type(scope): subject

body

footer
```

**Types**: feat, fix, docs, style, refactor, test, chore

## Key Configuration Files

| File | Purpose | Notes |
|------|---------|-------|
| `flake.nix` | Main entry point | Defines inputs, outputs, system configs |
| `flake.lock` | Locked dependencies | Auto-generated, commit after updates |
| `Makefile` | Ergonomic command interface | bootstrap, new-host, doctor, apply, diff, fmt, etc. |
| `scripts/bootstrap.sh` | Prerequisites installer | Idempotent: Xcode CLT, Homebrew (macOS), Nix (all) |
| `home/02-hosts/default.nix` | Discovery engine | Auto-scans hosts, resolves features, assembles modules |
| `home/03-features/base.nix` | Universal baseline | stateVersion + home-manager, loaded by every host |
| `home/03-features/cli.nix` | CLI feature | TTY-safe, non-interactive tools (shell, git, core-utils, cloud CLIs, runtimes) |
| `home/03-features/tui.nix` | TUI feature | Full-screen terminal apps (tmux, nvim, lazygit, yazi) |
| `home/03-features/gui.nix` | GUI feature | Terminal emulators requiring a display server |
| `home/01-platforms/linux.nix` | Linux settings | Platform-specific config for Linux |
| `home/01-platforms/darwin.nix` | macOS settings | Platform-specific config for macOS (24 lines!) |
| `home/01-platforms/linux-packages.nix` | Linux packages | Linux-only Nix packages |
| `home/01-platforms/darwin-packages.nix` | macOS packages | macOS-only Nix packages |
| `home/04-modules/cli/graduated/core-utils/` | Universal packages | CLI tools that work on both platforms |
| `home/04-modules/tui/graduated/nvim/lsp-tools.nix` | LSP tools | Global language servers, formatters |
| `home/04-modules/cli/graduated/zsh/default.nix` | Shell config | ZSH settings + config files |
| `home/04-modules/cli/graduated/zsh/platform-darwin.zsh.nix` | macOS shell | Platform-specific shell config for macOS |
| `darwin/system.nix` | nix-darwin system config | Homebrew casks, Nix daemon settings, stateVersion |

## Important Paths

| Path | Purpose |
|------|---------|
| `~/.config/` | XDG config directory |
| `~/.local/bin/` | User-local executables (Neovim wrappers) |
| `~/.local/share/` | Application data |
| `~/.nix-profile/` | User Nix profile |
| `/nix/store/` | Nix store (immutable packages) |

## Testing Strategy

### Static + eval checks (`nix flake check`)

The flake exposes a `checks` output that `nix flake check` builds:

```bash
make check                       # nix flake check
```

- `format` — `nixpkgs-fmt --check` over all `.nix` files
- `theme-lint` — `scripts/check-theme-lint.sh`
- `eval-<host>` — one per host; forces the full config to evaluate, including
  darwin hosts evaluated from Linux

### Container Testing

Safe, reproducible integration testing on Linux (including bare-metal NixOS):

```bash
make test-run                    # automated: build, provision, verify, teardown
make test-run HOST=<name>        # provision a different cli/tui host
make test-shell                  # interactive shell
```

**Container details:**
- Base: Ubuntu 24.04 LTS
- Platform: linux/amd64 (native on x86_64 Linux)
- Repository mounted at `/workspace` (read-only)
- Auto-installs Nix on first run

### CI/CD

All CI runs locally — there are no remote CI services.

1. **Pre-commit hook** - Runs gitleaks, `go fmt`, `go vet`, `nix fmt --check`, and theme lint on every commit (deployed via `unimart deli switch`, Nix-managed)
2. **`make ci`** - Full local static suite: secrets + formatting + theme lint + flake check + `make doctor` + host eval
3. **`make ci-full`** - `make ci` plus the automated container test (Linux only)

See [CI Strategy](../Reference/ci.md) for full details.

## Troubleshooting

### Common Issues

**1. Build fails with "file not found"**
- Ensure file is tracked by git: `git add <file>`
- Check file path is correct in Nix expressions

**2. Neovim distribution not loading**
- Check config exists: `ls ~/.config/nvim-<distro>`
- Verify wrapper script: `type nvim-<distro>`
- Test directly: `NVIM_APPNAME=nvim-<distro> nvim`

**3. LSP not working**
- Verify LSP tools installed: `which lua-language-server`
- Check `home/04-modules/tui/graduated/nvim/lsp-tools.nix`
- Re-apply config: `make apply HOST=<name>`

**4. Changes not applied**
- Reload shell: `exec zsh`
- Check generation: `home-manager generations`
- Rollback if needed:
  - **Linux:** `home-manager switch --rollback`
  - **macOS:** `sudo darwin-rebuild switch --rollback` (rolls back both system and Home Manager)

**5. Git submodules missing**
- AstroNvim config lives directly in the repo — no submodules needed.

## Security Considerations

### Current State

Keep sensitive values encrypted in `secrets/` and never commit plaintext credentials.

### Recommended Improvements

1. **Use encrypted secrets**: Implement `agenix` or `sops-nix`
2. **Environment variables**: Load secrets at runtime, not build time
3. **External secret stores**: Integrate with Vault or 1Password CLI
4. **Git ignore**: Add `.env` files to `.gitignore`

**When adding secrets:**
- NEVER commit sensitive data to Nix files
- Use runtime environment variables
- Document required secrets in README

## Integration Points

### AWS

Shell functions in `04-aws.zsh`:
- `assume <profile>` - Switch AWS profiles with SSO
- Fuzzy profile selection with fzf
- EKS cluster integration

### Vault

Functions in `05-functions.zsh`:
- `vault-ssh-key-sign` - Sign SSH keys with Vault
- `vault-check-key-cert` - Check certificate expiration

### Kubernetes

- K9s TUI with Catppuccin skin
- Kubectl aliases and autocompletion
- Context switching integrated with AWS

## Performance Notes

### Build Times

- **Initial apply**: 5-10 minutes (downloads packages)
- **Incremental rebuild**: 30-60 seconds (uses cache)
- **Container first run**: 2-3 minutes (Nix installation)

### Storage Requirements

- **Base Nix**: ~1-2 GB
- **Home Manager generation**: ~5-10 GB
- **Neovim distributions**: +2-3 GB per distro

### Optimization Tips

1. **Use binary cache**: Nix automatically uses cache.nixos.org
2. **Clean old generations**: `home-manager expire-generations "-7 days"`
3. **Garbage collect**: `nix-collect-garbage -d`

## Future Roadmap

### Short Term
- Implement secrets management (age/sops-nix)

### Medium Term
- DevShells for project-specific toolchains
- Architecture decision records (ADRs)
- Multi-user support (abstract username/paths)

### Long Term
- NixOS configuration for dedicated machines
- Remote deployment scripts
- Performance optimization with build caching

### Recently Completed
- Health check script (`make doctor`) — 18 checks across prerequisites, tools, and config
- Bootstrap automation (`make bootstrap`) — idempotent, handles macOS (Xcode CLT + Homebrew) and Nix
- Host scaffolding (`make new-host`) — auto-detects system metadata, supports profiles and feature overrides

## Resources

### Documentation
- [Main README](../README.md) - Project overview
- [Bootstrap Guide](../Getting-Started/bootstrap.md) - New machine setup walkthrough
- [Quickstart Guide](../Getting-Started/quickstart.md) - Getting started
- [CI Strategy](../Reference/ci.md) - Local CI checks and pre-commit hooks
- [Neovim Setup](../Modules/TUI/nvim.md) - Neovim details
- [Container Testing](../Modules/Containers/README.md) - Container workflow

### External Resources
- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nixvim Documentation](https://github.com/nix-community/nixvim)
- [Nix Pills](https://nixos.org/guides/nix-pills/) - Learning Nix

## Anti-Patterns to Avoid

1. **Don't commit secrets** - Use environment variables or encrypted secrets
2. **Don't use non-XDG paths** - Keep home directory clean
3. **Don't install LSP with Mason** - Use global Nix packages in `lsp-tools.nix`
4. **Don't break modularity** - Keep tools in separate modules under `04-modules/`
5. **Don't skip formatting** - Always run `make fmt`
6. **Don't assume platforms** - Test cross-platform or mark as platform-specific
7. **Don't inline large config blocks in platform files** - Extract to dedicated modules
8. **Don't hardcode usernames in paths** - Use `$HOME` or `config.home.homeDirectory`
9. **Don't use `lib.optionals` for platform packages** - Use platform-specific package files
10. **Don't import modules directly from hosts** - Modules in `04-modules/` go through feature files in `03-features/`
11. **Don't manually create host directories** - Use `make new-host`

---

**Project Stats**
- Lines of Nix: ~2,600+
- Modules: 32 (20 CLI graduated, 4 TUI graduated, 2 TUI incubating, 3 GUI graduated, 2 GUI incubating, 1 GUI sandbox)
- Neovim Distributions: 2 (AstroNvim + Nixvim)
- Supported Platforms: 2 (macOS aarch64-darwin, Linux x86_64-linux)

For questions or contributions, see the main [README](../../README.md).

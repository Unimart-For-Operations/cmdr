---
name: nix-modules
description: "cmdr's tiered Nix module system: host discovery engine, feature files, module inventory, meta.nix schema, and the load order that assembles a complete Home Manager configuration."
---

# Nix Module System

## Load Order

When `make switch` runs, the host discovery engine (`home/02-hosts/default.nix`) assembles modules in this order:

1. **base.nix** — Always loaded. Sets `stateVersion` and enables `home-manager`.
2. **Platform** — `01-platforms/darwin.nix` or `01-platforms/linux.nix` (resolved from distro).
3. **Features** — `03-features/{cli,tui,gui}.nix` as declared in `meta.nix`.
4. **Desktop** — `04-modules/gui/graduated/{hyprland,dms}` if `desktop` list is set.
5. **Sandbox** — `04-modules/gui/sandbox/{wezterm}` if `sandbox` list is set.
6. **Host overrides** — `02-hosts/<distro>/<host>/default.nix` (optional per-host customization).

## Host Discovery

The engine scans `home/02-hosts/<distro>/<host>/` directories for `meta.nix` files. No registration in `flake.nix` is needed — dropping a directory with `meta.nix` is sufficient.

**Distro-to-platform mapping:**
- `macos` → `darwin` (imports `01-platforms/darwin.nix`)
- `arch`, `nixos`, `ubuntu` → `linux` (imports `01-platforms/linux.nix`)

**Duplicate detection:** Throws an error if two hosts across different distros share the same name.

## meta.nix Schema

```nix
{
  description = "Human-readable machine name";
  system = "aarch64-darwin";              # or "x86_64-linux"
  username = "cmdr";
  homeDirectory = "/Users/cmdr";          # or "/home/cmdr"
  features = [ "cli" "tui" "gui" ];       # Required. Subsets of: cli, tui, gui
  # desktop = [ "hyprland" "dms" ];       # Optional. Linux desktop environments
  # sandbox = [ "wezterm" ];              # Optional. Experimental GUI modules
}
```

Use `make new-host DISTRO=<distro> NAME=<name>` to scaffold — never create manually.

## Current Hosts

| Host | Distro | System | Features |
|------|--------|--------|----------|
| apple-macbook-m3-pro | macos | aarch64-darwin | cli, tui, gui |
| apple-studio-m2-max | macos | aarch64-darwin | cli, tui, gui |
| cmdr | arch | x86_64-linux | cli, tui, gui + desktop |
| cachyos | arch | x86_64-linux | cli, tui, gui + desktop |

## Tiered Module System

Modules live in `home/04-modules/` with CNCF-style tiers:
- **graduated** — Stable, well-tested, always loaded by feature file
- **incubating** — Working but being refined, loaded by feature file
- **sandbox** — Experimental, opt-in via `meta.nix` sandbox list

## Module Inventory

### CLI (20 graduated, 0 incubating, 0 sandbox)

Loaded by `03-features/cli.nix`:
atuin, aws, azure, bat, containerization, core-utils, direnv, eza, fonts, fzf, git, go, opencode, pulumi, python, ssh, starship, terraform, zoxide, zsh

### TUI (4 graduated, 2 incubating, 0 sandbox)

Loaded by `03-features/tui.nix`:
- Graduated: lazygit, nvim, tmux, yazi
- Incubating: k9s, sesh

### GUI (3 graduated, 2 incubating, 1 sandbox)

Loaded by `03-features/gui.nix`:
- Graduated: ghostty, dms, hyprland (dms and hyprland are desktop-only, loaded via `desktop` list)
- Incubating: alacritty, kitty
- Sandbox: wezterm (loaded via `sandbox` list)

### Shared

- `_shared/fonts/` — shared terminal font metrics. Importable by any module.

## Adding a New Module

1. Create `home/04-modules/<category>/<tier>/<toolname>/default.nix`
2. Import in the appropriate feature file (`03-features/cli.nix`, `tui.nix`, or `gui.nix`)
3. Universal packages go in the module or `core-utils/`. Platform-specific packages go in `01-platforms/{linux,darwin}-packages.nix`.
4. Follow XDG base directory standards.
5. Run `make fmt` before committing.

## Key Rule

Never import a module directly from a host. All modules flow through feature files in `03-features/`. This ensures every host with that feature gets the module automatically.

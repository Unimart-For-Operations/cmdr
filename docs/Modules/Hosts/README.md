# Hosts

This directory is the source of truth for physical machines.

## Layout

Hosts are grouped by distro under `home/02-hosts/<distro>/<host>/`:

```
home/02-hosts/
├── default.nix          ← discovery engine (auto-scans all distro/host dirs)
├── _template/meta.nix   ← scaffold for new hosts
├── macos/
│   ├── apple-macbook-m3-pro/
│   │   └── meta.nix
│   └── apple-studio-m2-max/
│       ├── meta.nix
│       └── default.nix  ← host-specific overrides
├── arch/
│   ├── cmdr/
│   │   └── meta.nix
│   └── cachyos/
│       ├── meta.nix
│       └── default.nix
├── nixos/               ← future
└── ubuntu/              ← future
```

Key files outside this directory:

- `home/03-features/base.nix`: universal baseline loaded by every host (stateVersion + home-manager).
- `home/03-features/cli.nix`: TTY-safe, non-interactive tools (shell, git, core-utils, cloud CLIs, language runtimes).
- `home/03-features/tui.nix`: TTY-safe, full-screen terminal apps (tmux, nvim, lazygit, yazi).
- `home/03-features/gui.nix`: GPU-accelerated terminal emulators (require display server).
- `home/01-platforms/*.nix`: OS family defaults such as Linux or macOS.
- `home/04-modules/gui/graduated/hyprland/`: Hyprland packages and config.
- `home/04-modules/gui/graduated/dms/`: DankMaterialShell configuration.

## Why this structure

The important split is between platform, distro, and identity:

- Platforms answer: "what does Linux or macOS need?"
- Distros answer: "what does CachyOS change from generic Linux?"
- Hosts answer: "what is unique about this exact machine?"

That keeps forks local. A host can diverge heavily without polluting every other Linux or macOS host.

## How discovery works

`flake.nix` imports `home/02-hosts/default.nix`, which auto-discovers hosts by scanning two levels deep: first distro directories (`macos/`, `arch/`, etc.), then host directories within each distro.

- Directories starting with `_` or `.` are excluded (handles `_template/` and `.gitkeep`).
- A directory is only recognized as a host if it contains `meta.nix`.
- Empty distro dirs (e.g., `ubuntu/`, `nixos/`) are gracefully skipped.
- Duplicate host names across distros are detected and throw an error.
- Platform is **inferred** from the distro directory via a `distroToPlatform` map in the engine.
- Host names stay **flat** in flake outputs (e.g., `apple-studio-m2-max`, not `macos/apple-studio-m2-max`).
- macOS hosts are exposed as `darwinConfigurations` (via nix-darwin) and applied with `darwin-rebuild switch`.
- Linux hosts are exposed as `homeConfigurations` and applied with `home-manager switch`.

Each host must define `meta.nix` with at least:

```nix
{
  system = "x86_64-linux";
  username = "cmdr";
  homeDirectory = "/home/cmdr";
  features = [ "cli" "tui" ];
}
```

Optional fields:

- `description`: free-form label for humans.
- `features`: list of strings — `"cli"`, `"tui"`, `"gui"`. Resolved to module paths by the engine.
- `desktop`: list of strings — `"hyprland"`, `"dms"`. Requires `"gui"` in features.
- `work`: boolean — when `true`, the engine imports the current employer's module and platform variant automatically.

## Onboarding a new host

1. Pick the distro directory (e.g., `macos/`, `arch/`, `nixos/`). Create it if it doesn't exist.
2. Copy `home/02-hosts/_template/` to `home/02-hosts/<distro>/<new-host>/`.
3. Edit `meta.nix` with the real system, username, home directory, and features.
4. Add only machine-specific overrides to `default.nix` (optional).
5. Run `make list` to confirm discovery.
6. Apply with `make switch` (auto-detects) or `make apply HOST=<new-host>`.

## Suggested rule of thumb

- If two or more hosts will need it, move it up into `03-features`, `01-platforms`, or `04-modules`.
- If only one host needs it, keep it in that host directory.
- If you are unsure, start host-local and promote later when duplication becomes real.

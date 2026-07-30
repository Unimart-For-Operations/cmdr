# home/02-hosts/default.nix — Host Auto-Discovery Engine
#
# This file is the single entry point that turns the filesystem layout under
# home/02-hosts/<distro>/<host>/ into the `hosts` attrset consumed by flake.nix.
# It is called once at flake evaluation time:
#
#   hosts = import ./home/02-hosts { inherit lib; };
#
# DIRECTORY LAYOUT:
#
#   home/02-hosts/
#   ├── default.nix              ← this file (discovery engine)
#   ├── _template/meta.nix       ← scaffold for new hosts
#   ├── macos/
#   │   ├── apple-macbook-m3-pro/
#   │   │   └── meta.nix
#   │   └── apple-studio-m2-max/
#   │       ├── meta.nix
#   │       └── default.nix      ← host-specific overrides
#   ├── arch/
#   │   ├── cmdr/
#   │   │   └── meta.nix
#   │   └── cachyos/
#   │       ├── meta.nix
#   │       └── default.nix
#   ├── nixos/                   ← future
#   └── ubuntu/                  ← future
#
# The resulting attrset is keyed by host name (flat, no distro prefix):
#
#   {
#     "apple-studio-m2-max" = {
#       system        = "aarch64-darwin";
#       platform      = "darwin";        ← inferred from distro directory
#       username      = "cmdr";
#       homeDirectory = "/Users/cmdr";
#       modules       = [ base.nix  darwin.nix  cli.nix  tui.nix  ...  default.nix ];
#     };
#     "cmdr" = { ... };
#   }
#
# flake.nix then splits hosts by platform:
#   - Darwin hosts → lib.mapAttrs mkDarwinConfiguration darwinHosts
#     → darwinConfigurations."<name>" (nix-darwin wrapping Home Manager)
#   - Linux hosts  → lib.mapAttrs mkHomeConfiguration linuxHosts
#     → homeConfigurations."<name>" (standalone Home Manager)
#
# DATA FLOW (macOS):
#
#   make apply HOST=<name>
#     └─ darwin-rebuild switch --flake .#<name>
#          └─ flake.nix: darwinConfigurations."<name>"
#               └─ mkDarwinConfiguration name host
#                    ├─ darwin/system.nix        (Homebrew casks, Nix daemon)
#                    ├─ home-manager.users.<user> (embedded HM config)
#                    │    ├─ home.username      = host.username
#                    │    ├─ home.homeDirectory = host.homeDirectory
#                    │    └─ imports = host.modules  (assembled here)
#                    └─ specialArgs.hostName = name
#
# DATA FLOW (Linux):
#
#   make apply HOST=<name>
#     └─ home-manager switch --flake .#<name>
#          └─ flake.nix: homeConfigurations."<name>"
#               └─ mkHomeConfiguration name host
#                    ├─ pkgs  = pkgsFor host.system
#                    ├─ home.username      = host.username
#                    ├─ home.homeDirectory = host.homeDirectory
#                    ├─ extraSpecialArgs.hostName = name
#                    ├─ extraSpecialArgs.hostMeta = host
#                    └─ modules = host.modules  (assembled here)
#
# SEMANTIC HOST CONTRACT:
#
#   role = "tty-engineer" | "developer-workstation" | "platform-operator" | ...
#   capabilities = [ "baseline" "terminal-dev" "operator" "idp-local" "desktop" ... ];
#
# role/capabilities are declarations consumed by meta/unimart planning and docs.
# They do not directly import modules. The concrete Nix imports remain governed
# by features/desktop/sandbox below.
#
# MODULE LOAD ORDER:
#
#   [1] 03-features/base.nix                          — universal baseline (stateVersion + home-manager)
#   [2] 01-platforms/{darwin,linux}.nix                — OS-level settings + platform packages
#   [3] 03-features/{cli,tui,gui,tty}.nix             — features declared in meta.nix
#   [4] 04-modules/gui/graduated/{desktop}             — desktop modules declared in meta.nix
#   [5] 04-modules/{cat}/{tier}/{mod}                  — sandbox modules (opt-in per host)
#   [6] 02-hosts/<distro>/<host>/default.nix           — host-specific overrides (optional)
#
# HOW TO ADD A NEW HOST:
#   1. mkdir home/02-hosts/<distro>/<new-host>/
#   2. Create meta.nix with the structured fields (see _template/meta.nix)
#   3. Optionally create default.nix for host-specific overrides
#   4. Run `make list-hosts` to confirm it is discovered
#   No edits to this file or flake.nix are needed.

{ lib }:

let
  # ── Distro-to-platform mapping ─────────────────────────────────────────
  # Maps each distro directory name to the platform identifier used by
  # 01-platforms/.  Adding a new distro that runs on Linux just needs a
  # new entry here pointing to "linux".
  distroToPlatform = {
    macos = "darwin";
    arch = "linux";
    nixos = "linux";
    ubuntu = "linux";
  };

  # ── Platform modules ───────────────────────────────────────────────────
  platformModules = {
    darwin = ../01-platforms/darwin.nix;
    linux = ../01-platforms/linux.nix;
  };

  # ── Feature resolution ─────────────────────────────────────────────────
  # Maps feature name strings to module paths.
  # Features auto-include graduated + incubating modules.
  featureModules = {
    cli = ../03-features/cli.nix;
    tui = ../03-features/tui.nix;
    gui = ../03-features/gui.nix;
    tty = ../03-features/tty.nix;
  };

  # ── Desktop module resolution ──────────────────────────────────────────
  # Maps desktop name strings to module paths under 04-modules/gui/graduated/.
  desktopModules = {
    hyprland = ../04-modules/gui/graduated/hyprland;
    dms = ../04-modules/gui/graduated/dms;
  };

  # ── Sandbox module resolution ──────────────────────────────────────────
  # Maps sandbox name strings to module paths. Sandbox modules are opt-in
  # per host via the `sandbox` field in meta.nix.
  sandboxModules = {
    wezterm = ../04-modules/gui/sandbox/wezterm;
  };

  # ── Directory scanning helpers ─────────────────────────────────────────
  # List only subdirectories, excluding hidden and special entries.
  subdirs = path:
    lib.filterAttrs (name: type: type == "directory" && !lib.hasPrefix "_" name && !lib.hasPrefix "." name)
      (builtins.readDir path);

  # True if a directory contains a meta.nix file (i.e., it's a host, not empty).
  isHostDir = path: builtins.pathExists (path + "/meta.nix");

  # ── Discover all hosts across all distros ──────────────────────────────
  # Scans two levels: <distro>/<host>/ and collects { name = { distro, hostDir }; }
  discoverHosts =
    let
      distroDirs = subdirs ./.;
      distroNames = builtins.attrNames distroDirs;

      # For one distro, return a list of { name, distro, hostDir } attrsets
      hostsInDistro = distro:
        let
          distroPath = ./. + "/${distro}";
          hostDirs = subdirs distroPath;
          hostNames = builtins.attrNames hostDirs;
          validHosts = builtins.filter
            (name: isHostDir (distroPath + "/${name}"))
            hostNames;
        in
        map
          (name: {
            inherit name distro;
            hostDir = distroPath + "/${name}";
          })
          validHosts;

      # Flatten across all distros
      allHosts = lib.concatMap hostsInDistro distroNames;
    in
    allHosts;

  # ── Build a single host attrset ────────────────────────────────────────
  mkHost = { name, distro, hostDir }:
    let
      meta = import (hostDir + "/meta.nix");
      hostModule = hostDir + "/default.nix";
      role = meta.role or "";

      # Platform is inferred from the distro directory
      platform =
        if builtins.hasAttr distro distroToPlatform then
          distroToPlatform.${distro}
        else
          throw "Host '${name}' is in distro '${distro}' which has no platform mapping";

      platformModule =
        if builtins.hasAttr platform platformModules then
          platformModules.${platform}
        else
          throw "Platform '${platform}' (from distro '${distro}') has no module";

      # Resolve feature strings to module paths
      features = meta.features or [ ];
      featureMods = map
        (f:
          if builtins.hasAttr f featureModules then
            featureModules.${f}
          else
            throw "Host '${name}' requests unknown feature '${f}'"
        )
        features;

      # Resolve desktop strings to module paths
      desktop = meta.desktop or [ ];
      desktopMods = map
        (d:
          if builtins.hasAttr d desktopModules then
            desktopModules.${d}
          else
            throw "Host '${name}' requests unknown desktop '${d}'"
        )
        desktop;

      # Resolve sandbox strings to module paths (opt-in per host)
      sandbox = meta.sandbox or [ ];
      sandboxMods = map
        (s:
          if builtins.hasAttr s sandboxModules then
            sandboxModules.${s}
          else
            throw "Host '${name}' requests unknown sandbox module '${s}'"
        )
        sandbox;

      # Host-specific overrides (optional default.nix)
      hostMods = lib.optional (builtins.pathExists hostModule) hostModule;

      # TTY baseline contract: hosts with role="tty-engineer" must stay
      # display-server free unless the role is explicitly changed.
      _ =
        if role == "tty-engineer" && builtins.elem "gui" features then
          throw "Host '${name}' has role='tty-engineer' but enables feature 'gui'"
        else if role == "tty-engineer" && desktop != [ ] then
          throw "Host '${name}' has role='tty-engineer' but configures desktop modules"
        else
          null;
    in
    # Strip internal fields from the output attrset — these are directives
      # consumed by the engine, not fields Home Manager needs.
    (builtins.removeAttrs meta [ "features" "desktop" "sandbox" ]) // {
      inherit platform;
      modules =
        [ ../03-features/base.nix platformModule ]
        ++ featureMods
        ++ desktopMods
        ++ sandboxMods
        ++ hostMods;
    };

  # ── Assemble the final attrset ─────────────────────────────────────────
  hostList = discoverHosts;

  # Convert list of { name, distro, hostDir } into { name = mkHost {...}; }
  # Detect duplicate host names across distros.
  hostsAttrset = builtins.foldl'
    (acc: entry:
      if builtins.hasAttr entry.name acc then
        throw "Duplicate host name '${entry.name}' found in multiple distro directories"
      else
        acc // { ${entry.name} = mkHost entry; }
    )
    { }
    hostList;

in
hostsAttrset

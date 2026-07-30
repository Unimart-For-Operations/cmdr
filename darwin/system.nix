# darwin/system.nix — Shared nix-darwin system configuration
#
# System-level macOS settings applied by `darwin-rebuild switch`.
# This module manages:
#   - Homebrew casks and Mac App Store apps (declarative, replaces .Brewfile)
#   - Nix daemon configuration
#   - System state version
#
# User-level configuration (dotfiles, shell, packages) stays in Home Manager
# modules under home/04-modules/ — embedded via home-manager.darwinModules.
{ pkgs, ... }:

{
  # ── Nixpkgs ─────────────────────────────────────────────────────────────
  # Allow unfree packages (VS Code, etc.). With useGlobalPkgs = true,
  # Home Manager inherits this setting.
  nixpkgs.config.allowUnfree = true;

  # ── Nix daemon ──────────────────────────────────────────────────────────
  # Determinate Systems installer manages its own daemon, so nix-darwin
  # must not try to manage Nix. This disables nix-darwin's nix.settings,
  # nix.package, and Linux builder options — Determinate handles all of it.
  nix.enable = false;

  # ── Homebrew (declarative) ──────────────────────────────────────────────
  # Replaces the manual .Brewfile. Casks and MAS apps declared here are
  # installed during `darwin-rebuild switch` via `brew bundle`.
  # Homebrew itself must be pre-installed: https://brew.sh
  homebrew = {
    enable = true;

    # CLI formulae (tools that need Homebrew specifically)
    brews = [
      "colima" # macOS VM for Docker daemon (Lima-based, needs Homebrew for VM lifecycle)
    ];

    # GUI applications (Homebrew casks)
    casks = [
      "betterdisplay"
      "chatgpt"
      "daisydisk"
      "discord"
      "firefox"
      "flashspace"
      "ghostty"
      "keyboard-cowboy"
      "pearcleaner"
      "postman"
      "raycast"
      "rectangle"
      "slack"
      "utm"
      "visual-studio-code"
      "wireshark-app"
    ];

    # Mac App Store apps (requires `mas` CLI and being signed in)
    masApps = {
      "Amphetamine" = 937984704;
    };

    # Activation behavior during `darwin-rebuild switch`
    onActivation = {
      autoUpdate = false; # Don't auto-update Homebrew itself
      upgrade = false; # Don't upgrade already-installed casks
      cleanup = "none"; # "none" | "uninstall" | "zap" — start conservative
    };
  };

  # ── System state version ────────────────────────────────────────────────
  # nix-darwin equivalent of home.stateVersion. Do not change without
  # reading release notes: https://github.com/nix-darwin/nix-darwin/releases
  system.stateVersion = 6;
}

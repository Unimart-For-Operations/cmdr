# home/03-features/gui.nix — GUI Applications Feature
#
# GUI applications that require a display server (Wayland or X11).
# Includes GPU-accelerated terminal emulators and desktop productivity apps.
# Only useful on machines with a graphical session.
#
# Desktop environments (Hyprland, DMS) live in 04-modules/gui/graduated/
# but are NOT included here — load them via the `desktop` field in meta.nix.
#
# Sandbox modules (e.g. wezterm) are opt-in per host via `sandbox` in meta.nix.
#
#   features = [ "gui" ];
{ pkgs, ... }:

{
  imports = [
    # ── Graduated ────────────────────────────────────────────────────────
    ../04-modules/gui/graduated/ghostty
    ../04-modules/gui/graduated/browsers/firefox
    ../04-modules/gui/graduated/communication/teams-for-linux
    ../04-modules/gui/graduated/kubernetes/headlamp
    ../04-modules/gui/graduated/file-managers/thunar
    ../04-modules/gui/graduated/vscode
    # ── Incubating ───────────────────────────────────────────────────────
    ../04-modules/gui/incubating/kitty
    ../04-modules/gui/incubating/alacritty
  ];

  # GUI apps managed via Nix across all platforms
  home.packages = with pkgs; [
    obsidian # Knowledge base / markdown notes (available on Linux + Darwin)
  ];
}

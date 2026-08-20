# home/03-features/gui.nix — GUI Applications Feature
#
# GUI applications that require a display server (Wayland or X11).
# Includes GPU-accelerated terminal emulators and desktop productivity apps.
# Only useful on machines with a graphical session.
#
# Desktop environments (Hyprland, DMS) live in 04-modules/gui/graduated/
# but are NOT included here — load them via the `desktop` field in meta.nix.
#
# Communication apps (Slack, Teams) are opt-in per host via `gui-apps` in meta.nix.
#
#   features = [ "gui" ];
#   gui-apps = [ "slack" "teams-for-linux" ];
{ pkgs, ... }:

{
  imports = [
    # ── Graduated ────────────────────────────────────────────────────────
    # Terminal emulators (all graduated — pick your preferred one)
    ../04-modules/gui/graduated/ghostty
    ../04-modules/gui/graduated/kitty
    ../04-modules/gui/graduated/alacritty
    ../04-modules/gui/graduated/wezterm
    # Applications
    ../04-modules/gui/graduated/browsers/firefox
    ../04-modules/gui/graduated/kubernetes/headlamp
    ../04-modules/gui/graduated/vscode
  ];

  # GUI apps managed via Nix across all platforms
  home.packages = with pkgs; [
    obsidian # Knowledge base / markdown notes (available on Linux + Darwin)
  ];
}

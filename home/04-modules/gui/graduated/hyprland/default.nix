# Hyprland Desktop Environment Module
# CachyOS ships its own /usr/bin/start-hyprland which reads ~/.config/hypr/hyprland.conf.
#
# DankMaterialShell (enabled in hosts/cachyos via flake.nix) replaces:
#   waybar, rofi, mako, hyprlock, hypridle, wlogout, pamixer
#
# NOTE: hyprland.conf is NOT managed as an xdg.configFile symlink.
# DMS (dms setup) must be able to write/merge ~/.config/hypr/hyprland.conf
# directly, which is incompatible with a read-only nix store symlink.
# The file in this repo (hyprland.conf) serves as the reference/seed copy.
# To bootstrap a new machine: cp hyprland.conf ~/.config/hypr/hyprland.conf
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Wallpaper daemon
    hyprpaper

    # Screenshot
    grim # Screenshot tool
    slurp # Region selector

    # Clipboard
    wl-clipboard # wl-copy / wl-paste
    cliphist # Clipboard history

    # Wayland utilities
    xdg-utils
    playerctl # Media key control
    brightnessctl # Brightness control
    networkmanagerapplet # nm-applet for system tray
    polkit_gnome # Authentication agent
    cups-pk-helper # Polkit helper for CUPS printing
  ];

  xdg.configFile = {
    # hyprland.conf intentionally excluded — DMS owns it (see comment above)
    "hypr/hyprpaper.conf".source = ./hyprpaper.conf;
  };
}

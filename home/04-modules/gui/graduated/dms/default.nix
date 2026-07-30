# DankMaterialShell Module
#
# Enables and configures DankMaterialShell — a full Wayland desktop shell that
# replaces waybar, rofi, mako, hyprlock, hypridle, and wlogout.
#
# The DMS Home Manager option is provided by the flake input:
#   inputs.dms.homeModules.dank-material-shell
# which is imported here so any host loading this module gets the option set.
#
# The nixGL GPU driver wrapper (needed on non-NixOS distros) is machine-specific
# and lives in the host's default.nix rather than here.
{ inputs, ... }:

{
  imports = [
    inputs.dms.homeModules.dank-material-shell
  ];

  programs.dank-material-shell = {
    enable = true;
    systemd.enable = true; # auto-start via systemd user service
    enableSystemMonitoring = true; # dgop: CPU/RAM/GPU widgets
    enableDynamicTheming = true; # matugen: wallpaper-based theming
    enableClipboardPaste = true; # wtype: paste from clipboard history
  };
}

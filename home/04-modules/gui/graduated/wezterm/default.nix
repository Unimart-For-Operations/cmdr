# WezTerm terminal emulator
# Installed via Nix on both platforms.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    wezterm
  ];
}

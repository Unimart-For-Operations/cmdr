# home/03-features/base.nix — Universal Baseline
#
# Loaded by every host unconditionally (hardcoded in 02-hosts/default.nix).
# Contains only the two settings that Home Manager requires to function.
# Everything else belongs in a feature (e.g. 03-features/cli.nix).
{ ... }:

{
  # Home Manager release compatibility — do not change without reading release notes
  home.stateVersion = "24.05";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}

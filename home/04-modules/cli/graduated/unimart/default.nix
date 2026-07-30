# home/04-modules/cli/graduated/unimart/default.nix
#
# Unified CLI for the idpbuilder organization.
# Built from the meta repo flake (git+ssh://git@github.com/idpbuilder/meta.git).
#
# Version is pinned via cmdr's flake.lock. To bump:
#   1. Push changes to idpbuilder/meta
#   2. Run: nix flake update meta (in cmdr)
#   3. Run: make switch
{ config, inputs, pkgs, ... }:

{
  home.packages = [
    inputs.meta.packages.${pkgs.stdenv.hostPlatform.system}.unimart
  ];

  home.sessionVariables = {
    UNIMART_ORG_DIR = "${config.home.homeDirectory}/repos/meta";
  };
}

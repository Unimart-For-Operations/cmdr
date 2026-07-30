# Podman runtime tooling — incubating, not part of the idpbuilder runtime path
#
# Podman remains useful for rootless ad hoc container workflows, but
# idpbuilder/unimart freezer uses Docker + Kind as the supported control-plane
# runtime.
{ pkgs, lib, ... }:

{
  services.podman.enable = lib.mkIf pkgs.stdenv.isLinux true;

  home.packages = with pkgs; [
    podman
    podman-compose
  ];
}

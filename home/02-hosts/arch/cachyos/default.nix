{ pkgs, lib, inputs, ... }:

let
  nixGLIntel = inputs.nixgl.packages.${pkgs.system}.nixGLIntel;
  dmsPackage = inputs.dms.packages.${pkgs.system}.default;
in
{
  # Machine-specific: this host has an Intel GPU.
  # The Nix-built quickshell inside DMS cannot find the system EGL/GPU drivers
  # on CachyOS (non-NixOS). Wrap the ExecStart with nixGLIntel so the correct
  # libEGL / Mesa paths are injected at launch time.
  # DMS configuration lives in modules/dms/default.nix.
  systemd.user.services.dms = {
    Service.ExecStart = lib.mkForce "${nixGLIntel}/bin/nixGLIntel ${dmsPackage}/bin/dms run --session";
  };
}

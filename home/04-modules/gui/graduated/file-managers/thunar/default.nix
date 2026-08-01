{ pkgs, lib, ... }:

{
  # thunar is Linux-only; darwin hosts get a file manager via Finder.
  home.packages = with pkgs; lib.optionals pkgs.stdenv.isLinux [
    thunar
  ];
}

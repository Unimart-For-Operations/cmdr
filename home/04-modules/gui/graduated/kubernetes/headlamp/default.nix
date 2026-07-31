{ pkgs, ... }:

{
  home.packages = with pkgs; [
    headlamp
  ];
}

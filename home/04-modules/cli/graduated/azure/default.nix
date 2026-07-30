# Azure CLI — Microsoft Azure cloud tooling
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    azure-cli # az command — resource management, AKS login, etc.
  ];
}

# Terraform — Infrastructure as Code
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    terraform # Infrastructure as Code tool
    terraform-ls # Terraform Language Server for editor support
  ];
}

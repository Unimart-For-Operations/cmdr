# Pulumi — Infrastructure as Code
# Uses the pre-built binary (pulumi-bin) rather than pulumi from nixpkgs
# to avoid long compile times and to match the version used in CI.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    pulumi-bin # IaC CLI — pre-built binary
  ];
}

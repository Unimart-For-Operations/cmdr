# Containerization — container runtimes, orchestration, and Kubernetes tooling
#
# Internal tiered organization:
#   graduated/   — stable, known-needed tools (kubectl, fluxcd, kubelogin)
#   incubating/  — experimental runtimes kept out of the default path
{ ... }:

{
  imports = [
    ./graduated/docker.nix
    ./graduated/kubernetes.nix
    ./incubating/podman.nix
  ];
}

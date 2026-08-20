# home/03-features/cli-containers.nix — Container & Orchestration Tools
#
# Docker, Kubernetes CLI, and container runtimes (Podman).
# Required for IDP platform work and container-based development.
#
# Includes:
#   - docker — Docker Engine CLI + Kind for local Kubernetes
#   - kubernetes — kubectl, fluxcd, kubelogin
#   - podman — Alternative container runtime (incubating)
#
#   features = [ "cli-core" "cli-containers" ];
{ ... }:

{
  imports = [
    ../04-modules/cli/graduated/containerization
  ];
}

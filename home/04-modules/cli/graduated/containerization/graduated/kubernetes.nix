# Kubernetes CLI tooling — stable, known-needed
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    kubectl # Kubernetes CLI
    fluxcd # GitOps toolkit for Kubernetes
    kubelogin # Azure AD credential plugin for AKS authentication
  ];
}

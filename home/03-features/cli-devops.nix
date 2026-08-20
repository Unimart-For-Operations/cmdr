# home/03-features/cli-devops.nix — Cloud & Infrastructure-as-Code Tools
#
# Cloud platform SDKs and infrastructure tooling:
#   - aws — AWS CLI + Session Manager
#   - terraform — Terraform + terraform-ls
#   - pulumi — Pulumi IaC framework
#   - azure — Azure CLI
#   - claude-code — Claude code-generation CLI
#
# Optional feature — only load if you actively use these tools.
# Reduces baseline CLI bloat for teams focused on container/K8s workflows.
#
#   features = [ "cli-core" "cli-containers" "cli-devops" ];
{ ... }:

{
  imports = [
    ../04-modules/cli/graduated/aws
    ../04-modules/cli/graduated/terraform
    ../04-modules/cli/graduated/pulumi
    ../04-modules/cli/graduated/azure
    ../04-modules/cli/graduated/claude-code
  ];
}

# home/03-features/cli.nix — Full CLI Stack (Convenience Bundle)
#
# Composition of all CLI sub-features: core, languages, containers, devops, and org tools.
# Use this for maximum convenience if you want everything.
#
# For finer granularity, use sub-features directly:
#   features = [ "cli-core" "cli-containers" "cli-languages" ];
#
# Available sub-features:
#   - cli-core       ← Essential shell, git, SSH, CLI replacements (minimal baseline)
#   - cli-languages  ← Go, Python
#   - cli-containers ← Docker, Kubernetes, Podman
#   - cli-devops     ← AWS, Terraform, Pulumi, Azure, Claude-Code
#   - cli-org        ← OpenCode, Unimart
#
#   features = [ "cli" ];  # ← Loads all sub-features
{ ... }:

{
  imports = [
    ./cli-core.nix
    ./cli-languages.nix
    ./cli-containers.nix
    ./cli-devops.nix
    ./cli-org.nix
  ];
}

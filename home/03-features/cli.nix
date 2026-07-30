# home/03-features/cli.nix — CLI Tools Feature
#
# All command-line tools needed for a development workflow.
# No display server required — works on bare Linux consoles and SSH sessions.
#
# Includes graduated + incubating modules. Sandbox modules are opt-in
# per host via the `sandbox` field in meta.nix.
#
# Replaces: terminal.nix (CLI portion), languages.nix, cloud.nix (CLI portion)
#
#   features = [ "cli" ];
{ ... }:

{
  imports = [
    # ── Graduated ────────────────────────────────────────────────────────
    ../04-modules/cli/graduated/core-utils
    ../04-modules/cli/graduated/fonts
    ../04-modules/cli/graduated/git
    ../04-modules/cli/graduated/ssh
    ../04-modules/cli/graduated/zsh
    ../04-modules/cli/graduated/starship
    ../04-modules/cli/graduated/atuin
    ../04-modules/cli/graduated/direnv
    ../04-modules/cli/graduated/fzf
    ../04-modules/cli/graduated/zoxide
    ../04-modules/cli/graduated/bat
    ../04-modules/cli/graduated/eza
    ../04-modules/cli/graduated/aws
    ../04-modules/cli/graduated/terraform
    ../04-modules/cli/graduated/containerization
    ../04-modules/cli/graduated/go
    ../04-modules/cli/graduated/opencode
    ../04-modules/cli/graduated/python
    ../04-modules/cli/graduated/azure
    ../04-modules/cli/graduated/pulumi
    ../04-modules/cli/graduated/unimart
  ];
}

# home/03-features/cli-org.nix — Organization-Specific Tools
#
# Unimart organization CLIs:
#   - opencode — OpenCode CLI framework
#   - unimart — Unimart org coordinator CLI
#
# Enables org-wide workflows and platform coordination.
#
#   features = [ "cli-core" "cli-org" ];
{ ... }:

{
  imports = [
    ../04-modules/cli/graduated/opencode
    ../04-modules/cli/graduated/unimart
  ];
}

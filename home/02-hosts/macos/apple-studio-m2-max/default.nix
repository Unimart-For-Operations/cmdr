{ ... }:

{
  # Personal SSH key for all connections on this machine.
  # The default git email (andrcmdr@protonmail.com) is already set in
  # modules/git/default.nix — no override needed here.
  programs.ssh = {
    matchBlocks = {
      "*" = {
        identityFile = "~/.ssh/id_ed25519";
      };
    };
  };
}

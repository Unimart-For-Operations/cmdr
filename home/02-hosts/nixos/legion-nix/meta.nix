{
  description = "legion-nix — NixOS workstation";
  system = "x86_64-linux";
  username = "cmdr";
  homeDirectory = "/home/cmdr";
  gitName = "Andrew Mortimer";
  gitEmail = "andrcmdr@protonmail.com";
  role = "tty-engineer";
  capabilities = [ "baseline" "terminal-dev" "operator" ];
  features = [ "cli" "tui" ];
}

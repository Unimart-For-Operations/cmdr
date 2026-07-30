{
  description = "strix-nix — NixOS TTY workstation";
  system = "x86_64-linux";
  username = "cmdr";
  homeDirectory = "/home/cmdr";
  gitName = "Andrew Mortimer";
  gitEmail = "andrcmdr@protonmail.com";
  role = "tty-engineer";
  capabilities = [ "baseline" "terminal-dev" ];
  features = [ "cli" "tty" "tui" ];
  # No gui — TTY-only, no display server
  # No desktop modules — add when Hyprland/DMS is needed
  theme = "catppuccin-mocha";
}

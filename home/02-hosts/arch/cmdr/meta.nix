{
  description = "cmdr — Arch Linux primary workstation";
  system = "x86_64-linux";
  username = "cmdr";
  homeDirectory = "/home/cmdr";
  gitName = "Andrew Mortimer";
  gitEmail = "andrcmdr@protonmail.com";
  role = "tty-engineer";
  capabilities = [ "baseline" "terminal-dev" "operator" ];
  features = [ "cli" "tui" ];
  # No gui — TTY-only, no display server
  # No desktop modules — add when Hyprland/DMS is needed
}

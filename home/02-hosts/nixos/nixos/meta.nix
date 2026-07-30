{
  description = "NixOS workstation";
  system = "x86_64-linux";
  username = "cmdr";
  homeDirectory = "/home/cmdr";
  gitName = "Andrew Mortimer";
  gitEmail = "andrcmdr@protonmail.com";
  role = "developer-workstation";
  capabilities = [ "baseline" "terminal-dev" "operator" "idp-local" "desktop" ];
  features = [ "cli" "tui" "gui" ];
  desktop = [ "hyprland" "dms" ];
  theme = "catppuccin-frappe";
}

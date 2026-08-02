{
  description = "strix-nix — NixOS Hyprland workstation";
  system = "x86_64-linux";
  username = "cmdr";
  homeDirectory = "/home/cmdr";
  gitName = "Andrew Mortimer";
  gitEmail = "andrcmdr@protonmail.com";
  role = "developer-workstation";
  capabilities = [ "baseline" "terminal-dev" "operator" "idp-local" "desktop" "gaming" ];
  features = [ "cli" "tui" "gui" "gaming" ];
  desktop = [ "hyprland" "dms" ];
  theme = "catppuccin-mocha";
}

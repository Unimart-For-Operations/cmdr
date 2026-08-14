{
  description = "Describe the machine briefly";
  system = "x86_64-linux"; # or "aarch64-darwin"
  username = "cmdr";
  homeDirectory = "/home/cmdr";

  # Identity — used by the git module and any future signing config.
  gitName = "Your Name";
  gitEmail = "you@example.com";

  # Semantic role for provisioning/orchestration. This describes what the
  # physical unit is meant to become; features below describe the Nix modules
  # that implement that role.
  # Common roles: "tty-engineer", "developer-workstation", "platform-operator"
  role = "tty-engineer";

  # Capability declarations for meta/unimart planning. These are semantic and
  # additive; they do not directly import modules.
  # Common capabilities: "baseline", "terminal-dev", "operator", "idp-local", "desktop"
  capabilities = [ "baseline" "terminal-dev" ];

  # Features this machine needs (strings resolved by the discovery engine).
  # Available: "cli", "tui", "gui", "tty"
  features = [ "cli" "tui" ];

  # Desktop environments (requires "gui" in features).
  # Available: "hyprland", "dms"
  # desktop = [ "hyprland" "dms" ];

  # Sandbox modules — opt-in experimental tools.
  # Available: "wezterm"
  # sandbox = [ "wezterm" ];

}

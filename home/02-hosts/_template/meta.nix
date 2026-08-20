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
  # Available:
  #   - "cli"           ← Full CLI stack (convenience: all sub-features below)
  #   - "cli-core"      ← Essential: shell, git, SSH, CLI replacements
  #   - "cli-languages" ← Go, Python
  #   - "cli-containers"← Docker, Kubernetes, Podman
  #   - "cli-devops"    ← AWS, Terraform, Pulumi, Azure, Claude-Code
  #   - "cli-org"       ← OpenCode, Unimart
  #   - "tui"           ← Terminal UI tools: tmux, nvim, lazygit, yazi, k9s
  #   - "gui"           ← GUI apps: browsers, editors, terminals
  #   - "tty"           ← Minimal TTY baseline (cli-core + tmux, nvim, yazi)
  #
  # Examples:
  #   Minimal headless:     features = [ "tty" ];
  #   Full developer:       features = [ "cli" "tui" "gui" ];
  #   Cloud-free dev:       features = [ "cli-core" "cli-languages" "cli-containers" "tui" ];
  features = [ "cli" "tui" ];

  # Desktop environments (requires "gui" in features).
  # Available: "hyprland", "dms"
  # desktop = [ "hyprland" "dms" ];

  # GUI applications (requires "gui" in features).
  # Available: "slack", "teams-for-linux"
  # gui-apps = [ "slack" "teams-for-linux" ];

}

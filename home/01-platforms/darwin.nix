{ ... }:

# macOS platform configuration
# OS-level settings and PATH configuration specific to Darwin.
# Shell customizations are in 04-modules/cli/graduated/zsh/platform-darwin.zsh.nix
{
  # XDG_CONFIG_HOME is set in zsh config, so HM must know to use
  # ~/.config/ instead of ~/Library/Application Support/ for programs
  # that have macOS-specific path logic (k9s, lazygit, lazydocker, etc.)
  xdg.enable = true;

  imports = [
    ./darwin-packages.nix
    ../04-modules/cli/graduated/zsh/platform-darwin.zsh.nix
  ];

  # Platform-specific PATH entries
  home.sessionPath = [
    "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
    "/opt/homebrew/opt/gnu-sed/libexec/gnubin"
    "$HOME/.local/bin"
  ];

  # macOS system defaults
  targets.darwin = {
    currentHostDefaults = {
      "com.apple.controlcenter".BatteryShowPercentage = true;
    };
  };
}

# home/03-features/tty.nix -- Minimal TTY Feature
#
# Lean terminal-only baseline for headless boxes, VMs, and remote shells.
# Includes only cli-core (shell, git, SSH, core utils) and essential TUI apps.
#
#   features = [ "tty" ];
{ ... }:

{
  imports = [
    # -- CLI essentials (uses cli-core sub-feature directly) -----------
    ../04-modules/cli/graduated/core-utils
    ../04-modules/cli/graduated/git
    ../04-modules/cli/graduated/ssh
    ../04-modules/cli/graduated/zsh
    ../04-modules/cli/graduated/starship
    ../04-modules/cli/graduated/fzf
    ../04-modules/cli/graduated/zoxide
    ../04-modules/cli/graduated/bat
    ../04-modules/cli/graduated/eza

    # -- TTY apps (editor, multiplexer, file manager) -----------------
    ../04-modules/tui/graduated/tmux
    ../04-modules/tui/graduated/nvim
    ../04-modules/tui/graduated/yazi
  ];
}

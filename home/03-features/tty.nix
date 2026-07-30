# home/03-features/tty.nix -- Minimal TTY Feature
#
# Lean terminal-only baseline for headless boxes, VMs, and remote shells.
# Keeps only essential CLI + terminal workflow modules and skips cloud/lang
# stacks and GUI dependencies.
#
#   features = [ "tty" ];
{ ... }:

{
  imports = [
    # -- CLI essentials ------------------------------------------------------
    ../04-modules/cli/graduated/core-utils
    ../04-modules/cli/graduated/git
    ../04-modules/cli/graduated/ssh
    ../04-modules/cli/graduated/zsh
    ../04-modules/cli/graduated/starship
    ../04-modules/cli/graduated/fzf
    ../04-modules/cli/graduated/zoxide
    ../04-modules/cli/graduated/bat
    ../04-modules/cli/graduated/eza

    # -- TTY apps ------------------------------------------------------------
    ../04-modules/tui/graduated/tmux
    ../04-modules/tui/graduated/nvim
    ../04-modules/tui/graduated/yazi
  ];
}

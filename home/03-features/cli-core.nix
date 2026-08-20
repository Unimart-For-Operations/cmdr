# home/03-features/cli-core.nix — Core CLI Tools
#
# Essential command-line utilities: shell, git, SSH, CLI replacements (bat, eza, fzf),
# and core infrastructure (fonts, direnv).
#
# This is the minimal CLI baseline. Works on bare Linux consoles and SSH sessions.
# Requires no additional dependencies.
#
#   features = [ "cli-core" ];
{ ... }:

{
  imports = [
    # ── Core Shell & VCS ─────────────────────────────────────────────────
    ../04-modules/cli/graduated/core-utils
    ../04-modules/cli/graduated/fonts
    ../04-modules/cli/graduated/git
    ../04-modules/cli/graduated/ssh
    ../04-modules/cli/graduated/zsh
    ../04-modules/cli/graduated/starship
    ../04-modules/cli/graduated/atuin
    # ── Development Environment ──────────────────────────────────────────
    ../04-modules/cli/graduated/direnv
    # ── CLI Replacements ─────────────────────────────────────────────────
    ../04-modules/cli/graduated/fzf
    ../04-modules/cli/graduated/zoxide
    ../04-modules/cli/graduated/bat
    ../04-modules/cli/graduated/eza
  ];
}

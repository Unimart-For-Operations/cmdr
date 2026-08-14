{ pkgs, ... }:

{
  # Add overrides here only when this machine diverges from the shared baseline.

  home.packages = [
    pkgs.bluetuith
    pkgs.gcc
    pkgs.kbd
    pkgs.terminus_font
  ];

  # Manual helper: run in a Linux TTY to apply the font to the current VC.
  home.file.".local/bin/apply-tty-font" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      FONT_NAME="''${1:-''${TTY_FONT:-ter-v18n}}"

      if setfont "''${FONT_NAME}" 2>/dev/null; then
        exit 0
      fi

      if sudo -n setfont "''${FONT_NAME}" 2>/dev/null; then
        exit 0
      fi

      sudo setfont "''${FONT_NAME}"
    '';
  };

  programs.zsh.shellAliases.tty-font-apply = "~/.local/bin/apply-tty-font";
  home.sessionVariables.TTY_FONT = "ter-v18n";

  # NixOS keeps /etc/passwd shell at bash unless changed in system config.
  # Trampoline from bash login/non-login sessions into zsh for this host.
  home.file.".bash_profile".text = ''
    if [ -n "''${BASH_VERSION:-}" ] && [ -t 1 ] && [ -z "''${ZSH_VERSION:-}" ] && command -v zsh >/dev/null 2>&1; then
      exec zsh -l
    fi
  '';

  home.file.".bashrc".text = ''
    if [ -n "''${BASH_VERSION:-}" ] && [ -t 1 ] && [ -z "''${ZSH_VERSION:-}" ] && command -v zsh >/dev/null 2>&1; then
      exec zsh
    fi
  '';
}

{ config, pkgs, ... }:

{
  # Add overrides here only when this machine diverges from the shared baseline.

  home.packages = [
    pkgs.gcc
    pkgs.kbd
    pkgs.terminus_font
  ];

  # Linux virtual console palette (Catppuccin Mocha) for TERM=linux TTYs.
  home.file.".config/vtrgb-catppuccin-mocha".text = ''
    69,243,166,249,137,203,148,186,88,243,166,249,137,203,148,166
    71,139,227,226,180,166,226,194,91,139,227,226,180,166,226,173
    90,168,161,175,250,247,213,222,112,168,161,175,250,247,213,200
  '';

  # Manual helper: run in a Linux TTY to apply the palette to the current VC.
  home.file.".local/bin/apply-vtrgb-theme" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      THEME_FILE="${config.home.homeDirectory}/.config/vtrgb-catppuccin-mocha"
      if ! sudo -n setvtrgb "''${THEME_FILE}" 2>/dev/null; then
        sudo setvtrgb "''${THEME_FILE}"
      fi
    '';
  };

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

  programs.zsh.shellAliases.vtrgb-apply = "~/.local/bin/apply-vtrgb-theme";
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

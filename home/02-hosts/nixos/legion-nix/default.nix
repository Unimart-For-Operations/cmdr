{ ... }:

{
  # ── Shell Trampoline ──────────────────────────────────────────
  # NixOS keeps /etc/passwd shell at bash unless changed in system config.
  # Trampoline from bash login/non-login sessions into zsh for this host.
  home.file.".bash_profile".text = ''
    if [ -n "''${BASH_VERSION:-}" ] && [ -t 1 ] && [ -z "''${ZSH_VERSION:-}" ] && command -v zsh >/dev/null 2>&1; then
      exec zsh -l
    fi
  '';

  home.file.".bashrc".text = ''
    if [ -n "''${BASH_VERSION:-}" ] && [ -t 0 ] && [ -t 1 ] && [ -z "''${ZSH_VERSION:-}" ] && command -v zsh >/dev/null 2>&1; then
      exec zsh
    fi
  '';
}

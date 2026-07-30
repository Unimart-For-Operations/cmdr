# macOS-specific shell configuration
#
# Platform-level aliases, variables, and environment setup for Darwin.
# Imported by home/01-platforms/darwin.nix.
{ config, lib, ... }:

{
  # ── macOS session variables (set in .zshenv) ─────────────────────────────
  programs.zsh.sessionVariables = {
    HOMEBREW_NO_ANALYTICS = "1";
    HOMEBREW_NO_ENV_HINTS = "1";

    # Docker socket — Colima provides the Docker daemon on macOS via a Lima VM.
    # This must be set explicitly because the Docker CLI defaults to Docker Desktop's
    # socket, which doesn't exist. Colima's socket path is stable across restarts.
    DOCKER_HOST = "unix:///Users/\${USER}/.config/colima/default/docker.sock";
  };

  # ── macOS PATH entries ───────────────────────────────────────────────────
  home.sessionPath = [
    "$HOME/.pulumi/bin"
  ];

  # ── macOS aliases ────────────────────────────────────────────────────────
  programs.zsh.shellAliases = {
    # Homebrew (casks managed declaratively by nix-darwin — see darwin/system.nix)
    bl = "brew list";
    bi = "brew install";
    bu = "brew update; brew upgrade; brew cleanup --prune=all";

    # Direnv manual shortcuts (auto-hooks via Home Manager; these are for manual use)
    de = ''eval "$(direnv hook zsh)"'';
    da = "direnv allow";

  };

  # ── macOS initContent — Homebrew env ──────────────────────────────────────
  # Priority 700: must run before the multiplexer auto-start (900).
  programs.zsh.initContent = lib.mkOrder 700 ''
    # Homebrew environment (adds brew to PATH, sets HOMEBREW_PREFIX, etc.)
    eval "$(/opt/homebrew/bin/brew shellenv)"
  '';
}

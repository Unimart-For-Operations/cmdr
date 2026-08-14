# ZSH — core shell configuration
#
# All shell configuration is managed declaratively through Home Manager's
# programs.zsh.* options:
#   - shellAliases:      simple command shortcuts (merged across modules)
#   - sessionVariables:  environment variables (set once in .zshenv)
#   - initContent:       complex shell logic, ordered via lib.mkOrder
#
# No xdg.configFile or glob-sourcing loop — everything is Nix-native.
#
# Ordering reference (Home Manager internal slots we must work around):
#   570  — compinit (HM)
#   700  — autosuggestions (HM)
#   910  — history options, fzf integration (HM)
#   950  — setopt (HM)
#   1000 — default user content / enableZshIntegration tools (HM)
#   1100 — shellAliases rendered (HM)
#   1200 — syntax-highlighting (HM)
{ config, pkgs, lib, hostMeta ? { }, ... }:

let
  # Common eza flags — extracted to avoid 7x duplication
  ezaIgnore = ''"Applications|Desktop|Documents|Downloads|Library|Movies|Music|Pictures|Public"'';
  ezaBase = "--group-directories-first --icons --ignore-glob ${ezaIgnore}";
  ttyRole = builtins.hasAttr "role" hostMeta && hostMeta.role == "tty-engineer";
in
{
  programs.zsh = {
    enable = true;

    # Keep zsh dotfiles in $HOME (not $XDG_CONFIG_HOME/zsh) — zsh requires
    # .zshenv in $HOME by default. Pinned because xdg.enable = true on macOS
    # would otherwise move them in future HM versions.
    dotDir = config.home.homeDirectory;

    # Completion — replaces manual compinit in 01-completion.zsh
    # Home Manager runs compinit at priority 570 internally
    enableCompletion = true;

    # Auto-suggestions (fish-style)
    autosuggestion.enable = true;

    # Syntax highlighting
    syntaxHighlighting.enable = true;

    # History
    history = {
      size = 1000000;
      save = 1000000;
      path = "${config.xdg.stateHome}/.zsh_history";
      extended = true;
      share = true;
      ignoreDups = true;
      ignoreAllDups = true;
      expireDuplicatesFirst = true;
    };

    # Keymap
    defaultKeymap = "emacs";

    # ── Session variables (written to .zshenv, set once per session) ─────────
    sessionVariables = {
      # XDG base directories
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_STATE_HOME = "$HOME/.local/state";
      XDG_CACHE_HOME = "$HOME/.cache";

      # Editors
      EDITOR = "nvim";
      VISUAL = "nvim";
      MANPAGER = "nvim +Man!";

      # Kubernetes
      KUBECONFIG = "$HOME/.config/kube/config";

      # eza colors — suppress permission/owner columns
      EZA_COLORS = "uu=0:gu=0:ur=0:uw=0:ux=0:ue=0:gr=0:gr=0:gx=0:tr=0:tw=0:tx=0";
    };

    # ── PATH entries (via Home Manager, deduplicated) ────────────────────────
    # Note: ~/.local/bin is set in platform files (darwin.nix sessionPath)
    # and the opencode bin path is added here for all platforms.

    # ── Aliases (declarative, merged across modules) ─────────────────────────
    shellAliases = {
      # Navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";

      # Safe defaults
      cp = "cp -i";
      mv = "mv -i";
      df = "df -h";
      grep = "grep --color=auto";

      # Editors — nvim is handled by wrapper scripts in ~/.local/bin/
      # (see 04-modules/tui/graduated/nvim/default.nix). No nvim aliases needed.
      vi = "nvim";
      vim = "nvim";

      # Git
      gd = "GIT_EXTERNAL_DIFF=difft git diff";

      # eza (ls replacement) — all aliases defined here for consistent
      # --group-directories-first and --ignore-glob behavior.
      # enableZshIntegration is disabled in eza/default.nix to avoid conflicts.
      l = "eza -la ${ezaBase}";
      ls = "eza ${ezaBase}";
      ll = "eza -ll ${ezaBase}";
      la = "eza -a ${ezaBase}";
      ltr = "eza -ll -snew ${ezaBase}";
      ltra = "eza -lla -snew ${ezaBase}";
      ldv = "eza -la -snew --git --tree --level=2 ${ezaBase}";

      # Tmux session management
      tls = "tmux ls";
      ta = "tmux attach -t";
      tkill = "tmux kill-session -t";
      tdev = "~/.config/tmux/layouts/dev-session.sh";
      tai = "~/.config/tmux/layouts/ai-session.sh";
      tidp = "~/.config/tmux/layouts/idp-session.sh";

    };

    # ── initContent — complex shell logic with explicit ordering ─────────────
    initContent = lib.mkMerge [

      # Opencode PATH — before tool integrations
      (lib.mkOrder 700 ''
        # Opencode CLI
        export PATH="${config.home.homeDirectory}/.opencode/bin:$PATH"
      '')

      (lib.mkOrder 705 ''
        # Wrapper precedence: ~/.local/bin contains managed command shims such
        # as nvim -> nvim-astro. Keep it ahead of the Nix profile even inside
        # long-lived tmux sessions that inherited an older PATH.
        path=("${config.home.homeDirectory}/.local/bin" $path)
        typeset -U path
      '')

      (lib.mkOrder 710 ''
        # idpbuilder/Kind needs Docker everywhere: Docker Engine on Linux and
        # Colima's Docker daemon on macOS. Never inherit Podman's socket as the
        # default Docker endpoint.
        if [[ "''${DOCKER_HOST:-}" == *"/podman/"* ]]; then
          unset DOCKER_HOST
        fi
      '')

      # Multiplexer auto-start (tmux)
      # Runs late enough that env is fully set, but before tool integrations.
      (lib.mkOrder 900 ''
        # Guard: skip if already inside a multiplexer or non-interactive shell
        if [[ -z "''${TMUX:-}" && -n "''${PS1:-}" \
              && "''${TERM_PROGRAM:-}" != "vscode" && -z "''${INSIDE_EMACS:-}" ]]; then
          command -v tmux &>/dev/null && tmux new-session -A -s main
        fi
      '')

      # Remaining tool integrations not handled by enableZshIntegration
      (lib.mkOrder 1000 ''
        # Prompt strategy:
        # - TTY-focused hosts and Linux virtual console: simple prompt
        # - Everything else: Starship
        if [[ "''${TERM:-}" == "linux" || ${if ttyRole then "true" else "false"} == true ]]; then
          PROMPT='%n@%m:%~ %# '
          RPROMPT=""
        elif command -v starship >/dev/null 2>&1; then
          eval "$(starship init zsh)"
        fi

        # VS Code shell integration
        if [[ "$TERM_PROGRAM" == "vscode" ]]; then
          . "$(code --locate-shell-integration-path zsh)" 2>/dev/null
        fi
      '')
    ];

    # Disabled — using Nix-native plugins instead
    oh-my-zsh.enable = false;
  };

}

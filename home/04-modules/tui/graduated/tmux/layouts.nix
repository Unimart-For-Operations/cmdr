{ config, pkgs, lib, ... }:

{
  # Tmux layout scripts deployed to ~/.config/tmux/layouts/
  # Shared helper is sourced by each layout script for DRY arg parsing,
  # path resolution, session management, and project-type detection.

  xdg.configFile = {
    # ── Shared helper library ──────────────────────────────────────────
    "tmux/layouts/_tmux-helpers.sh" = {
      text = ''
        #!/usr/bin/env bash
        # Shared helper functions for tmux layout scripts.
        # Source this file; do not execute it directly.
        #
        # Provides:
        #   parse_args $@                          – sets SESSION_NAME, EXPLICIT_PATH
        #   resolve_path NAME EXPLICIT FALLBACK..  – echoes resolved directory
        #   attach_or_create SESSION_NAME           – attaches if exists, returns 1 otherwise
        #   detect_project PATH                    – sets PROJECT_TYPE, PROJECT_DEV_CMD
        #
        # NOTE: No `set -e` — layout scripts use non-zero exits as control flow
        # (zoxide miss, command -v checks, attach_or_create returning 1).
        # Each function handles its own errors explicitly.

        set -uo pipefail

        # ── Argument parsing ───────────────────────────────────────────
        # Sets globals: SESSION_NAME, EXPLICIT_PATH
        parse_args() {
            SESSION_NAME="''${1:-}"
            EXPLICIT_PATH="''${2:-}"

            # "." means use current directory
            if [[ "$SESSION_NAME" == "." ]]; then
                SESSION_NAME="$(basename "$PWD")"
                EXPLICIT_PATH="$PWD"
            fi

            # Sanitize: tmux doesn't allow dots or colons in session names
            SESSION_NAME="''${SESSION_NAME//\./_}"
            SESSION_NAME="''${SESSION_NAME//:/_}"

            if [[ -z "$SESSION_NAME" ]]; then
                echo "Usage: $(basename "$0") <session-name> [path]"
                echo ""
                echo "  session-name   Name for the tmux session (use '.' for current dir)"
                echo "  path           Optional project directory"
                return 1
            fi
        }

        # ── Path resolution ────────────────────────────────────────────
        # Priority: explicit > zoxide > fallback dirs > $PWD
        # Usage: resolve_path "$SESSION_NAME" "$EXPLICIT_PATH" dir1 dir2 ...
        resolve_path() {
            local name="$1"; shift
            local explicit="$1"; shift
            # remaining args are fallback parent directories

            # 1. Explicit path
            if [[ -n "$explicit" && -d "$explicit" ]]; then
                echo "$explicit"
                return 0
            fi

            # 2. Zoxide query
            if command -v zoxide &>/dev/null; then
                local zpath
                zpath="$(zoxide query "$name" 2>/dev/null)" || true
                if [[ -n "$zpath" && -d "$zpath" ]]; then
                    echo "$zpath"
                    return 0
                fi
            fi

            # 3. Fallback parent dirs
            local parent
            for parent in "$@"; do
                if [[ -d "$parent/$name" ]]; then
                    echo "$parent/$name"
                    return 0
                fi
            done

            # 4. Current directory
            echo "$PWD"
        }

        # ── Session management ─────────────────────────────────────────
        # Returns 0 (and attaches/switches) if session already exists.
        # Returns 1 if the session does NOT exist (caller must create it).
        attach_or_create() {
            local session="$1"
            if ! tmux has-session -t "=$session" 2>/dev/null; then
                return 1
            fi
            # Session exists — attach or switch
            if [[ -n "''${TMUX:-}" ]]; then
                tmux switch-client -t "=$session"
            else
                tmux attach-session -t "=$session"
            fi
            return 0
        }

        # ── Final attach helper ────────────────────────────────────────
        # Call after session creation to attach/switch into it.
        attach_session() {
            local session="$1"
            if [[ -n "''${TMUX:-}" ]]; then
                tmux switch-client -t "=$session"
            else
                tmux attach-session -t "=$session"
            fi
        }

        # ── Project-type detection ─────────────────────────────────────
        # Sets PROJECT_TYPE to one of:
        #   nix | node | go | rust | python | terraform | elixir | ruby | generic
        # Also sets PROJECT_DEV_CMD with a sensible "run dev" command.
        detect_project() {
            local dir="$1"
            PROJECT_TYPE="generic"
            PROJECT_DEV_CMD=""

            # Order matters: more specific first
            if [[ -f "$dir/flake.nix" ]]; then
                PROJECT_TYPE="nix"
                PROJECT_DEV_CMD="nix develop"
            elif [[ -f "$dir/Cargo.toml" ]]; then
                PROJECT_TYPE="rust"
                PROJECT_DEV_CMD="cargo build"
            elif [[ -f "$dir/go.mod" ]]; then
                PROJECT_TYPE="go"
                PROJECT_DEV_CMD="go build ./..."
            elif [[ -f "$dir/package.json" ]]; then
                PROJECT_TYPE="node"
                # Prefer bun > pnpm > yarn > npm
                if [[ -f "$dir/bun.lockb" ]] || [[ -f "$dir/bun.lock" ]]; then
                    PROJECT_DEV_CMD="bun run dev"
                elif [[ -f "$dir/pnpm-lock.yaml" ]]; then
                    PROJECT_DEV_CMD="pnpm run dev"
                elif [[ -f "$dir/yarn.lock" ]]; then
                    PROJECT_DEV_CMD="yarn dev"
                else
                    PROJECT_DEV_CMD="npm run dev"
                fi
            elif [[ -f "$dir/pyproject.toml" ]] || [[ -f "$dir/setup.py" ]] || [[ -f "$dir/requirements.txt" ]]; then
                PROJECT_TYPE="python"
                if [[ -f "$dir/pyproject.toml" ]]; then
                    PROJECT_DEV_CMD="uv run python"
                else
                    PROJECT_DEV_CMD="python3"
                fi
            elif [[ -f "$dir/main.tf" ]] || [[ -f "$dir/terragrunt.hcl" ]]; then
                PROJECT_TYPE="terraform"
                if command -v tofu &>/dev/null; then
                    PROJECT_DEV_CMD="tofu plan"
                else
                    PROJECT_DEV_CMD="terraform plan"
                fi
            elif [[ -f "$dir/mix.exs" ]]; then
                PROJECT_TYPE="elixir"
                PROJECT_DEV_CMD="mix phx.server"
            elif [[ -f "$dir/Gemfile" ]]; then
                PROJECT_TYPE="ruby"
                if [[ -f "$dir/bin/rails" ]]; then
                    PROJECT_DEV_CMD="bin/rails server"
                else
                    PROJECT_DEV_CMD="bundle exec ruby"
                fi
            fi
        }
      '';
      executable = true;
    };

    # ── Development session layout ───────────────────────────────────
    "tmux/layouts/dev-session.sh" = {
      text = ''
        #!/usr/bin/env bash
        # Development Session Layout
        #
        # Creates a structured tmux workspace for development:
        #
        #   Window 1  editor    – 3-pane: nvim (top-left) + terminal (bottom-left) + opencode (right)
        #                         left 67% / right 33%, nvim ~65% height / terminal ~35% height
        #   Window 2  terminal  – two horizontal panes (shell | shell)
        #   Window 3  git       – lazygit (or git status fallback)
        #
        # Usage:
        #   dev-session.sh <session-name> [project-path]
        #   dev-session.sh .                              # use current directory
        #
        # Detected project types: nix, node, go, rust, python, terraform, elixir, ruby

        # shellcheck source=_tmux-helpers.sh
        source "''${XDG_CONFIG_HOME:-$HOME/.config}/tmux/layouts/_tmux-helpers.sh"

        parse_args "$@" || exit 1

        PROJECT_PATH=$(resolve_path "$SESSION_NAME" "$EXPLICIT_PATH" \
            "$HOME/Documents" "$HOME/projects" "$HOME/work")

        if [[ ! -d "$PROJECT_PATH" ]]; then
            echo "Error: directory does not exist: $PROJECT_PATH" >&2
            exit 1
        fi

        # If session already exists, just attach to it
        attach_or_create "$SESSION_NAME" && exit 0

        detect_project "$PROJECT_PATH"

        # ── Window 1: editor ───────────────────────────────────────────
        # Start with nvim-astro in the first pane
        tmux new-session -d -s "$SESSION_NAME" -n 'editor' -c "$PROJECT_PATH" \
            "nvim-astro ."

        # Right pane (33% width): opencode or plain shell
        if command -v opencode &>/dev/null; then
            tmux split-window -h -t "=$SESSION_NAME:1.0" -c "$PROJECT_PATH" -l 33% \
                "opencode ."
        else
            tmux split-window -h -t "=$SESSION_NAME:1.0" -c "$PROJECT_PATH" -l 33%
        fi

        # Bottom-left pane (35% height): plain terminal
        # Target pane 0 (nvim) to split below it, creating pane 2
        tmux split-window -v -t "=$SESSION_NAME:1.0" -c "$PROJECT_PATH" -l 35%

        # Focus the nvim pane (pane 0)
        tmux select-pane -t "=$SESSION_NAME:1.0"

        # ── Window 2: terminal ─────────────────────────────────────────
        tmux new-window -t "=$SESSION_NAME" -n 'terminal' -c "$PROJECT_PATH"
        tmux split-window -h -t "=$SESSION_NAME:2" -c "$PROJECT_PATH"

        # ── Window 3: git ──────────────────────────────────────────────
        if command -v lazygit &>/dev/null; then
            tmux new-window -t "=$SESSION_NAME" -n 'git' -c "$PROJECT_PATH" \
                "lazygit"
        else
            tmux new-window -t "=$SESSION_NAME" -n 'git' -c "$PROJECT_PATH"
            tmux send-keys -t "=$SESSION_NAME:3" "git status" C-m
        fi

        # ── Activate and attach ────────────────────────────────────────
        tmux select-window -t "=$SESSION_NAME:1"
        attach_session "$SESSION_NAME"
      '';
      executable = true;
    };

    # ── AI coding session layout ─────────────────────────────────────
    "tmux/layouts/ai-session.sh" = {
      text = ''
        #!/usr/bin/env bash
        # AI Coding Session Layout
        #
        # Side-by-side layout for AI-assisted development:
        #
        #   Window 1  ai       – left: opencode (60%), right: nvim (40%)
        #   Window 2  terminal – two horizontal panes
        #   Window 3  git      – lazygit
        #
        # Usage:
        #   ai-session.sh <session-name> [project-path]
        #   ai-session.sh .

        # shellcheck source=_tmux-helpers.sh
        source "''${XDG_CONFIG_HOME:-$HOME/.config}/tmux/layouts/_tmux-helpers.sh"

        parse_args "$@" || exit 1

        PROJECT_PATH=$(resolve_path "$SESSION_NAME" "$EXPLICIT_PATH" \
            "$HOME/Documents" "$HOME/projects" "$HOME/work")

        if [[ ! -d "$PROJECT_PATH" ]]; then
            echo "Error: directory does not exist: $PROJECT_PATH" >&2
            exit 1
        fi

        # If session already exists, just attach to it
        attach_or_create "$SESSION_NAME" && exit 0

        detect_project "$PROJECT_PATH"

        # ── Window 1: ai (opencode + editor) ───────────────────────────
        # Left pane (60%): opencode
        if command -v opencode &>/dev/null; then
            tmux new-session -d -s "$SESSION_NAME" -n 'ai' -c "$PROJECT_PATH" \
                "opencode ."
        else
            tmux new-session -d -s "$SESSION_NAME" -n 'ai' -c "$PROJECT_PATH"
        fi

        # Right pane (40%): nvim-astro
        tmux split-window -h -t "=$SESSION_NAME:1.0" -c "$PROJECT_PATH" -l 40% \
            "nvim-astro ."

        # Focus the opencode pane (pane 0)
        tmux select-pane -t "=$SESSION_NAME:1.0"

        # ── Window 2: terminal ─────────────────────────────────────────
        tmux new-window -t "=$SESSION_NAME" -n 'terminal' -c "$PROJECT_PATH"
        tmux split-window -h -t "=$SESSION_NAME:2" -c "$PROJECT_PATH"

        # ── Window 3: git ──────────────────────────────────────────────
        if command -v lazygit &>/dev/null; then
            tmux new-window -t "=$SESSION_NAME" -n 'git' -c "$PROJECT_PATH" \
                "lazygit"
        else
            tmux new-window -t "=$SESSION_NAME" -n 'git' -c "$PROJECT_PATH"
            tmux send-keys -t "=$SESSION_NAME:3" "git status" C-m
        fi

        # ── Activate and attach ────────────────────────────────────────
        tmux select-window -t "=$SESSION_NAME:1"
        attach_session "$SESSION_NAME"
      '';
      executable = true;
    };

    # ── idpbuilder org session layout ──────────────────────────────────
    "tmux/layouts/idp-session.sh" = {
      text = ''
        #!/usr/bin/env bash
        # idpbuilder Org Session Layout
        #
        # Multi-repo workspace for the idpbuilder GitHub organization:
        #
        #   Window 1  org      – 6-pane grid (3 columns x 2 rows)
        #     Col 1 (25%):  Obsidian vault docs (top)  |  idpbuilder repo (bottom)
        #     Col 2 (25%):  docs repo (top)            |  idpctl repo (bottom)
        #     Col 3 (50%):  org root (top)             |  org root (bottom)
        #
        #   Window 2  lazygit  – 5 equal vertical panes, each running lazygit
        #     org root | cmdr | docs | idpbuilder | idpctl
        #
        # Usage:
        #   idp-session.sh

        # shellcheck source=_tmux-helpers.sh
        source "''${XDG_CONFIG_HOME:-$HOME/.config}/tmux/layouts/_tmux-helpers.sh"

        SESSION_NAME="idpbuilder"
        ORG_ROOT="$HOME/repos/Unimart-For-Operations/meta"
        OBSIDIAN_DOCS="$HOME/Documents/cmdr/Professional/organizations/idpbuilder/cmdr"

        # Repo directories
        REPO_CMDR="$ORG_ROOT/cmdr"
        REPO_IDPBUILDER="$ORG_ROOT/idpbuilder"
        REPO_IDPCTL="$ORG_ROOT/idpctl"
        REPO_DOCS="$ORG_ROOT/docs"

        # If session already exists, just attach to it
        attach_or_create "$SESSION_NAME" && exit 0

        # Verify org root exists
        if [[ ! -d "$ORG_ROOT" ]]; then
            echo "Error: org directory does not exist: $ORG_ROOT" >&2
            exit 1
        fi

        # Fall back to cmdr docs in the repo if Obsidian vault isn't available
        if [[ ! -d "$OBSIDIAN_DOCS" ]]; then
            OBSIDIAN_DOCS="$REPO_CMDR/docs"
        fi

        # ── Window 1: org (3 columns x 2 rows) ────────────────────────────
        # Create session with first pane in org root
        tmux new-session -d -s "$SESSION_NAME" -n 'org' -c "$ORG_ROOT"

        # Create 3 vertical columns by splitting horizontally twice
        tmux split-window -h -t "=$SESSION_NAME:1.1" -c "$REPO_DOCS"
        tmux split-window -h -t "=$SESSION_NAME:1.1" -c "$OBSIDIAN_DOCS"

        # Now split each column vertically to create top/bottom pairs
        # Pane numbering after the horizontal splits: 1=left, 2=middle, 3=right
        tmux split-window -v -t "=$SESSION_NAME:1.1" -c "$REPO_IDPBUILDER"
        tmux split-window -v -t "=$SESSION_NAME:1.3" -c "$REPO_IDPCTL"
        tmux split-window -v -t "=$SESSION_NAME:1.5" -c "$ORG_ROOT"

        # Focus the first pane
        tmux select-pane -t "=$SESSION_NAME:1.1"

        # ── Window 2: lazygit (5 equal vertical panes) ─────────────────────
        tmux new-window -t "=$SESSION_NAME" -n 'lazygit' -c "$ORG_ROOT"

        # Create 4 more panes by splitting horizontally
        tmux split-window -h -t "=$SESSION_NAME:2.1" -c "$REPO_CMDR"
        tmux split-window -h -t "=$SESSION_NAME:2.2" -c "$REPO_DOCS"
        tmux split-window -h -t "=$SESSION_NAME:2.3" -c "$REPO_IDPBUILDER"
        tmux split-window -h -t "=$SESSION_NAME:2.4" -c "$REPO_IDPCTL"

        # Equalize the panes
        tmux select-layout -t "=$SESSION_NAME:2" even-horizontal

        # Launch lazygit in each pane
        for pane in 1 2 3 4 5; do
            tmux send-keys -t "=$SESSION_NAME:2.$pane" "lazygit" C-m
        done

        # ── Activate and attach ────────────────────────────────────────────
        tmux select-window -t "=$SESSION_NAME:1"
        tmux select-pane -t "=$SESSION_NAME:1.1"
        attach_session "$SESSION_NAME"
      '';
      executable = true;
    };
  };
}

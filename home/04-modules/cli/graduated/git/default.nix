# Git configuration, hooks, commit template, and companion tools
#
# Manages:
#   - Git settings (user, editor, hooks path, commit template, comment char)
#   - Global hook scripts (~/.githooks/{pre-commit,commit-msg,post-commit,pre-push})
#   - Shared hook libraries (~/.githooks/lib/{gates,commit-msg,sync}.sh)
#   - Conventional commit template (~/.config/git/commit-template)
#   - Companion packages (difftastic, gh, gitleaks, glab)
#
# Hook architecture: Hybrid dispatch
#   Global hooks run universal gates (format, vet, gitleaks, conventional commit,
#   DCO, executive summary). If a repo has .githooks/<hook-name>, the global hook
#   dispatches to it for repo-specific gates.
#
# Gate inventory:
#   pre-commit (fast):  nix fmt, go fmt, go vet, gitleaks, theme lint (cmdr)
#   commit-msg:         conventional commit, DCO sign-off, ## Changes, ## Executive Summary
#   post-commit:        docs sync to cdc vault, commit-log entry, cdc auto-commit
#   pre-push (slow):    go build, go test, nix flake check
#
# Comment character: ; (semicolon)
#   Set via core.commentChar so that ## markdown headers in commit messages
#   are preserved by git's commit.cleanup = strip. Template instructions
#   use ; prefix and are stripped automatically.
#
# Deploy with: unimart deli switch
{ pkgs, config, hostMeta, ... }:

let
  hooksDir = "${config.home.homeDirectory}/.githooks";

  # ── Shared library: gates.sh ──────────────────────────────────────────
  # Sourced by hook scripts. Provides gate functions for pre-commit and
  # pre-push, plus helpers for repo detection and dispatch.
  gatesLib = ''
    #!/usr/bin/env bash
    # ~/.githooks/lib/gates.sh — Shared gate functions
    # Sourced by hook scripts. Do not execute directly.

    # ── Output helpers ───────────────────────────────────────────────────
    _RED='\033[0;31m'
    _GREEN='\033[0;32m'
    _YELLOW='\033[0;33m'
    _CYAN='\033[0;36m'
    _RESET='\033[0m'

    gate_pass() { printf "''${_GREEN}[pass]''${_RESET} %s\n" "$1"; }
    gate_fail() { printf "''${_RED}[fail]''${_RESET} %s\n" "$1"; }
    gate_warn() { printf "''${_YELLOW}[warn]''${_RESET} %s\n" "$1"; }
    gate_info() { printf "''${_CYAN}[info]''${_RESET} %s\n" "$1"; }

    # ── Repo detection ───────────────────────────────────────────────────
    repo_root() { git rev-parse --show-toplevel; }
    repo_name() { basename "$(repo_root)"; }
    is_go_repo()  { [[ -f "$(repo_root)/go.mod" ]]; }
    is_nix_repo() { [[ -f "$(repo_root)/flake.nix" ]]; }

    # Walk up from repo root to find the org dir (meta repo with .gitmodules)
    resolve_org_dir() {
      local dir
      dir="$(repo_root)"
      while [[ ! -f "''${dir}/.gitmodules" ]] && [[ "''${dir}" != "/" ]]; do
        dir="$(dirname "''${dir}")"
      done
      if [[ -f "''${dir}/.gitmodules" ]]; then
        printf '%s' "''${dir}"
      else
        return 1
      fi
    }

    # ── Pre-commit gates (fast) ──────────────────────────────────────────
    check_nix_fmt() {
      if ! is_nix_repo; then return 0; fi
      if ! command -v nix >/dev/null 2>&1; then
        gate_warn "nix not found, skipping nix fmt check"
        return 0
      fi
      local nix_files
      # Exclude Backstage scaffolder templates: their *.nix skeletons carry
      # scaffolder placeholders (dollar-brace pairs) that are invalid Nix by
      # design, so nixfmt cannot parse them. Rendered output is validated
      # downstream, not at commit time.
      nix_files=$(git diff --cached --name-only --diff-filter=ACMR -- '*.nix' \
        | grep -v 'scaffolder-templates/' || true)
      if [[ -z "''${nix_files}" ]]; then return 0; fi

      gate_info "checking nix fmt"
      if echo "''${nix_files}" | xargs nix fmt -- --check 2>/dev/null; then
        gate_pass "nix fmt"
        return 0
      else
        gate_fail "nix fmt — run: nix fmt"
        return 1
      fi
    }

    check_go_fmt() {
      if ! is_go_repo; then return 0; fi
      if ! command -v gofmt >/dev/null 2>&1; then
        gate_warn "gofmt not found, skipping go fmt check"
        return 0
      fi
      local go_files
      go_files=$(git diff --cached --name-only --diff-filter=ACMR -- '*.go' || true)
      if [[ -z "''${go_files}" ]]; then return 0; fi

      gate_info "checking go fmt"
      local unformatted
      unformatted=$(echo "''${go_files}" | xargs gofmt -l 2>/dev/null || true)
      if [[ -z "''${unformatted}" ]]; then
        gate_pass "go fmt"
        return 0
      else
        gate_fail "go fmt — unformatted files:"
        printf '  %s\n' ''${unformatted}
        return 1
      fi
    }

    check_go_vet() {
      if ! is_go_repo; then return 0; fi
      if ! command -v go >/dev/null 2>&1; then
        gate_warn "go not found, skipping go vet"
        return 0
      fi
      local go_files
      go_files=$(git diff --cached --name-only --diff-filter=ACMR -- '*.go' || true)
      if [[ -z "''${go_files}" ]]; then return 0; fi

      gate_info "running go vet"
      if go vet ./... 2>&1; then
        gate_pass "go vet"
        return 0
      else
        gate_fail "go vet"
        return 1
      fi
    }

    check_gitleaks() {
      if ! command -v gitleaks >/dev/null 2>&1; then
        gate_warn "gitleaks not found, skipping secret scan"
        return 0
      fi
      gate_info "scanning for secrets"
      if gitleaks git --staged --no-banner 2>/dev/null; then
        gate_pass "gitleaks"
        return 0
      else
        gate_fail "gitleaks — secrets detected in staged changes"
        return 1
      fi
    }

    # ── Pre-push gates (slow) ────────────────────────────────────────────
    check_go_build() {
      if ! is_go_repo; then return 0; fi
      if ! command -v go >/dev/null 2>&1; then
        gate_warn "go not found, skipping go build"
        return 0
      fi
      gate_info "running go build"
      if go build ./... 2>&1; then
        gate_pass "go build"
        return 0
      else
        gate_fail "go build"
        return 1
      fi
    }

    check_go_test() {
      if ! is_go_repo; then return 0; fi
      if ! command -v go >/dev/null 2>&1; then
        gate_warn "go not found, skipping go test"
        return 0
      fi
      gate_info "running go test"
      if go test ./... 2>&1; then
        gate_pass "go test"
        return 0
      else
        gate_fail "go test"
        return 1
      fi
    }

    check_nix_flake() {
      if ! is_nix_repo; then return 0; fi
      if ! command -v nix >/dev/null 2>&1; then
        gate_warn "nix not found, skipping nix flake check"
        return 0
      fi
      gate_info "running nix flake check"
      if nix flake check 2>&1; then
        gate_pass "nix flake check"
        return 0
      else
        gate_fail "nix flake check"
        return 1
      fi
    }

    # ── Dispatch ─────────────────────────────────────────────────────────
    # Run the repo-local .githooks/<hook> if it exists. Returns the hook's
    # exit code, or 0 if no repo-local hook is present.
    dispatch_repo_hook() {
      local hook_name="$1"
      shift
      local repo_hook
      repo_hook="$(repo_root)/.githooks/''${hook_name}"
      if [[ -x "''${repo_hook}" ]]; then
        gate_info "dispatching to repo-local .githooks/''${hook_name}"
        "''${repo_hook}" "$@"
        return $?
      fi
      return 0
    }
  '';

  # ── Shared library: commit-msg.sh ─────────────────────────────────────
  # Sourced by the commit-msg hook. Validates commit message structure.
  commitMsgLib = ''
    #!/usr/bin/env bash
    # ~/.githooks/lib/commit-msg.sh — Commit message validation
    # Sourced by the commit-msg hook. Do not execute directly.

    source "''${HOOKS_LIB_DIR}/gates.sh"

    # Conventional commit: type(scope): subject  OR  type: subject
    CONVENTIONAL_PATTERN='^(feat|fix|refactor|style|docs|test|chore|build|ci|perf|revert)(\([a-zA-Z0-9_./-]+\))?!?:[[:space:]].+'

    validate_conventional_commit() {
      local msg_file="$1"
      local first_line
      first_line=$(head -1 "''${msg_file}")

      # Skip merge commits
      if [[ "''${first_line}" =~ ^Merge\  ]]; then
        gate_info "merge commit — skipping conventional commit check"
        return 0
      fi

      if [[ "''${first_line}" =~ ''${CONVENTIONAL_PATTERN} ]]; then
        gate_pass "conventional commit format"
        return 0
      else
        gate_fail "conventional commit format"
        printf "  Expected: <type>(<scope>): <subject>\n"
        printf "  Got:      %s\n" "''${first_line}"
        printf "  Types: feat, fix, refactor, style, docs, test, chore, build, ci, perf, revert\n"
        return 1
      fi
    }

    validate_dco_signoff() {
      local msg_file="$1"
      if grep -q '^Signed-off-by:' "''${msg_file}"; then
        gate_pass "DCO sign-off"
        return 0
      else
        gate_fail "DCO sign-off — use: git commit -s"
        return 1
      fi
    }

    validate_changes_section() {
      local msg_file="$1"
      local first_line
      first_line=$(head -1 "''${msg_file}")

      # Skip merge commits
      if [[ "''${first_line}" =~ ^Merge\  ]]; then return 0; fi

      if grep -q '^## Changes' "''${msg_file}"; then
        # Check section has content (between ## Changes and next ## or Signed-off-by or EOF)
        local changes_content
        changes_content=$(sed -n '/^## Changes/,/^## \|^Signed-off-by:/p' "''${msg_file}" \
          | sed '1d;$d' \
          | grep -v '^[[:space:]]*$' \
          | grep -v '^;' \
          || true)
        if [[ -n "''${changes_content}" ]]; then
          gate_pass "## Changes section"
          return 0
        else
          gate_fail "## Changes section is empty"
          return 1
        fi
      else
        gate_fail "## Changes section missing"
        return 1
      fi
    }

    validate_executive_summary() {
      local msg_file="$1"
      local first_line
      first_line=$(head -1 "''${msg_file}")

      # Skip merge commits
      if [[ "''${first_line}" =~ ^Merge\  ]]; then return 0; fi

      if grep -q '^## Executive Summary' "''${msg_file}"; then
        local summary_content
        summary_content=$(sed -n '/^## Executive Summary/,/^## \|^Signed-off-by:/p' "''${msg_file}" \
          | sed '1d;$d' \
          | grep -v '^[[:space:]]*$' \
          | grep -v '^;' \
          || true)
        if [[ -n "''${summary_content}" ]]; then
          gate_pass "## Executive Summary section"
          return 0
        else
          gate_fail "## Executive Summary section is empty"
          return 1
        fi
      else
        gate_fail "## Executive Summary section missing"
        return 1
      fi
    }
  '';

  # ── Shared library: sync.sh ───────────────────────────────────────────
  # Sourced by the post-commit hook. Handles docs sync to the cdc vault,
  # commit-log entry creation, and cdc auto-commit.
  syncLib = ''
        #!/usr/bin/env bash
        # ~/.githooks/lib/sync.sh — Docs sync and executive summary extraction
        # Sourced by the post-commit hook. Do not execute directly.

        source "''${HOOKS_LIB_DIR}/gates.sh"

        # Check if the last commit touched docs/ files
        commit_has_docs_changes() {
          git diff-tree --no-commit-id --name-only -r HEAD -- 'docs/' 2>/dev/null | grep -q .
        }

        sync_meta_docs_to_cdc() {
          local org_dir="$1"
          local vault_root="$2"
          local dest="''${vault_root}/meta"
          local docs_src="''${org_dir}/docs"

          rm -rf "''${dest}"
          mkdir -p "''${dest}"

          if [[ -d "''${docs_src}" ]]; then
            rsync -a --delete --delete-excluded \
              --exclude='.git' \
              --exclude='.gitignore' \
              --exclude='Makefile' \
              --exclude='cmdr/' \
              --exclude='idpbuilder/' \
              --exclude='idpctl/' \
              --exclude='scripts/' \
              "''${docs_src}/" "''${dest}/"
          fi

          for file in README.md AGENTS.md TOOLING.md PROVISIONING.md CHANGELOG.md; do
            if [[ -f "''${org_dir}/''${file}" ]]; then
              rsync -a "''${org_dir}/''${file}" "''${dest}/"
            fi
          done
        }

        # Sync this repo's docs/ to the cdc vault
        sync_docs_to_cdc() {
          local org_dir name vault_root src dest
          org_dir="$(resolve_org_dir)" || {
            gate_warn "could not resolve org dir — skipping docs sync"
            return 0
          }

          name="$(repo_name)"
          vault_root="''${org_dir}/unimart-employee-handbooks/cdc"

          if [[ ! -d "''${vault_root}" ]]; then
            gate_warn "cdc vault not found at ''${vault_root} — skipping docs sync"
            return 0
          fi

          if [[ "''${name}" == "meta" ]]; then
            gate_info "syncing meta docs → cdc/meta/"
            sync_meta_docs_to_cdc "''${org_dir}" "''${vault_root}"
            dest="''${vault_root}/meta"
          else
            src="$(repo_root)/docs"
            if [[ ! -d "''${src}" ]]; then
              gate_info "no docs/ directory in ''${name} — skipping sync"
              return 0
            fi

            dest="''${vault_root}/''${name}"
            mkdir -p "''${dest}"

            gate_info "syncing ''${name}/docs/ → cdc/''${name}/"
            rsync -a --delete "''${src}/" "''${dest}/"
          fi

          # Inject frontmatter if the script exists
          local inject="''${vault_root}/scripts/inject-frontmatter.sh"
          if [[ -x "''${inject}" ]]; then
            bash "''${inject}" "''${dest}" "''${name}"
          fi

          gate_pass "docs synced to cdc vault"
        }

        # Extract ## Executive Summary text from HEAD commit message
        extract_executive_summary() {
          local msg
          msg="$(git log -1 --format='%B')"
          local summary
          summary=$(printf '%s\n' "''${msg}" \
            | sed -n '/^## Executive Summary/,/^## \|^Signed-off-by:/p' \
            | sed '1d;$d' \
            | sed '/^[[:space:]]*$/d')
          if [[ -n "''${summary}" ]]; then
            printf '%s' "''${summary}"
          fi
        }

        # Create a commit-log entry in the cdc vault for Obsidian Dataview
        create_commit_log_entry() {
          local org_dir name vault_root
          org_dir="$(resolve_org_dir)" || return 0
          name="$(repo_name)"
          vault_root="''${org_dir}/unimart-employee-handbooks/cdc"

          if [[ ! -d "''${vault_root}" ]]; then return 0; fi

          local summary
          summary="$(extract_executive_summary)"
          if [[ -z "''${summary}" ]]; then return 0; fi

          local commit_hash commit_date subject commit_type commit_scope
          commit_hash="$(git log -1 --format='%h')"
          commit_date="$(git log -1 --format='%cs')"
          subject="$(git log -1 --format='%s')"

          # Parse conventional commit type and scope from subject line
          commit_type="$(printf '%s' "''${subject}" | sed -n 's/^\([a-z]*\).*/\1/p')"
          commit_scope="$(printf '%s' "''${subject}" | sed -n 's/^[a-z]*(\([^)]*\)).*/\1/p')"

          local log_dir="''${vault_root}/commit-log"
          mkdir -p "''${log_dir}"

          local entry_file="''${log_dir}/''${commit_date}-''${name}-''${commit_hash}.md"

          cat > "''${entry_file}" << ENTRY
    ---
    repo: ''${name}
    date: ''${commit_date}
    commit: ''${commit_hash}
    type: ''${commit_type}
    scope: ''${commit_scope}
    tags: [commit-log]
    ---

    # ''${subject}

    ''${summary}
    ENTRY

          gate_pass "commit-log entry: ''${commit_date}-''${name}-''${commit_hash}.md"
        }

        # Auto-commit any pending changes in the cdc vault
        auto_commit_cdc() {
          local org_dir vault_root
          org_dir="$(resolve_org_dir)" || return 0
          vault_root="''${org_dir}/unimart-employee-handbooks/cdc"

          # .git may be a file (submodule) or directory (standalone clone)
          if [[ ! -e "''${vault_root}/.git" ]]; then return 0; fi

          # Clear git env vars inherited from the hook's parent process.
          # Without this, git -C targets the wrong repo (the one being committed,
          # not the cdc vault). GIT_DIR and GIT_INDEX_FILE are the main culprits.
          local _cdc_git="env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE git -C ''${vault_root}"

          # Check for any changes (staged, unstaged, or untracked)
          if ! ''${_cdc_git} diff --quiet 2>/dev/null || \
             ! ''${_cdc_git} diff --cached --quiet 2>/dev/null || \
             [[ -n "$(''${_cdc_git} ls-files --others --exclude-standard 2>/dev/null)" ]]; then

            local name commit_hash
            name="$(repo_name)"
            commit_hash="$(git log -1 --format='%h')"

            ''${_cdc_git} add -A
            ''${_cdc_git} commit \
              -m "docs(sync): auto-sync from ''${name}@''${commit_hash}" \
              -s --no-verify

            gate_pass "cdc vault auto-committed"
          fi
        }
  '';

  # ── Hook: pre-commit ──────────────────────────────────────────────────
  # Fast gates only. Runs on every commit in every repo.
  preCommitHook = ''
    #!/usr/bin/env bash
    set -euo pipefail

    HOOKS_LIB_DIR="''${HOME}/.githooks/lib"
    source "''${HOOKS_LIB_DIR}/gates.sh"

    echo "━━━ pre-commit gates ━━━"

    errors=0

    # Gate: nix fmt (staged .nix files only)
    check_nix_fmt   || errors=$((errors + 1))

    # Gate: go fmt (staged .go files only)
    check_go_fmt    || errors=$((errors + 1))

    # Gate: go vet
    check_go_vet    || errors=$((errors + 1))

    # Gate: gitleaks secret scan
    check_gitleaks  || errors=$((errors + 1))

    # Dispatch to repo-local .githooks/pre-commit
    dispatch_repo_hook "pre-commit" "$@" || errors=$((errors + 1))

    if [[ "''${errors}" -gt 0 ]]; then
      printf "\n''${_RED}[fail]''${_RESET} %d gate(s) failed — commit aborted\n" "''${errors}"
      exit 1
    fi

    printf "\n''${_GREEN}[pass]''${_RESET} all pre-commit gates passed\n"
  '';

  # ── Hook: commit-msg ──────────────────────────────────────────────────
  # Validates commit message structure: conventional format, DCO sign-off,
  # ## Changes section, ## Executive Summary section.
  commitMsgHook = ''
    #!/usr/bin/env bash
    set -euo pipefail

    HOOKS_LIB_DIR="''${HOME}/.githooks/lib"
    source "''${HOOKS_LIB_DIR}/commit-msg.sh"

    echo "━━━ commit-msg gates ━━━"

    msg_file="$1"
    errors=0

    # Strip ; comment lines (core.commentChar = ";") before validation.
    # Git hasn't applied commit.cleanup yet when this hook fires.
    tmpfile=$(mktemp)
    trap 'rm -f "''${tmpfile}"' EXIT
    grep -v '^;' "''${msg_file}" > "''${tmpfile}" || true

    # Gate: conventional commit format
    validate_conventional_commit "''${tmpfile}" || errors=$((errors + 1))

    # Gate: DCO sign-off
    validate_dco_signoff "''${tmpfile}" || errors=$((errors + 1))

    # Gate: ## Changes section present and non-empty
    validate_changes_section "''${tmpfile}" || errors=$((errors + 1))

    # Gate: ## Executive Summary section present and non-empty
    validate_executive_summary "''${tmpfile}" || errors=$((errors + 1))

    # Dispatch to repo-local .githooks/commit-msg
    dispatch_repo_hook "commit-msg" "$@" || errors=$((errors + 1))

    if [[ "''${errors}" -gt 0 ]]; then
      printf "\n''${_RED}[fail]''${_RESET} %d gate(s) failed — commit aborted\n" "''${errors}"
      exit 1
    fi

    printf "\n''${_GREEN}[pass]''${_RESET} all commit-msg gates passed\n"
  '';

  # ── Hook: post-commit ─────────────────────────────────────────────────
  # Self-reconciling docs pipeline. Syncs docs to cdc vault, creates
  # commit-log entries from executive summaries, auto-commits the vault.
  # Best-effort: no -e flag, commit already happened.
  postCommitHook = ''
    #!/usr/bin/env bash
    set -uo pipefail

    # Guard against re-entry: cdc auto-commits trigger post-commit again.
    # The child git process inherits this env var, so the recursive hook
    # sees it and exits immediately.
    if [[ "''${_HOOK_POST_COMMIT_RUNNING:-}" == "1" ]]; then
      exit 0
    fi
    export _HOOK_POST_COMMIT_RUNNING=1

    HOOKS_LIB_DIR="''${HOME}/.githooks/lib"
    source "''${HOOKS_LIB_DIR}/sync.sh"

    echo "━━━ post-commit sync ━━━"

    # Sync docs to cdc vault if docs/ files were in the commit
    if commit_has_docs_changes; then
      sync_docs_to_cdc || gate_warn "docs sync failed (non-fatal)"
    fi

    # Create commit-log entry (for all commits with executive summaries)
    create_commit_log_entry || gate_warn "commit-log entry failed (non-fatal)"

    # Auto-commit cdc vault if anything changed
    auto_commit_cdc || gate_warn "cdc auto-commit failed (non-fatal)"

    # Dispatch to repo-local .githooks/post-commit
    dispatch_repo_hook "post-commit" "$@" || true

    exit 0
  '';

  # ── Hook: pre-push ────────────────────────────────────────────────────
  # Slow gates. Runs before push to remote.
  prePushHook = ''
    #!/usr/bin/env bash
    set -euo pipefail

    HOOKS_LIB_DIR="''${HOME}/.githooks/lib"
    source "''${HOOKS_LIB_DIR}/gates.sh"

    echo "━━━ pre-push gates ━━━"

    errors=0

    # Gate: go build
    check_go_build  || errors=$((errors + 1))

    # Gate: go test
    check_go_test   || errors=$((errors + 1))

    # Gate: nix flake check (moved here from pre-commit — too slow for commits)
    check_nix_flake || errors=$((errors + 1))

    # Dispatch to repo-local .githooks/pre-push
    dispatch_repo_hook "pre-push" "$@" || errors=$((errors + 1))

    if [[ "''${errors}" -gt 0 ]]; then
      printf "\n''${_RED}[fail]''${_RESET} %d gate(s) failed — push aborted\n" "''${errors}"
      exit 1
    fi

    printf "\n''${_GREEN}[pass]''${_RESET} all pre-push gates passed\n"
  '';

  # ── Commit template ───────────────────────────────────────────────────
  # Uses ; for comments (matches core.commentChar). Section headers (##)
  # are preserved in the final commit message.
  commitTemplate = ''
    <type>(<scope>): <subject>

    ## Changes

    <describe what changed and why>

    ## Executive Summary

    <1-2 paragraphs for the docs ecosystem — changelogs, vault queries, AI agents>

    ; --- COMMIT END ---
    ; Type: feat, fix, refactor, style, docs, test, chore, build, ci, perf, revert
    ; Scope: component affected (e.g., hooks, stockroom, cmdr, idpbuilder)
    ; DCO: Always use git commit -s to add Signed-off-by
    ; All sections (## Changes, ## Executive Summary) are required
    ; Merge commits are exempt from section requirements
    ; Bypass with --no-verify for WIP commits
  '';

in
{
  home.packages = with pkgs; [
    difftastic # Structural diff tool (used by lazygit pager and gd alias)
    gh # GitHub CLI
    gitleaks # Secret scanning (pre-commit gate)
    glab # GitLab CLI
  ];

  programs.git = {
    enable = true;

    settings = {
      commit.template = "~/.config/git/commit-template";
      core = {
        commentChar = ";";
        editor = "nvim";
        hooksPath = hooksDir;
      };
      credential.helper = "store";
      init.defaultBranch = "main";
      pull.rebase = true;
      url."git@github.com:".insteadOf = "https://github.com/";
      user.email = hostMeta.gitEmail;
      user.name = hostMeta.gitName;
    };
  };

  # ── Global hook scripts ────────────────────────────────────────────────
  home.file.".githooks/pre-commit" = {
    text = preCommitHook;
    executable = true;
  };

  home.file.".githooks/commit-msg" = {
    text = commitMsgHook;
    executable = true;
  };

  home.file.".githooks/post-commit" = {
    text = postCommitHook;
    executable = true;
  };

  home.file.".githooks/pre-push" = {
    text = prePushHook;
    executable = true;
  };

  # ── Shared hook libraries ──────────────────────────────────────────────
  home.file.".githooks/lib/gates.sh" = {
    text = gatesLib;
    executable = true;
  };

  home.file.".githooks/lib/commit-msg.sh" = {
    text = commitMsgLib;
    executable = true;
  };

  home.file.".githooks/lib/sync.sh" = {
    text = syncLib;
    executable = true;
  };

  # ── Commit template ────────────────────────────────────────────────────
  xdg.configFile."git/commit-template".text = commitTemplate;
}

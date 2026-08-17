# CI Strategy

Local-first continuous integration. No remote CI services — all checks run on your machine.

## Overview

Validation happens at two levels:

1. **Pre-commit hook** — runs automatically on every `git commit`
2. **`make ci`** — full suite, run manually before pushing

Both are designed to gracefully degrade: if a tool is missing (e.g., outside the dev shell), that check is skipped rather than failing.

## Pre-commit Hook

Deployed globally via `unimart deli switch` (Nix-managed, installed to `~/.githooks/`). Runs these checks in order:

| Check | Tool | What it validates |
|-------|------|-------------------|
| Nix formatting | `nix fmt` | All `.nix` files are formatted (if `flake.nix` exists) |
| Go formatting | `go fmt` | All `.go` files are formatted (if `go.mod` exists) |
| Go vet | `go vet` | Static analysis of Go code (if `go.mod` exists) |
| Secret scanning | `gitleaks` | No secrets in staged changes |
| Theme lint | cmdr-specific | Theme consistency (if cmdr theme script exists) |

If any check fails, the commit is aborted. If a tool isn't available, that check is skipped with a warning.

### Deployment

Hooks are deployed automatically when applying the Nix configuration:

```bash
unimart deli switch
```

There is no `make hooks` target — hooks are Nix-managed and deployed globally to `~/.githooks/` via `core.hooksPath`. See meta's ADR-005 for the full gate architecture.

### Additional Hook Types

Beyond pre-commit, the hook system includes:

- **commit-msg** — Validates conventional commit format, DCO sign-off, `## Changes` and `## Executive Summary` sections
- **post-commit** — Syncs docs to cdc vault, creates commit-log entries, auto-commits the vault
- **pre-push** — Runs `go build`, `go test`, and `nix flake check`

### Bypassing

In rare cases where you need to commit despite a failing check:

```bash
git commit --no-verify -m "wip: work in progress"
```

## `make ci`

The full local CI suite. Run this before pushing to main:

```bash
make ci
```

Runs six checks in sequence:

| Step | Check | Notes |
|------|-------|-------|
| 1/6 | Secret scanning (`gitleaks detect`) | Full repo scan |
| 2/6 | Nix formatting (`nix fmt -- --check .`) | Run `make fmt` to fix |
| 3/6 | Theme lint (`scripts/check-theme-lint.sh`) | Direct palette imports / raw hex colors |
| 4/6 | Flake evaluation (`nix flake check`) | Also builds the `checks` output (below) |
| 5/6 | Environment health (`make doctor`) | 18-item host check |
| 6/6 | Host compatibility (`make compat`) | Cross-platform eval matrix |

Reports a pass/fail summary at the end.

## `make ci-full`

Adds the **automated container test** to `make ci` — build the Ubuntu test
container, provision a Home Manager host, verify the toolchain, teardown:

```bash
make ci-full          # ci + container test (default host: cmdr)
make ci-full HOST=x   # provision a different cli/tui host in the container
```

Linux only (requires a reachable Docker daemon). On macOS this target is
blocked with an explanatory error. The container test is intentionally **not**
part of `make ci` so the fast static gate stays fast; run `ci-full` before
pushing anything that touches Home Manager modules.

## What Each Check Does

### Secret Scanning

Uses [gitleaks](https://github.com/gitleaks/gitleaks) with the repo's `.gitleaks.toml` config. The config allowlists SOPS-encrypted content patterns (`ENC[AES256_GCM,...]`, age public keys) so encrypted secrets don't trigger false positives.

- **Pre-commit**: scans staged changes only (`gitleaks git --staged`)
- **`make ci`**: scans the full repo (`gitleaks detect`)

### Nix Formatting

Runs `nixpkgs-fmt` (the formatter defined in `flake.nix`) in check mode. If files are unformatted, fix with:

```bash
make fmt
```

### Flake Evaluation

Runs `nix flake check`, which evaluates all outputs defined in `flake.nix` and **builds the `checks` output** — a real test suite, not just evaluation:

- `checks.<system>.format` — `nixpkgs-fmt --check` over the source tree
- `checks.<system>.theme-lint` — runs `scripts/check-theme-lint.sh`
- `checks.<system>.eval-<host>` — one per host (linux, darwin, nixos); forces the full host config to evaluate, catching syntax errors, bad module options, and broken feature flags **across every host from any platform**

This catches:

- Syntax errors in any `.nix` file
- Missing imports or undefined variables
- Type errors in module options
- Broken package references
- Linux-only packages leaking into darwin hosts (e.g. `thunar`)
- Cross-platform eval regressions (darwin configs evaluated from Linux)

This replaces the former `nix-flake-check.yml` and `theme-lint.yml` GitHub Actions workflows. Note that `nix flake check` evaluates the current system's checks; darwin hosts are still *evaluated* (not built) from Linux, so platform mistakes surface immediately.

### Environment Health (`make doctor`)

Verifies that the current machine has all expected tools and configurations. Checks:

- Prerequisites: git, Homebrew (macOS), Nix, flakes enabled
- Repository: flake.nix, flake.lock, git submodules
- Shell: default shell is zsh, XDG config directory
- Managed tools: nvim, tmux, starship, direnv, rg, fd, bat, eza, zoxide, atuin
- Home Manager: available, generation count

## Migration History

This project previously used GitHub Actions for CI:

| Former workflow | Replacement |
|----------------|------------|
| `nix-flake-check.yml` (Linux + macOS matrix) | Pre-commit hook + `make ci` step 4 |
| `linux-container-test.yml` (5-job pipeline) | `make doctor` + `make test-run`/`test-tty` (Linux) |
| `theme-lint.yml` | `make ci` step 3 + `checks.<system>.theme-lint` |

The GitHub Actions workflows were removed to eliminate per-minute billing costs on a private repository. The macOS CI runner alone accounted for ~60% of the flake check cost due to GitHub's 10x billing multiplier for macOS minutes.

The container integration test pipeline (`build` -> `provision` -> `verify-*`) is preserved as local Make targets (`make test`, `make test-run`, `make test-tty`) for Linux machines, and gated behind `make ci-full`.

## Future: Gitea Actions

When the project matures to self-hosted Gitea, the `make ci` target is the natural entry point for a Gitea Actions workflow. A minimal workflow would be:

```yaml
# .gitea/workflows/ci.yml (future)
on: [push]
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: DeterminateSystems/nix-installer-action@main
      - run: make ci
```

---

**Last Updated:** 2026-03-23

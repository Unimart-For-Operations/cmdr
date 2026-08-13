---
name: upstream-mgmt
description: "idpbuilder's cherry-pick workflow for tracking cnoe-io/idpbuilder upstream changes without merge commits."
---

# Upstream Management

## Context

`idpbuilder` is tracked **in-tree** at `idpbuilder/` in the meta repo (a single absorb commit — its history here is flat, so meta shares no ancestry with cnoe-io/idpbuilder). It is a private independent copy of [cnoe-io/idpbuilder](https://github.com/cnoe-io/idpbuilder); the fork relationship was intentionally broken because GitHub requires forks of public repos to be public.

**Go module path stays `github.com/cnoe-io/idpbuilder`** — this is intentional, matching upstream to avoid rewriting all import paths.

## Remote Setup

Run from the **meta repo root**:

```
upstream → git@github.com:cnoe-io/idpbuilder.git       (public, read-only)
```

```
git remote add upstream git@github.com:cnoe-io/idpbuilder.git
make fetch-upstream
```

The 259 original fork commits and 16 tags are preserved in the private fork history; upstream refs and tags are fetched into meta on demand.

## Cherry-Pick Workflow

Changes from upstream are **cherry-picked, never merged**. Because histories are disconnected and upstream commits carry root-relative paths (no `idpbuilder/` prefix), cherry-picks are applied via `git format-patch | git apply --directory=idpbuilder/ --3way --index`, which maps every path under `idpbuilder/`.

### Makefile Targets (run from meta root)

```bash
make fetch-upstream                # git fetch upstream --tags
make upstream-status               # Divergence summary: our idpbuilder/ subtree vs upstream/main
make log-upstream                  # Recent upstream commits (no merge-base exists)
make log-upstream-detail           # Recent upstream commits with diffs
make diff-upstream                 # Tree diff: HEAD:idpbuilder ↔ upstream/main
make cherry-pick COMMIT=<sha>      # Apply a single upstream commit (guarded to upstream history)
make cherry-pick-range FROM=<sha> TO=<sha>  # Apply an upstream commit range
```

`cherry-pick` and `cherry-pick-range` refuse to apply commits that are not part of `upstream/main` history, and never auto-commit — they stage the mapped changes and print the stat for review.

### Typical Workflow

```bash
# 1. Fetch latest upstream
make fetch-upstream

# 2. Review what's new
make upstream-status              # How far is our subtree from upstream/main?
make log-upstream                 # Recent upstream work
make diff-upstream                # File-level divergence

# 3. Cherry-pick selectively (stages changes; then commit yourself)
make cherry-pick COMMIT=abc123
git commit -s -m "feat(idpbuilder): <summary of what was brought in>"

# 4. Or a range
make cherry-pick-range FROM=abc123 TO=def456
git commit -s -m "feat(idpbuilder): <summary>"
```

Commits must pass the meta commit-msg gates: conventional subject, DCO sign-off (`-s`), and `## Changes` / `## Executive Summary` sections.

## Rules

1. **Never `git merge upstream/main`** — always apply upstream commits selectively.
2. **Never change the Go module path** — it must stay `github.com/cnoe-io/idpbuilder`.
3. **Resolve conflicts manually** — applications may conflict where the fork diverged from upstream.
4. **Tag preservation** — upstream tags are fetched automatically with `--tags`.
5. **Document significant cherry-picks** — note what was brought in and why in the commit message.

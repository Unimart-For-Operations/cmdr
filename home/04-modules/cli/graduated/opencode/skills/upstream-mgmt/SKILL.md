---
name: upstream-mgmt
description: "idpbuilder's cherry-pick workflow for tracking cnoe-io/idpbuilder upstream changes without merge commits."
---

# Upstream Management

## Context

`idpbuilder` is a private independent copy of [cnoe-io/idpbuilder](https://github.com/cnoe-io/idpbuilder). The fork relationship was intentionally broken because GitHub requires forks of public repos to be public.

**Go module path stays `github.com/cnoe-io/idpbuilder`** — this is intentional, matching upstream to avoid rewriting all import paths.

## Remote Setup

```
origin   → git@github.com:Unimart-For-Operations/idpbuilder.git    (private)
upstream → git@github.com:cnoe-io/idpbuilder.git       (public, read-only)
```

All 259 original commits and 16 tags are preserved in the private repo.

## Cherry-Pick Workflow

Changes from upstream are **cherry-picked, never merged**. This keeps the commit history clean and allows selective adoption.

### Makefile Targets

```bash
make fetch-upstream                    # git fetch upstream --tags
make log-upstream                      # Show new commits: HEAD..upstream/main
make log-upstream-detail               # Show new commits with diffs
make diff-upstream                     # Show stat diff: HEAD...upstream/main
make cherry-pick COMMIT=<sha>          # Cherry-pick a single commit
make cherry-pick-range FROM=<sha> TO=<sha>  # Cherry-pick a range
make upstream-status                   # Ahead/behind counts + last fetch time
```

### Typical Workflow

```bash
# 1. Fetch latest upstream
make fetch-upstream

# 2. Review what's new
make log-upstream              # Quick overview
make diff-upstream             # File-level changes

# 3. Cherry-pick selectively
make cherry-pick COMMIT=abc123

# 4. Or cherry-pick a range
make cherry-pick-range FROM=abc123 TO=def456

# 5. Verify status
make upstream-status
```

## Rules

1. **Never `git merge upstream/main`** — always cherry-pick.
2. **Never change the Go module path** — it must stay `github.com/cnoe-io/idpbuilder`.
3. **Resolve conflicts manually** — cherry-picks may conflict with local changes.
4. **Tag preservation** — upstream tags are fetched automatically with `--tags`.
5. **Document significant cherry-picks** — note what was brought in and why in the commit message.

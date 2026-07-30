---
name: docs-sync
description: "Two-phase documentation sync pipeline: source repos → cdc handbook/vault with committed frontmatter."
---

# Documentation Sync Pipeline

## Architecture

```
Source repos (cmdr, idpbuilder, meta)
  → Phase 1: Pull to cdc vault (rsync --delete)
  → Phase 2: Inject frontmatter for Obsidian Dataview

cdc vault = committed Markdown employee handbook
Obsidian = optional UI over the same Markdown files
```

**Script:** `unimart-employee-handbooks/cdc/scripts/sync-docs.sh`
**Contract:** `.docs-manifest.yml` (meta repo root)
**Command:** `unimart newsstand sync`

## Source Of Truth

Each repo self-documents in its own `docs/` directory:

- `cmdr/docs/` → `cdc/cmdr/`
- `idpbuilder/docs/` → `cdc/idpbuilder/`
- `meta/docs/` plus root control-plane docs → `cdc/meta/`

The legacy `docs/` submodule remains during transition, but it is not the active handbook. Do not use it as the Obsidian target.

## Phase 1: Pull

The sync script uses `rsync --delete` so each cdc mirror exactly matches its source. For meta, the script avoids copying legacy mirrored repos from `meta/docs`; it syncs only meta-owned docs plus root files such as `README.md`, `AGENTS.md`, `TOOLING.md`, and `PROVISIONING.md`.

Never edit synced mirror directories directly:

- `cdc/cmdr/`
- `cdc/idpbuilder/`
- `cdc/meta/`

Edit the corresponding source repo docs instead.

## Phase 2: Frontmatter Injection

`scripts/inject-frontmatter.sh <target> <source-name>` adds or updates:

```yaml
---
source: cmdr
synced: 2026-04-06
---
```

Frontmatter is committed to the cdc repo. Source repos remain clean.

## Hook Integration

Hooks are Nix-managed by cmdr and deployed globally to `~/.githooks/` via `unimart deli switch`.

The global `post-commit` hook:

1. Checks whether the commit touched `docs/`.
2. Syncs that repo's docs to cdc.
3. Creates a `cdc/commit-log/` entry when the commit message has `## Executive Summary`.
4. Auto-commits cdc changes.

The global `pre-commit` hook runs fast local gates such as formatting, vetting, and secret scanning. It does not run the docs sync.

## Trigger Points

| Trigger | How |
|---------|-----|
| Manual from meta | `unimart newsstand sync` |
| Compatibility wrapper | `make sync-docs` |
| Automatic | Global post-commit hook on docs changes |

## Key Paths

```
meta/
├── .docs-manifest.yml
├── docs/                                Meta-owned docs plus legacy hub content
├── cmdr/docs/                           Source docs for cmdr
├── idpbuilder/docs/                     Source docs for idpbuilder
└── unimart-employee-handbooks/cdc/      Generated handbook / Obsidian vault
    ├── cmdr/                            Synced mirror
    ├── idpbuilder/                      Synced mirror
    ├── meta/                            Synced mirror
    ├── commit-log/                      Auto-generated commit summaries
    └── scripts/sync-docs.sh
```

## Rules

1. Edit source repo docs, not cdc mirrors.
2. Keep cdc Markdown terminal-readable; Obsidian is optional.
3. Frontmatter belongs in cdc mirrors, not source repos.
4. Update `.docs-manifest.yml` when source lists or mirror policy changes.
5. Treat the legacy `docs/` submodule as transitional.

# Documentation Organization

How documentation is organized across the idpbuilder org and synced with Obsidian.

## Architecture

Documentation lives in **source repos** (the single source of truth), is aggregated in an
**org-level docs repo**, and pushed to the **Obsidian vault** for reading, graph view, and
cross-device access via Obsidian Sync.

```
SOURCE REPOS (author here)            DOCS REPO (aggregation)       OBSIDIAN VAULT (read/navigate)
cmdr/docs/           ──┐
idpctl/README.md     ──┼─ Phase 1 ─→  idpbuilder/docs/   ─ Phase 2 ─→  ~/Documents/cmdr/Professional/
idpbuilder/docs/     ──┘               cmdr/                             organizations/idpbuilder/
                                       idpctl/                           cmdr/
                                       idpbuilder/                       idpctl/
                                                                         idpbuilder/
```

### Triggers

| Trigger | How |
|---------|-----|
| Manual | `make sync-docs` from any source repo (delegates to org-level docs repo) |
| Pre-commit hook | Automatically syncs when committing changes under `docs/` |
| Manual (org) | `make sync` from the docs repo directly |

### Key Properties

- **One-way by default**: repo → docs repo → Obsidian
- **Reverse sync available**: `make pull-docs` rsyncs from Obsidian back to the repo (for phone edits)
- **Frontmatter injection**: synced files receive `source` and `synced` metadata for Dataview queries
- **Idempotent**: safe to run multiple times

## Repo Structure (cmdr)

```
cmdr/
├── README.md              # Streamlined overview (GitHub landing page)
├── docs/                  # Canonical documentation (copied to Obsidian)
│   ├── README.md          # Full project documentation index
│   ├── Getting-Started/   # Setup and installation guides
│   ├── Architecture/      # Design and structure docs
│   ├── Reference/         # Look-up information
│   ├── Guides/            # How-to tutorials
│   ├── Modules/           # Module-specific documentation
│   └── Contributing/      # Development guidelines
├── Makefile               # sync-docs, pull-docs targets
└── scripts/
    └── inject-frontmatter.sh  # Post-sync frontmatter injection
```

## Sync Commands

```bash
# Push: repo → docs repo → Obsidian vault
make sync-docs

# Pull: Obsidian vault → repo (for phone/tablet edits)
make pull-docs
```

## Editing Workflow

### Edit in Repo (Recommended)

1. Edit files in `docs/`
2. Commit: `git add docs/ && git commit -m "docs: update..."`
3. The pre-commit hook auto-syncs to Obsidian (if docs repo is cloned)

### Edit in Obsidian (Quick Notes / Phone)

1. Edit in Obsidian on any device (phone, tablet, desktop)
2. Obsidian Sync propagates changes to the Mac
3. Pull changes back: `make pull-docs`
4. Review: `git diff docs/`
5. Commit from terminal

> The repo is the source of truth. Prefer editing there.
> Obsidian edits are for quick notes on the go — always pull and commit promptly.

## Obsidian Vault Layout

The vault (`~/Documents/cmdr`) is a symlink to the iCloud-synced directory.
Obsidian Sync handles cross-device propagation.

```
~/Documents/cmdr/
├── .obsidian/                          # Vault config (plugins, themes)
├── Professional/
│   └── organizations/
│       └── idpbuilder/
│           ├── cmdr/                   # ← synced from cmdr/docs/
│           ├── idpctl/                 # ← synced from idpctl/
│           └── idpbuilder/             # ← synced from idpbuilder/docs/
├── Academic/
├── Financial/
├── Personal/
├── daily/                              # obsidian.nvim daily notes
├── templates/                          # obsidian.nvim templates
└── assets/imgs/                        # Attachments
```

## Org-Level Docs Repo

The aggregation repo lives at `../docs/` (sibling of `cmdr/`):

```bash
# Clone if not present
gh repo clone idpbuilder/docs ../docs
```

Its `scripts/sync-docs.sh` runs the two-phase pipeline:
- **Phase 1 (Pull)**: rsync from each source repo into `docs/{cmdr,idpctl,idpbuilder}/`
- **Phase 2 (Push)**: rsync from docs repo into Obsidian vault
- **Phase 3 (Frontmatter)**: inject `source` and `synced` metadata into vault copies

## Terminal Obsidian Tooling

| Tool | Purpose | Install |
|------|---------|---------|
| **obsidian.nvim** | Neovim plugin: wiki-link completion, daily notes, backlinks, search | lazy.nvim (AstroNvim) |
| **markdown-oxide** | LSP server: wiki-link go-to-definition, references, tag completion | `pkgs.markdown-oxide` |
| **basalt** | TUI: browse and edit vault interactively in terminal | `pkgs.basalt` |
| **notesmd-cli** | CLI: create/search/rename notes, frontmatter CRUD, backlink updates | Custom Nix derivation |
| **obsidian-export** | CLI: export vault to standard CommonMark (for publishing) | `pkgs.obsidian-export` |

### notesmd-cli Examples

```bash
# Fuzzy search vault notes
notesmd-cli search --vault cmdr

# Create a note with content
notesmd-cli create "meeting-notes" --vault cmdr --content "$(cat notes.md)"

# Edit frontmatter
notesmd-cli frontmatter "docs/architecture.md" --vault cmdr --edit --key source --value cmdr

# Rename note (updates all backlinks across vault)
notesmd-cli move "old-name" "new-name" --vault cmdr
```

## Documentation Sections

### Repository Root
**README.md** - Streamlined overview for GitHub
- Quick start, managed hosts, command reference
- Links to full documentation in `docs/`

### docs/ Directory

| Section | Contents |
|---------|----------|
| **README.md** | Full documentation index |
| **Getting-Started/** | Bootstrap guide, quickstart reference |
| **Architecture/** | Layering, design principles |
| **Reference/** | Platform support, secrets, docs organization |
| **Guides/** | How-to tutorials |
| **Modules/** | Module docs: Hosts, Containers, TUI, Work |
| **Contributing/** | AI agent guidelines, development practices |

### Conventions

- Directories: `PascalCase` (e.g., `Getting-Started/`)
- Files: `lowercase.md` (e.g., `bootstrap.md`)
- Section index files: `README.md`
- Root README: concise GitHub landing page
- Full docs: everything lives in `docs/`

## Obsidian Tips

### Wiki Links
```markdown
See [[bootstrap]] for setup instructions.
For platform support, check [[platforms]].
```

### Tags
```markdown
#nix #setup #reference
```

### Graph View
Use Obsidian's graph view to visualize doc relationships across the vault.

### Dataview Queries
After frontmatter injection, synced files have `source` and `synced` fields.
Use Dataview to query imported docs:

````markdown
```dataview
TABLE source, synced
FROM "Professional/organizations/idpbuilder"
SORT synced DESC
```
````

## Troubleshooting

### Obsidian not showing docs
```bash
# Re-sync
make sync-docs

# Verify vault path
ls ~/Documents/cmdr/Professional/organizations/idpbuilder/cmdr/

# Check symlink
ls -la ~/Documents/cmdr
# Should point to: ~/Documents/Documents - Andrew's Mac Studio/cmdr
```

### Symlink missing
```bash
# Recreate the ~/Documents/cmdr symlink
ln -s ~/Documents/Documents\ -\ Andrew\'s\ Mac\ Studio/cmdr ~/Documents/cmdr
```

### Docs repo not cloned
```bash
# sync-docs and pull-docs require the org-level docs repo
gh repo clone idpbuilder/docs "$(dirname "$(pwd)")/docs"
```

---

**Last Updated:** 2026-03-23

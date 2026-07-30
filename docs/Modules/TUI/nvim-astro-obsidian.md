---
source: idpbuilder-org
synced: 2026-03-30
---
# Obsidian.nvim Integration for AstroNvim

## Overview

The obsidian.nvim plugin provides seamless integration between Neovim and Obsidian, allowing you to manage your notes, follow links, search content, and more directly from within AstroNvim.

**Vault Location**: `~/Documents/cmdr`

## Quick Start

1. **Install the plugin**: The plugin will auto-install when you next launch AstroNvim
2. **Open a note**: Navigate to `~/Documents/cmdr` and open any `.md` file
3. **Start using**: All Obsidian commands are available under `<Leader>o`

## Terminal Tooling Stack

| Tool | Role | Source |
|------|------|--------|
| **obsidian.nvim** | Neovim plugin — links, completion, daily notes | `user.lua` (lazy.nvim) |
| **markdown-oxide** | LSP — go-to-def, rename, hover, codelens | `lsp-tools.nix` → `astrolsp.lua` |
| **notesmd-cli** | CLI — create, search, frontmatter, daily | `core-utils/default.nix` (custom derivation) |
| **basalt** | TUI — browse/manage vaults interactively | `core-utils/default.nix` (nixpkgs) |

## Keybindings

All keybindings use the `<Leader>o` prefix (by default `<Leader>` is `<Space>`).

### Core Commands

| Keybinding | Command | Description |
|------------|---------|-------------|
| `<Leader>oo` | `:ObsidianOpen` | Open current note in Obsidian app |
| `<Leader>on` | `:ObsidianNew` | Create a new note (prompts for title) |
| `<Leader>oq` | `:ObsidianQuickSwitch` | Quick switch between notes (fuzzy finder) |
| `<Leader>of` | `:ObsidianSearch` | Search note contents with Telescope |
| `<Leader>ot` | `:ObsidianTags` | Search by tags |
| `<Leader>od` | `:ObsidianToday` | Open or create today's daily note |
| `<Leader>oy` | `:ObsidianYesterday` | Open yesterday's daily note |
| `gf` | Smart follow | Follow Obsidian link or normal file path |

### Organization & Links

| Keybinding | Command | Description |
|------------|---------|-------------|
| `<Leader>ob` | `:ObsidianBacklinks` | Show all notes linking to current note |
| `<Leader>ol` | `:ObsidianLinks` | Show all links in current note |
| `<Leader>or` | `:ObsidianRename` | Rename note and update all references |
| `<Leader>ow` | `:ObsidianWorkspace` | Switch between workspaces |

### Media & Assets

| Keybinding | Command | Description |
|------------|---------|-------------|
| `<Leader>op` | `:ObsidianPasteImg` | Paste image from clipboard |

## Features

### 1. Note Navigation
- **Follow Links**: Use `gf` on any Obsidian link to follow it
  - Works with `[[wiki-links]]`
  - Works with `[markdown](links.md)`
  - Falls back to standard `gf` for non-Obsidian files
- **Backlinks**: See what notes reference the current note
- **Quick Switch**: Fuzzy find any note in your vault

### 2. Note Creation
- **Smart IDs**: Notes are created with URL-safe IDs based on title
- **Templates**: Store templates in `~/Documents/cmdr/templates/`
- **Daily Notes**: Automatic daily notes in `~/Documents/cmdr/daily/`

### 3. Completion
- **Note Names**: Autocomplete note names when typing `[[`
- **Tags**: Autocomplete tags when typing `#`
- **Works with blink.cmp**: Integrates via blink.compat bridge (AstroNvim v5 uses blink.cmp, not nvim-cmp)

### 4. Enhanced UI
- **Checkboxes**: Fancy icons for task lists
  - `[ ]` → 󰄱 (todo)
  - `[x]` → ✓ (done)
  - `[>]` → ➜ (forwarded)
  - `[~]` → ~ (in progress)
- **Syntax Highlighting**: Special highlighting for:
  - Wiki links `[[note]]`
  - Tags `#tag`
  - External links
  - Block references

### 5. Images & Attachments
- **Paste Images**: Use `<Leader>op` to paste from clipboard
- **Auto-organization**: Images saved to `~/Documents/cmdr/assets/imgs/`

### 6. markdown-oxide LSP

The **markdown-oxide** language server provides Obsidian-aware intelligence for
markdown files — go-to-definition on `[[wiki-links]]`, file/heading/tag
completions, hover previews, rename across vault, and codelens for backlink
counts.  It replaces the generic `marksman` LSP.

- **Server name** (lspconfig): `markdown_oxide`
- **Binary**: `markdown-oxide` (provided by Nix via `lsp-tools.nix`)
- **Root markers**: `.obsidian`, `.moxide.toml`, `.git`
- **Capabilities**: requires `workspace.didChangeWatchedFiles.dynamicRegistration = true`
- **`:Daily` command**: registered via `on_attach` — creates/opens today's daily note through the LSP

Config: `~/.config/nvim-astro/lua/plugins/astrolsp.lua`

### 7. notesmd-cli (Terminal Companion)

**notesmd-cli** is a Go CLI for programmatic Obsidian vault management from the
terminal — creating notes, modifying frontmatter, searching content, listing
vaults, and opening notes.  Installed via a custom Nix derivation in
`core-utils/default.nix`.

Common commands:
```bash
notesmd-cli list-vaults                 # Show registered vaults
notesmd-cli print-default               # Show default vault
notesmd-cli list                        # List notes in default vault
notesmd-cli create "My Note"            # Create a new note
notesmd-cli daily                       # Create/open today's daily note
notesmd-cli search                      # Fuzzy search notes
notesmd-cli search-content "query"      # Search note contents
notesmd-cli frontmatter get note.md     # View frontmatter
notesmd-cli frontmatter set note.md key value  # Set frontmatter field
```

## Workflow Examples

### Creating a New Note
```
1. Press <Leader>on
2. Type note title (e.g., "Meeting Notes 2026-02-04")
3. Start writing
4. Link to other notes with [[note-name]]
```

### Daily Journaling
```
1. Press <Leader>od to open today's note
2. Write your entry
3. Use templates with :ObsidianTemplate
```

### Finding Information
```
1. Press <Leader>of to search all notes
2. Or <Leader>oq for quick note switching
3. Or <Leader>ot to search by tags
```

### Working with Links
```
1. Type [[ to trigger note completion
2. Start typing note name
3. Press <C-n>/<C-p> to navigate suggestions
4. Use gf to follow any link
```

## Configuration

Your Obsidian.nvim configuration is located in:
`~/.config/nvim-astro/lua/plugins/user.lua`

### Workspace Configuration
```lua
workspaces = {
  {
    name = "cmdr",
    path = "~/Documents/cmdr",
  },
}
```

### Daily Notes Settings
- **Folder**: `~/Documents/cmdr/daily/`
- **Format**: `YYYY-MM-DD.md` (e.g., `2026-02-04.md`)
- **Title**: Full date format (e.g., "February 4, 2026")

### Templates Settings
- **Folder**: `~/Documents/cmdr/templates/`
- **Variables**: `{{date}}`, `{{time}}`, `{{title}}`

## Tips & Tricks

### 1. Organize Your Vault
```
~/Documents/cmdr/
├── daily/           # Daily notes
├── templates/       # Note templates
├── assets/
│   └── imgs/       # Images and attachments
├── projects/        # Project notes
└── reference/       # Reference materials
```

### 2. Use Templates
Create a template file at `~/Documents/cmdr/templates/meeting.md`:
```markdown
# {{title}}

**Date**: {{date}}
**Time**: {{time}}

## Attendees
- 

## Agenda
- 

## Notes

## Action Items
- [ ] 
```

Then use `:ObsidianTemplate meeting` when creating meeting notes.

### 3. Leverage Tags
- Use tags like `#project/work`, `#meeting`, `#todo`
- Search tags with `<Leader>ot`
- Tags autocomplete when typing `#`

### 4. Link Everything
- Reference related notes with `[[note-name]]`
- Use `<Leader>ob` to see what references current note
- Use `<Leader>or` to safely rename notes (updates all references)

### 5. Combine with Telescope
- `<Leader>of` uses Telescope for powerful search
- Supports regex patterns
- Live preview of matches

## Commands Reference

### All Available Commands
```
:ObsidianOpen          - Open in Obsidian app
:ObsidianNew           - Create new note
:ObsidianQuickSwitch   - Quick note switcher
:ObsidianSearch        - Search notes
:ObsidianTags          - Search tags
:ObsidianToday         - Today's daily note
:ObsidianYesterday     - Yesterday's daily note
:ObsidianTomorrow      - Tomorrow's daily note
:ObsidianBacklinks     - Show backlinks
:ObsidianLinks         - Show links
:ObsidianFollowLink    - Follow link under cursor
:ObsidianTemplate      - Insert template
:ObsidianWorkspace     - Switch workspace
:ObsidianPasteImg      - Paste image from clipboard
:ObsidianRename        - Rename note and update refs
:ObsidianLinkNew       - Create link to new note
:ObsidianToggleCheckbox - Toggle checkbox state
```

## Troubleshooting

### Plugin Not Loading
1. Check that plugin is installed: `:Lazy`
2. Sync plugins: `:Lazy sync`
3. Restart Neovim

### Completion Not Working
1. Ensure you're in a markdown file in your vault
2. Check blink.cmp is loaded: `:Lazy` and look for `blink.cmp` and `blink.compat`
3. Type `[[` to trigger note completion

### Links Not Working
1. Ensure file path is correct: `:ObsidianWorkspace`
2. Check vault path in config
3. Use `gf` on the link

### Images Not Pasting
1. Ensure clipboard contains an image
2. Check assets folder exists: `~/Documents/cmdr/assets/imgs/`
3. Use `:ObsidianPasteImg` command

## Further Reading

- **Plugin Documentation**: https://github.com/epwalsh/obsidian.nvim
- **Obsidian Help**: https://help.obsidian.md/
- **AstroNvim Docs**: https://docs.astronvim.com/
- **markdown-oxide**: https://github.com/Feel-ix-343/markdown-oxide
- **notesmd-cli**: https://github.com/Yakitrak/notesmd-cli

## Next Steps

1. **Create folder structure**:
   ```bash
   cd ~/Documents/cmdr
   mkdir -p daily templates assets/imgs
   ```

2. **Create your first template**:
   ```bash
   nvim ~/Documents/cmdr/templates/default.md
   ```

3. **Start your daily note**:
   - Open AstroNvim
   - Press `<Leader>od`
   - Start writing!

4. **Explore existing notes**:
   - Press `<Leader>oq` for quick switcher
   - Press `<Leader>of` to search all notes

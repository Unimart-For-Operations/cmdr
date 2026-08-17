# AstroNvim Stabilization Phase (Neovim 0.12)

## Context

This phase stabilized the `nvim-astro` distribution after mixed plugin states
caused startup failures on Neovim `0.12.x`.

Primary symptoms:

- Startup error walls from Treesitter module/API mismatch.
- `nvim-treesitter-textobjects` trying to load
  `nvim-treesitter.configs` during startup.
- Markdown rendering and navigation regressions caused by plugin/version drift.

## What Changed

### 1) Completion and Markdown UX

- Scoped Obsidian completion to markdown buffers so global completion is not
  overridden.
- Added markdown-local readability options (`wrap`, `linebreak`, `spell`,
  conceal settings) via autocmd.
- Kept markdown formatting conservative (`prettier --prose-wrap preserve`).

### 2) Cross-Platform Behavior

- Switched Obsidian URL opener to platform-aware behavior:
  - macOS: `open`
  - Linux: `xdg-open`

### 3) Treesitter and Plugin Compatibility

- Pinned `nvim-treesitter` to a known Neovim `0.12` compatible commit and set
  the newer plugin entrypoint (`main = "nvim-treesitter"`) for the user
  override.
- Pinned `aerial.nvim` to a revision that avoids deprecated node APIs.
- Temporarily disabled `nvim-treesitter-textobjects` because its startup path
  (`require("nvim-treesitter.configs")`) conflicts with the newer Treesitter
  runtime shape.

### 4) Lockfile and Runtime State Hygiene

- Improved Home Manager lock seeding logic so
  `~/.local/share/nvim-astro/lazy-lock.json` is refreshed when the source lock
  changes.
- Updated inline comments to match the actual module paths and Nix-managed
  behavior.

## Operational Notes

When lock or plugin specs change, use this recovery sequence:

```bash
unimart deli switch
cp ~/repos/meta/cmdr/home/04-modules/tui/graduated/nvim/nvim-astro/lazy-lock.json \
  ~/.local/share/nvim-astro/lazy-lock.json
NVIM_APPNAME=nvim-astro nvim --headless "+Lazy! clean" "+Lazy! restore" +qa
```

## Current Status

- Crash loop from `nvim-treesitter.configs` preload failure is resolved.
- Markdown workflow is stable again with render + LSP + completion.
- One non-fatal deprecation warning may still appear for codelens refresh and
  can be addressed in a follow-up cleanup.

## Follow-up Work

1. Re-introduce textobjects using a compatible configuration path for the
   newer Treesitter branch.
2. Remove remaining codelens deprecation noise in all plugin callbacks.
3. Re-evaluate lockfile pin strategy to reduce branch/commit drift during
   `:Lazy update` cycles.

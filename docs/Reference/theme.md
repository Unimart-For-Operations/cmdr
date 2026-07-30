---
source: idpbuilder-org
synced: 2026-03-30
---
# Theme System

**Centralized, switchable theming for all terminal, TUI, and CLI tools.**

The theme system provides a single source of truth for visual styling across every tool cmdr manages. Changing one value in a host's `meta.nix` cascades a full palette swap to all consumers on rebuild.

---

## Architecture

```
meta.nix: { theme = "catppuccin-frappe"; }
  → hostMeta (specialArgs, plumbed by discovery engine)
    → switchboard: import _shared/theme "catppuccin-frappe"
      → loads palettes/catppuccin-frappe.nix
        → builds semantic layer from palette
          → modules consume theme.semantic.* (primary)
                              theme.palette.*  (tool-specific fallback)
                              theme.toolThemes.* (name-string tools)
```

### Files

```
home/04-modules/_shared/theme/
├── default.nix                    # Switchboard function: themeName → attrset
└── palettes/
    └── catppuccin-frappe.nix      # Full palette + meta + toolThemes + fonts
```

### Data Flow

1. Each host's `meta.nix` declares `theme = "catppuccin-frappe"`
2. The discovery engine passes this through as `hostMeta.theme` via `extraSpecialArgs`
3. Consumer modules call `import ../../../_shared/theme (hostMeta.theme or "catppuccin-frappe")`
4. The switchboard imports `palettes/${themeName}.nix` and builds the full theme attrset
5. Modules use `theme.semantic.*` for universal purposes, `theme.palette.*` for tool-specific UI

### Scope

The theme system governs everything **inside a terminal**:
- Terminal emulators (Ghostty, Kitty, Alacritty)
- TUI applications (nvim, tmux, k9s, lazygit, yazi)
- CLI tools (starship, opencode, bat, fzf)

It does **not** govern:
- Desktop shell theming (DMS handles this dynamically from wallpaper colors via matugen)
- Hyprland compositor appearance (DMS overrides via `~/.config/hypr/dms/*.conf`)

The two systems coexist without conflict. See the [platforms doc](../Reference/platforms.md) for host-level details.

---

## Theme Attrset Shape

The switchboard returns this structure:

```nix
{
  # ── Identity ──────────────────────────────────────────────────
  name = "catppuccin-frappe";         # Full theme name
  variant = "frappe";                 # Palette variant
  style = "dark";                     # "dark" or "light"

  # ── Raw Palette ───────────────────────────────────────────────
  # All hex values from the palette. Use semantic.* where possible;
  # fall back to palette.* only for tool-specific UI that has no
  # semantic mapping (e.g., k9s chart resource colors, breadcrumbs).
  palette = {
    rosewater = "#f2d5cf"; flamingo = "#eebebe"; pink = "#f4b8e4";
    mauve = "#ca9ee6"; red = "#e78284"; maroon = "#ea999c";
    peach = "#ef9f76"; yellow = "#e5c890"; green = "#a6d189";
    teal = "#81c8be"; sky = "#99d1db"; sapphire = "#85c1dc";
    blue = "#8caaee"; lavender = "#babbf1";
    text = "#c6d0f5"; subtext1 = "#b5bfe2"; subtext0 = "#a5adce";
    overlay2 = "#949cbb"; overlay1 = "#838ba7"; overlay0 = "#737994";
    surface2 = "#626880"; surface1 = "#51576d"; surface0 = "#414559";
    base = "#303446"; mantle = "#292c3c"; crust = "#232634";
  };

  # ── Semantic Layer ────────────────────────────────────────────
  # Stable interface for theme switching. Palette values change per
  # theme; semantic keys stay the same across all palettes.
  semantic = {

    # Core (~18 keys) — used by 3+ modules
    bg            = "#303446";   # Primary background
    bgPanel       = "#292c3c";   # Panel/sidebar background
    bgElement     = "#414559";   # Raised element background
    fg            = "#c6d0f5";   # Primary foreground text
    fgMuted       = "#838ba7";   # Muted/secondary text
    fgOnAccent    = "#303446";   # Text on accent-colored backgrounds
    accent        = "#ca9ee6";   # Primary accent
    accentSecond  = "#85c1dc";   # Secondary accent
    accentTertiary = "#f4b8e4";  # Decorative/highlight accent
    ok            = "#a6d189";   # Success state
    warn          = "#ef9f76";   # Warning state
    err           = "#e78284";   # Error state
    info          = "#8caaee";   # Informational state
    border        = "#51576d";   # Inactive border
    borderActive  = "#ca9ee6";   # Active/focused border
    selection     = "#f2d5cf";   # Selection/mark highlight
    cursor        = "#f2d5cf";   # Cursor color
    cursorText    = "#303446";   # Text under cursor
    link          = "#8caaee";   # URL/link color

    # Diff domain — code diff coloring
    diff = {
      added         = "#a6d189";   # Added text
      removed       = "#e78284";   # Removed text
      context       = "#838ba7";   # Context/unchanged text
      hunkHeader    = "#85c1dc";   # Hunk header
      addedBg       = "#414559";   # Added line background
      removedBg     = "#414559";   # Removed line background
      contextBg     = "#292c3c";   # Context line background
      lineNumber    = "#737994";   # Line number gutter
    };

    # Syntax domain — syntax highlighting
    syntax = {
      comment       = "#838ba7";   # Comments
      keyword       = "#ca9ee6";   # Keywords
      function      = "#8caaee";   # Function names
      variable      = "#c6d0f5";   # Variables
      string        = "#a6d189";   # String literals
      number        = "#ef9f76";   # Numeric literals
      type          = "#e5c890";   # Type names
      operator      = "#85c1dc";   # Operators
      punctuation   = "#949cbb";   # Punctuation
    };

    # Prompt domain — shell prompt segments
    prompt = {
      identity      = "#ca9ee6";   # User/OS segment
      path          = "#f4b8e4";   # Directory segment
      vcs           = "#ef9f76";   # Git/VCS segment
      toolchain     = "#85c1dc";   # Language/runtime segment
      container     = "#a6d189";   # Container context segment
      time          = "#8caaee";   # Time segment
    };

    # Terminal domain — terminal emulator config
    terminal = {
      ansi = {
        color0  = "#51576d";   # black   (surface1)
        color1  = "#e78284";   # red
        color2  = "#a6d189";   # green
        color3  = "#e5c890";   # yellow
        color4  = "#8caaee";   # blue
        color5  = "#ca9ee6";   # magenta (mauve)
        color6  = "#81c8be";   # cyan    (teal)
        color7  = "#b5bfe2";   # white   (subtext1)
        color8  = "#626880";   # bright black  (surface2)
        color9  = "#e78284";   # bright red
        color10 = "#a6d189";   # bright green
        color11 = "#e5c890";   # bright yellow
        color12 = "#8caaee";   # bright blue
        color13 = "#ca9ee6";   # bright magenta
        color14 = "#81c8be";   # bright cyan
        color15 = "#a5adce";   # bright white (subtext0)
      };
    };
  };

  # ── Fonts ─────────────────────────────────────────────────────
  fonts = {
    mono = { family = "FiraCode Nerd Font Mono"; size = 13; };
    sans = { family = "Inter"; size = 13; };
  };

  # ── Tool Theme Names ──────────────────────────────────────────
  # For tools that accept a built-in theme name string rather than
  # hex values. Each palette file defines these per-tool mappings.
  toolThemes = {
    bat             = "TwoDark";
    catppuccin      = "frappe";
    ghostty         = "Catppuccin Frappe";
    k9s             = "catppuccin-frappe";
    lazygit         = "catppuccin-frappe";
    lualine         = "catppuccin";
    nvimColorscheme = "catppuccin";
    opencode        = "catppuccin-frappe";
    starship        = "catppuccin-frappe";
  };
}
```

---

## Semantic Layer Design

The semantic layer has **three tiers**:

### Tier 1: Core Semantic (~18 keys)

Universal UI concepts used by 3+ modules. Every theme **must** define these.

| Key | Purpose | Catppuccin Frappe |
|-----|---------|-------------------|
| `bg` | Primary background | `base` |
| `bgPanel` | Panel/sidebar background | `mantle` |
| `bgElement` | Raised element background | `surface0` |
| `fg` | Primary foreground text | `text` |
| `fgMuted` | Muted/secondary text | `overlay1` |
| `fgOnAccent` | Text on accent-colored backgrounds | `base` |
| `accent` | Primary accent | `mauve` |
| `accentSecond` | Secondary accent | `sapphire` |
| `accentTertiary` | Decorative/highlight accent | `pink` |
| `ok` | Success state | `green` |
| `warn` | Warning state | `peach` |
| `err` | Error state | `red` |
| `info` | Informational state | `blue` |
| `border` | Inactive border | `surface1` |
| `borderActive` | Active/focused border | `mauve` |
| `selection` | Selection/mark highlight | `rosewater` |
| `cursor` | Cursor color | `rosewater` |
| `cursorText` | Text under cursor | `base` |
| `link` | URL/link color | `blue` |

### Tier 2: Domain Semantic

Stable interfaces for specific tool domains. Used by 1-2 modules today, but any new tool in the same domain would share the same keys.

| Domain | Keys | Consumers |
|--------|------|-----------|
| `diff.*` | added, removed, context, hunkHeader, addedBg, removedBg, contextBg, lineNumber | opencode |
| `syntax.*` | comment, keyword, function, variable, string, number, type, operator, punctuation | opencode |
| `prompt.*` | identity, path, vcs, toolchain, container, time | starship |
| `terminal.ansi` | color0–color15 | kitty, alacritty |

### Tier 3: Raw Palette

For tool-specific UI that doesn't generalize (k9s chart resource colors, dialog styling, breadcrumb colors). These values will still change per palette, but the **mapping** from palette color → UI element is tool-specific.

Modules should prefer semantic keys and only fall back to `theme.palette.*` when no semantic key applies.

---

## Consumer Module Pattern

### Standard pattern (most modules)

```nix
{ hostMeta, ... }:
let
  theme = import ../../../_shared/theme (hostMeta.theme or "catppuccin-frappe");
  s = theme.semantic;
  p = theme.palette;  # only for tool-specific UI
in
{
  programs.someApp.settings = {
    background = s.bg;           # semantic — switches with theme
    foreground = s.fg;
    accentColor = s.accent;
    chartCpu = p.mauve;          # palette — tool-specific, no semantic mapping
  };
}
```

### Name-string pattern (tools with built-in themes)

```nix
{ hostMeta, ... }:
let
  theme = import ../../../_shared/theme (hostMeta.theme or "catppuccin-frappe");
in
{
  programs.ghostty.settings.theme = theme.toolThemes.ghostty;
  programs.ghostty.settings.font-family = theme.fonts.mono.family;
  programs.ghostty.settings.font-size = theme.fonts.mono.size;
}
```

---

## Adding a New Theme

To add a new theme (e.g., Catppuccin Mocha), create a single palette file:

```
home/04-modules/_shared/theme/palettes/catppuccin-mocha.nix
```

The file must provide the same attrset shape as `catppuccin-frappe.nix`.

Then update the host's `meta.nix`:

```nix
{
  theme = "catppuccin-mocha";
}
```

Run `make switch`. All consumers update automatically.

---

## Module Theme Coverage

### Fully themed (semantic layer)

| Module | Tier | Semantic keys used | Palette fallback? |
|--------|------|-------------------|-------------------|
| opencode | cli/graduated | core + diff + syntax | Yes (markdown domain) |
| starship | cli/graduated | core + prompt | No |
| tmux | tui/graduated | core | Yes (date segment, pane borders) |
| k9s | tui/incubating | core | Yes (chart colors, dialogs, breadcrumbs) |
| ghostty | gui/graduated | toolThemes + fonts | No |
| kitty | gui/incubating | core + terminal.ansi + fonts | No |
| alacritty | gui/incubating | core + terminal.ansi + fonts | No |
| nvim | tui/graduated | toolThemes only | No |
| bat | cli/graduated | toolThemes only | No |
| lazygit | tui/graduated | toolThemes | No |
| fzf | cli/graduated | core | No |
| yazi | tui/graduated | core | Yes |

### Not themed (no visual config)

All remaining modules (core-utils, containerization, go, ssh, python, terraform, aws, azure, direnv, zoxide, zsh, sesh, dms, hyprland, wezterm) either have no visual configuration or are governed by external systems (DMS).

### Manual sync points

These files cannot import Nix and must be updated manually when switching themes:

| File | Hardcoded values | Notes |
|------|-----------------|-------|
| `nvim-astro/lua/user.lua` | `flavour = "frappe"`, Obsidian highlight hex values | Lua files; catppuccin.nvim reads the flavour string |
| `hyprland/hyprland.conf` | `rgba()` border colors, cursor theme name | Not Nix-managed (DMS needs write access) |

---

## Relationship to DMS

DMS (Dank Material Shell) provides **dynamic wallpaper-based theming** for the Wayland desktop shell on Linux hosts. It operates in a completely separate domain:

| Layer | Theming System | Switchable? |
|-------|---------------|-------------|
| Terminal + TUI + CLI | **cmdr theme system** (this doc) | Yes, per host via `meta.nix` |
| Desktop shell (bar, launcher, notifications, lock) | **DMS / matugen** (dynamic) | Yes, automatically from wallpaper |
| Hyprland compositor (borders, gaps) | **DMS** (dynamic, overrides static defaults) | Yes, via DMS settings |

The two systems coexist because they govern non-overlapping layers. The wallpaper serves as the shared context — a Catppuccin-style wallpaper produces harmonious DMS colors alongside the static terminal palette.

---

## See Also

- [Architecture](../Architecture/README.md) — Module composition and tier system
- [Platforms](platforms.md) — Host inventory and platform-specific details
- [Hosts](../Modules/Hosts/README.md) — `meta.nix` fields and host discovery
- [Tier Migration v1](../Roadmap/tier-migration-v1.md) — Historical context for the original theme system

---

## Exporting The Theme (programmatic consumption)

Sometimes other repositories and tools need the theme as structured data (JSON) so they can generate config files or embed assets. Two supported ways to obtain the theme are:

- Simple script (recommended for local development):

  From the org root, run:

  ```bash
  ./cmdr/scripts/theme-export.sh <theme-name> > theme.json
  # e.g. ./cmdr/scripts/theme-export.sh catppuccin-frappe > /tmp/theme.json
  ```

  This calls the callable switchboard and writes a JSON representation of the theme to stdout.

- Nix evaluation (advanced / hermetic):

  You can evaluate the switchboard directly with Nix if you prefer a hermetic path. Example (impure path shown for convenience):

  ```bash
  nix eval --impure --raw --expr 'builtins.toJSON ((import ./home/04-modules/_shared/theme/default.nix).call "catppuccin-frappe")' > theme.json
  ```

When you produce `theme.json` place it somewhere consumers can find it (common patterns):

- Repository-local: `idpctl/internal/theme/fixtures/theme-sample.json` (used for testing) or `idpctl/theme.json` for local runs.
- Org-level: `~/repos/github/idpbuilder/.workspace/theme.json` (developer convention).

Consumers (idpctl, idpbuilder) may either run the export script at build-time or accept a path/flag/env var to locate an existing `theme.json` file. See `idpctl/docs/Reference/theme.md` for example usage.

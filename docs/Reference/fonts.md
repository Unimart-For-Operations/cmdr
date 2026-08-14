---
source: idpbuilder-org
synced: 2026-03-30
---
# Fonts

**Single source of truth for terminal font metrics.**

The `_shared/fonts` module defines the font families and sizing used by the
terminal emulators (Ghostty, Kitty, Alacritty). It replaces the former
`_shared/theme` switchboard — Catppuccin theming was removed from the config so
tools use their stock themes. On DMS hosts, colors are owned dynamically by
DMS/matugen from the wallpaper.

## Files

```
home/04-modules/_shared/fonts/
└── default.nix                    # mono, monoKitty, sans font definitions
```

## Usage

```nix
{ pkgs, ... }:
let
  f = (import ../../../_shared/fonts).mono;
in
{
  xdg.configFile."ghostty/config".text = ''
    font-size = ${toString f.size}
    font-family = "${f.family}"
  '';
}
```

## Exposed attrs

| Attr | Purpose |
|------|---------|
| `mono.family` | FiraCode Nerd Font Mono |
| `mono.size` | 13 (GUI terminal default) |
| `mono.lineHeight` | 1.18 multiplier |
| `mono.cellHeightPercent` | 14 (Ghostty percent) |
| `mono.offset` | `{ x = 0; y = 1; }` (Alacritty pixel offset) |
| `monoKitty` | Mirror of `mono` for Kitty's fractional line-height handling |
| `sans` | Inter, size 13 |

## Relationship to DMS

DMS/matugen generates **colors** from the wallpaper on DMS hosts; it does not
manage fonts. Terminal font metrics therefore always come from `_shared/fonts`,
independent of the active colorscheme.

## See Also

- [Architecture](../Architecture/README.md) — Module composition and tier system
- [Platforms](platforms.md) — Host inventory and platform-specific details

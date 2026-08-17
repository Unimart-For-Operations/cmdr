# Shared font configuration — single import point for all font consumers
#
# Usage in a consumer module:
#     let f = import ../../../_shared/fonts;
#     in { font-family = f.mono.family; }
#
# Exposes:
#   f.mono.family         — "AtkynsonMono Nerd Font Mono"
#   f.mono.size           — 13 (GUI terminal default)
#   f.mono.lineHeight     — 1.18 multiplier
#   f.mono.cellHeightPercent — 14 (Ghostty uses a percent)
#   f.mono.offset         — { x = 0; y = 1; } (pixel offset for Alacritty)
#   f.monoKitty           — mirrors mono (Kitty uses a fractional line height)
#   f.sans                — Inter, size 13

{
  # Font stack
  mono = {
    family = "AtkynsonMono Nerd Font Mono";
    size = 13; # GUI terminal default
    # Line height multiplier (1.0 = default). Slightly increased to
    # reduce visual clipping and improve vertical rhythm across terminals.
    lineHeight = 1.18;
    # Percent cell height used by some terminals (Ghostty uses a percent)
    cellHeightPercent = 14;
    # Pixel offset applied to the cell height for terminals that accept
    # a pixel offset (Alacritty uses an integer y offset).
    offset = { x = 0; y = 1; };
  };

  monoKitty = {
    # Mirror the generic mono values to reduce layout drift between
    # Kitty and other terminals. Consumers may override selectively if
    # a platform requires a different metric.
    family = "AtkynsonMono Nerd Font Mono";
    size = 13;
    lineHeight = 1.18;
    cellHeightPercent = 14;
    offset = { x = 0; y = 1; };
  };

  sans = {
    family = "Inter";
    size = 13;
  };
}

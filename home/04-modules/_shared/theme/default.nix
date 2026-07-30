# Theme switchboard — single import point for all visual consumers
#
# Usage in a consumer module:
# - Backwards compatible: `let theme = import ../../../_shared/theme; in { ... }`
#   returns the default theme object (`catppuccin-frappe`) and exposes
#   a `call` attribute to select another theme.
# - Per-host selection (recommended):
#     let theme = (import ../../../_shared/theme).call (hostMeta.theme or "catppuccin-frappe");
#   Consumer modules that receive `hostMeta` should use the pattern above.
#
# This gives you:
#   theme.name            — "catppuccin-frappe"
#   theme.variant         — "frappe"
#   theme.style           — "dark"
#   theme.palette.*       — all hex colour values (rosewater, base, text, …)
#   theme.palette.ansi.*  — terminal 16-colour ANSI mapping
#   theme.semantic.*      — purpose-based aliases (bg, fg, accent, …)
#   theme.fonts.*         — font families and sizes
#   theme.toolThemes.*    — per-tool theme name strings
#   theme.icons.*         — icon/powerline preferences

let
  # Theme function: import a palette by name and return the unified theme
  themeFun = themeName:
    let
      palette = import ./palettes/${themeName}.nix;
      parts = builtins.split "-" themeName;
      variant = if (builtins.length parts) > 1 then builtins.elemAt parts 1 else themeName;
      isMocha = variant == "mocha";
    in
    {
      # Identity
      name = themeName;
      variant = variant;
      style = "dark";

      # Raw palette — every palette file should expose colours + ansi map
      inherit palette;

      # Semantic aliases — map purpose to palette colours
      semantic = {
        bg = palette.base;
        bgPanel = palette.mantle;
        bgElement = palette.surface0;
        fg = palette.text;
        fgMuted = palette.overlay1;
        fgOnAccent = palette.crust;
        accent = palette.mauve;
        accentSecond = palette.sapphire;
        link = palette.blue;
        ok = palette.green;
        warn = palette.peach;
        err = palette.red;
        info = palette.blue;
        border = palette.surface1;
        borderActive = palette.mauve;
        selection = palette.rosewater;
        cursor = palette.rosewater;
        cursorText = palette.base;
      };

      # Font stack
      fonts = {
        mono = {
          family = "FiraCode Nerd Font Mono";
          size = 13; # GUI terminal default
          # Line height multiplier (1.0 = default). Slightly increased to
          # reduce visual clipping and improve vertical rhythm across terminals.
          lineHeight = 1.18;
          # Percent cell height used by some terminals (Ghostty uses a percent)
          cellHeightPercent = 14;
          # Pixel offset applied to the cell height for terminals that accept
          # a pixel offset (Alacritty uses an integer y offset).
          # Reduce the Y offset to better align with Kitty's fractional line
          # height handling on macOS Retina displays.
          offset = { x = 0; y = 1; };
        };
        monoKitty = {
          # Mirror the generic mono values to reduce layout drift between
          # Kitty and other terminals. Consumers may override selectively if
          # a platform requires a different metric.
          family = "FiraCode Nerd Font Mono";
          size = 13;
          lineHeight = 1.18;
          cellHeightPercent = 14;
          offset = { x = 0; y = 1; };
        };
        sans = {
          family = "Inter";
          size = 13;
        };
      };

      # Per-tool theme name strings — for tools that accept a theme name
      # rather than raw hex values
      toolThemes = {
        bat = "TwoDark";
        catppuccin = if isMocha then "mocha" else "frappe"; # generic catppuccin flavour key
        ghostty = if isMocha then "Catppuccin Mocha" else "Catppuccin Frappe";
        k9s = if isMocha then "catppuccin-mocha" else "catppuccin-frappe";
        lazygit = if isMocha then "catppuccin-mocha" else "catppuccin-frappe";
        lualine = "catppuccin";
        nvimColorscheme = "catppuccin";
        opencode = if isMocha then "catppuccin-mocha" else "catppuccin-frappe";
        starship = if isMocha then "catppuccin-mocha" else "catppuccin-frappe";
      };

      # Icon / powerline preferences
      icons = {
        powerline = true;
        nerdFont = true;
        separatorLeft = "";
        separatorRight = "";
      };

      # Terminal mapping convenience
      terminal = {
        ansi = palette.ansi;
      };
    };

  # Export the default theme (backwards compatible) and expose the
  # function as the `call` attribute for consumers that want to pick
  # a different theme at import time.
  defaultTheme = themeFun "catppuccin-frappe";
in
defaultTheme // { call = themeFun; }

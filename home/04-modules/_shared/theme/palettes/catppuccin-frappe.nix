# Catppuccin Frappe palette
# Reference: https://github.com/catppuccin/catppuccin
#
# This is the single source of truth for all Catppuccin Frappe hex values
# used across the cmdr workstation. Every visual consumer module imports
# this palette via the theme switchboard (_shared/theme/default.nix).
{
  # Accent colours
  rosewater = "#f2d5cf";
  flamingo = "#eebebe";
  pink = "#f4b8e4";
  mauve = "#ca9ee6";
  red = "#e78284";
  maroon = "#ea999c";
  peach = "#ef9f76";
  yellow = "#e5c890";
  green = "#a6d189";
  teal = "#81c8be";
  sky = "#99d1db";
  sapphire = "#85c1dc";
  blue = "#8caaee";
  lavender = "#babbf1";

  # Base tones
  text = "#c6d0f5";
  subtext1 = "#b5bfe2";
  subtext0 = "#a5adce";
  overlay2 = "#949cbb";
  overlay1 = "#838ba7";
  overlay0 = "#737994";
  surface2 = "#626880";
  surface1 = "#51576d";
  surface0 = "#414559";
  base = "#303446";
  mantle = "#292c3c";
  crust = "#232634";

  # Terminal 16-color mapping (ANSI indices)
  # Used by kitty, alacritty, and other terminal emulators
  ansi = {
    color0 = "#51576d"; # black   (surface1)
    color1 = "#e78284"; # red
    color2 = "#a6d189"; # green
    color3 = "#e5c890"; # yellow
    color4 = "#8caaee"; # blue
    color5 = "#ca9ee6"; # magenta (mauve)
    color6 = "#81c8be"; # cyan    (teal)
    color7 = "#b5bfe2"; # white   (subtext1)
    color8 = "#626880"; # bright black  (surface2)
    color9 = "#e78284"; # bright red
    color10 = "#a6d189"; # bright green
    color11 = "#e5c890"; # bright yellow
    color12 = "#8caaee"; # bright blue
    color13 = "#ca9ee6"; # bright magenta
    color14 = "#81c8be"; # bright cyan
    color15 = "#a5adce"; # bright white (subtext0)
  };
}

#!/usr/bin/env bash
set -uo pipefail

# greetd start script — themed TUI login on strix-nix.
#
# The greeter colors are expressed as ANSI palette *slots* (color0..color15):
# on DMS hosts the console palette that those slots resolve to is inherited
# from the active wallpaper theme (Mutagen) by the greetd-theme.service, which
# runs setvtrgb against ~/.config/greetd/dank-vtrgb at boot. Before that file
# exists the slots fall back to the static Catppuccin palette of this host.
# @tuigreet@ and @uwsm@ are substituted by system.nix at build time.

# ── Greeter theme (ANSI slots) ─────────────────────────────────────────
GREET_CONTAINER="color0"   # background of the centered containers
GREET_BORDER="color5"      # container borders (mauve/primary slot)
GREET_TITLE="color5"       # container titles (falls back to border)
GREET_TEXT="color7"        # base text (light slot)
GREET_GREET="color5"       # greeting / banner (accent slot)
GREET_PROMPT="color6"      # "Username:" / "Password:" labels (cyan slot)
GREET_INPUT="color7"       # typed input
GREET_TIME="color6"        # date and time (cyan slot)
GREET_ACTION="color4"      # bottom action hints (blue slot)
GREET_BUTTON="color3"      # action keybindings (yellow slot)

THEME="container=${GREET_CONTAINER};border=${GREET_BORDER};title=${GREET_TITLE};text=${GREET_TEXT};greet=${GREET_GREET};prompt=${GREET_PROMPT};input=${GREET_INPUT};time=${GREET_TIME};action=${GREET_ACTION};button=${GREET_BUTTON}"

# ── ASCII art greeting ─────────────────────────────────────────────────
# Map a ratatui color name to the matching VT SGR foreground code so the
# banner renders through the console palette that the theme service applied.
sgr_of() {
  case "$1" in
    black) echo 30 ;;
    red) echo 31 ;;
    green) echo 32 ;;
    yellow) echo 33 ;;
    blue) echo 34 ;;
    magenta) echo 35 ;;
    cyan) echo 36 ;;
    gray | white) echo 37 ;;
    darkgray) echo 90 ;;
    lightred) echo 91 ;;
    lightgreen) echo 92 ;;
    lightyellow) echo 93 ;;
    lightblue) echo 94 ;;
    lightmagenta) echo 95 ;;
    lightcyan) echo 96 ;;
    *) echo 37 ;;
  esac
}

BANNER="$(cat /etc/greetd/banner.txt)"
GREETING="$(printf '\033[%sm%s\033[0m' "$(sgr_of "$GREET_GREET")" "$BANNER")"
GREETING+="$(printf '\n\n\033[%sm%s\033[0m' "$(sgr_of "$GREET_TEXT")" "you have been summoned — sign in to continue")"

exec @tuigreet@/bin/tuigreet \
  --time \
  --remember \
  --remember-user-session \
  --asterisks \
  --theme "$THEME" \
  --greeting "$GREETING" \
  --cmd '@uwsm@/bin/uwsm start hyprland.desktop'

# Kitty terminal emulator configuration
# Theme: Catppuccin Frappe (sourced from _shared/theme)
# Keybindings: cmd+ on macOS, ctrl+ on Linux
{ pkgs, lib, hostMeta ? { }, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  mod = if isDarwin then "cmd" else "ctrl";
  theme = (import ../../../_shared/theme).call (if builtins.hasAttr "theme" hostMeta then hostMeta.theme else "catppuccin-frappe");
  p = theme.palette;
  a = p.ansi;
  f = theme.fonts.monoKitty;
in
{
  programs.kitty = {
    enable = true;
    shellIntegration.enableZshIntegration = true;

    font = {
      name = f.family;
      size = f.size;
    };

    keybindings = {
      "${mod}+t" = "new_tab";
      "${mod}+w" = "close_window";
      "${mod}+k" = "clear_terminal scroll active";
      "${mod}+1" = "goto_tab 1";
      "${mod}+2" = "goto_tab 2";
      "${mod}+3" = "goto_tab 3";
      "${mod}+4" = "goto_tab 4";
      "${mod}+5" = "goto_tab 5";
      "${mod}+6" = "goto_tab 6";
      "${mod}+7" = "goto_tab 7";
      "${mod}+8" = "goto_tab 8";
      "${mod}+9" = "goto_tab 9";
    };

    settings = {
      # ── Catppuccin Frappe palette (from shared theme) ──────────────────────
      foreground = p.text;
      background = p.base;
      selection_foreground = p.base;
      selection_background = p.rosewater;

      color0 = a.color0;
      color8 = a.color8;
      color1 = a.color1;
      color9 = a.color9;
      color2 = a.color2;
      color10 = a.color10;
      color3 = a.color3;
      color11 = a.color11;
      color4 = a.color4;
      color12 = a.color12;
      color5 = a.color5;
      color13 = a.color13;
      color6 = a.color6;
      color14 = a.color14;
      color7 = a.color7;
      color15 = a.color15;
      url_color = p.blue;

      # ── Cursor ────────────────────────────────────────────────────────────
      cursor_shape = "beam";
      cursor_beam_thickness = "1.5";
      cursor_blink_interval = "0.4";
      cursor_stop_blinking_after = "0";

      # ── Window ────────────────────────────────────────────────────────────
      window_padding_width = "8";
      placement_strategy = "center";
      hide_window_decorations = "titlebar-only";
      remember_window_size = "no";
      initial_window_width = "100c";
      initial_window_height = "30c";
      # Kitty supports a per-font line height via `line_height` in its
      # config; set it from the shared theme to reduce vertical drift.
      # The theme value is already a float; stringify it for the config.
      line_height = toString theme.fonts.mono.lineHeight;

      # ── Copy / clipboard ──────────────────────────────────────────────────
      copy_on_select = "clipboard";
      clipboard_control = "write-clipboard write-primary read-clipboard read-primary";

      # ── Mouse ─────────────────────────────────────────────────────────────
      mouse_hide_wait = "3.0";

      # ── Bell ──────────────────────────────────────────────────────────────
      enable_audio_bell = "no";

      # ── Misc ──────────────────────────────────────────────────────────────
      confirm_os_window_close = "0";

      # ── Shell ─────────────────────────────────────────────────────────────
      shell = if isDarwin then "/bin/zsh -l" else "${pkgs.zsh}/bin/zsh";

      # ── Tabs ──────────────────────────────────────────────────────────────
      tab_bar_edge = "top";
      tab_bar_style = "powerline";
      tab_title_template = "{index}: {title}";

      # ── macOS-specific ────────────────────────────────────────────────────
      macos_option_as_alt = "yes";
      macos_titlebar_color = "background";
    };
  };
}

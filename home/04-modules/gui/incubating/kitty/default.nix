# Kitty terminal emulator configuration
# Fonts sourced from _shared/fonts. Colors are owned by DMS's matugen on DMS
# hosts (dank-theme.conf); elsewhere kitty uses its stock colors.
# Keybindings: cmd+ on macOS, ctrl+ on Linux
{ config, pkgs, lib, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  # On hosts running the DMS desktop shell, colors are owned by DMS (matugen)
  # so themes applied in DMS propagate to the terminal. The dank-material-shell
  # module is only imported on DMS hosts, so its `enable` flag is the signal.
  isDms = (config.programs.dank-material-shell or { }).enable or false;
  mod = if isDarwin then "cmd" else "ctrl";
  f = (import ../../../_shared/fonts).monoKitty;
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

    # DMS hosts: source colors from DMS's matugen output.
    extraConfig = lib.mkIf isDms "include ${config.home.homeDirectory}/.config/kitty/dank-theme.conf";

    settings = {
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
      # config; set it from the shared fonts to reduce vertical drift.
      line_height = toString f.lineHeight;

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

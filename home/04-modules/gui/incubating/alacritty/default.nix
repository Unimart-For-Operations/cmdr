# Alacritty terminal emulator configuration
# Parity target: Ghostty config
# Fonts sourced from _shared/fonts. Colors are owned by DMS's matugen on DMS
# hosts (dank-theme.toml); elsewhere alacritty uses its stock colors.
{ pkgs, lib, config, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  # On hosts running the DMS desktop shell, colors are owned by DMS (matugen)
  # so themes applied in DMS propagate to the terminal. The dank-material-shell
  # module is only imported on DMS hosts, so its `enable` flag is the signal.
  isDms = (config.programs.dank-material-shell or { }).enable or false;
  f = (import ../../../_shared/fonts).mono;
in
{
  programs.alacritty = {
    enable = true;

    settings = {
      # DMS hosts: pull colors from DMS's matugen output.
      import = lib.mkIf isDms [ "${config.home.homeDirectory}/.config/alacritty/dank-theme.toml" ];

      # ── Shell ──────────────────────────────────────────────────────────────
      terminal.shell = if isDarwin then "/bin/zsh" else "${pkgs.zsh}/bin/zsh";

      # ── Font ───────────────────────────────────────────────────────────────
      font = {
        normal = {
          family = f.family;
          style = "Regular";
        };
        bold = {
          family = f.family;
          style = "Bold";
        };
        italic = {
          family = f.family;
          style = "Italic";
        };
        # Use the shared fonts mono font size. Add 0.0 to ensure a float
        # value (Alacritty expects a float for size).
        size = f.size + 0.0;

        # Cell height and offset are derived from the shared fonts so
        # different terminals align more closely. Use the font values
        # converted into the shape Alacritty expects.
        offset = {
          x = f.offset.x;
          y = f.offset.y;
        };
        # If the fonts module provides a lineHeight, scale the cell height by it.
        # Alacritty doesn't accept a fractional lineHeight directly, so we
        # emulate it with the y-offset and cell padding when necessary.
        builtin_box_drawing = true;
      };

      # ── Cursor ─────────────────────────────────────────────────────────────
      cursor = {
        style = {
          shape = "Block";
          blinking = "Always";
        };
        blink_interval = 500;
        blink_timeout = 0; # never stop blinking
      };

      # ── Window ─────────────────────────────────────────────────────────────
      window = {
        padding = {
          x = 12;
          y = 12;
        };
        decorations = "full";
        startup_mode = "Maximized";
        dynamic_title = true;
        opacity = 1.0;
        option_as_alt = "Both";
      };

      # ── Scrolling ──────────────────────────────────────────────────────────
      scrolling = {
        history = 10000;
        multiplier = 3;
      };

      # ── Mouse ──────────────────────────────────────────────────────────────
      mouse = {
        hide_when_typing = true;
      };

      # ── Selection ──────────────────────────────────────────────────────────
      selection = {
        save_to_clipboard = true;
      };

      # ── Keyboard bindings ──────────────────────────────────────────────────
      keyboard.bindings = [
        # Clear screen  (Cmd+K)
        { key = "K"; mods = "Command"; action = "ClearHistory"; }
        # New tab (Cmd+T)
        { key = "T"; mods = "Command"; action = "CreateNewTab"; }
        # Close pane / tab (Cmd+W)
        { key = "W"; mods = "Command"; action = "Quit"; }
        # Tab switching (Cmd+1-9)
        { key = "Key1"; mods = "Command"; action = "SelectTab1"; }
        { key = "Key2"; mods = "Command"; action = "SelectTab2"; }
        { key = "Key3"; mods = "Command"; action = "SelectTab3"; }
        { key = "Key4"; mods = "Command"; action = "SelectTab4"; }
        { key = "Key5"; mods = "Command"; action = "SelectTab5"; }
        { key = "Key6"; mods = "Command"; action = "SelectTab6"; }
        { key = "Key7"; mods = "Command"; action = "SelectTab7"; }
        { key = "Key8"; mods = "Command"; action = "SelectTab8"; }
        { key = "Key9"; mods = "Command"; action = "SelectTab9"; }
        # macOS: Option as Alt (word movement)
        { key = "Left"; mods = "Alt"; chars = "\\u001bb"; }
        { key = "Right"; mods = "Alt"; chars = "\\u001bf"; }
      ];

      # ── Environment variables ───────────────────────────────────────────────
      env = {
        TERM = "xterm-256color";
      };
    };
  };
}

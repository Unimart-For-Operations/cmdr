# Alacritty terminal emulator configuration
# Parity target: Ghostty config
# Theme: Catppuccin Frappe (sourced from _shared/theme) on non-DMS hosts.
# On DMS hosts colors come from DMS's matugen-generated dank-theme.toml.
{ pkgs, lib, config, hostMeta ? { }, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  # On hosts running the DMS desktop shell, colors are owned by DMS (matugen)
  # so themes applied in DMS propagate to the terminal. The dank-material-shell
  # module is only imported on DMS hosts, so its `enable` flag is the signal.
  isDms = (config.programs.dank-material-shell or { }).enable or false;
  theme = (import ../../../_shared/theme).call (if builtins.hasAttr "theme" hostMeta then hostMeta.theme else "catppuccin-frappe");
  p = theme.palette;
  a = p.ansi;
  f = theme.fonts.mono;
  catppuccinColors = {
    # ── Appearance ─────────────────────────────────────────────────────────
    # Catppuccin Frappe palette (from shared theme)
    colors = {
      primary = {
        background = p.base;
        foreground = p.text;
      };
      cursor = {
        text = p.base;
        cursor = p.rosewater;
      };
      selection = {
        text = p.base;
        background = p.rosewater;
      };
      normal = {
        black = a.color0;
        red = a.color1;
        green = a.color2;
        yellow = a.color3;
        blue = a.color4;
        magenta = a.color5;
        cyan = a.color6;
        white = a.color7;
      };
      bright = {
        black = a.color8;
        red = a.color9;
        green = a.color10;
        yellow = a.color11;
        blue = a.color12;
        magenta = a.color13;
        cyan = a.color14;
        white = a.color15;
      };
      footer_bar = {
        background = p.mantle;
        foreground = p.text;
      };
      hints = {
        start = {
          background = p.yellow;
          foreground = p.base;
        };
        end = {
          background = p.surface2;
          foreground = p.base;
        };
      };
    };
  };
in
{
  programs.alacritty = {
    enable = true;

    settings = {
      # DMS hosts: pull colors from DMS's matugen output. Imports are applied
      # on top of this config, so they override the shared-theme colors.
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
        # Use the shared theme mono font size. Add 0.0 to ensure a float
        # value (Alacritty expects a float for size).
        size = f.size + 0.0;

        # Cell height and offset are derived from the shared theme so
        # different terminals align more closely. Use the theme values
        # converted into the shape Alacritty expects.
        offset = {
          x = f.offset.x;
          y = f.offset.y;
        };
        # If the theme provides a lineHeight, scale the cell height by it.
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
    }
    # Shared-theme Catppuccin colors only where DMS isn't owning terminal colors
    // (if isDms then { } else catppuccinColors);
  };
}

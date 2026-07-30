# Ghostty terminal emulator configuration
# No Home Manager module; deployed via xdg.configFile.
# Theme: Catppuccin Frappe (sourced from _shared/theme)
# Package installation:
#   - Linux:  Installed via Nix (this module)
#   - macOS:  Installed via Homebrew cask (see .Brewfile)
{ pkgs, lib, config, hostMeta ? { }, ... }:

let
  theme = (import ../../../_shared/theme).call (if builtins.hasAttr "theme" hostMeta then hostMeta.theme else "catppuccin-frappe");
  f = theme.fonts.mono;
in
{
  # Install Ghostty on Linux; macOS uses Homebrew cask
  home.packages = lib.optionals pkgs.stdenv.isLinux [ pkgs.ghostty ];

  xdg.configFile."ghostty/config".text = ''
    # ~/.config/ghostty/config

    auto-update-channel = tip

    # Font settings — use mono family and size from shared theme for metric parity
    font-size = ${toString f.size}
    font-family = "${f.family}"

    # FiraCode stylistic sets and character variants
    font-feature = ss01
    font-feature = ss02
    font-feature = ss03
    font-feature = ss05
    font-feature = cv02
    font-feature = cv05
    font-feature = cv09
    font-feature = cv14
    font-feature = cv16
    font-feature = cv18
    font-feature = cv25
    font-feature = cv26
    font-feature = cv32

    # Slightly bolder text for better readability
    font-thicken = true

    # Line spacing for better vertical rhythm and readability (from theme)
    adjust-cell-height = ${toString theme.fonts.mono.cellHeightPercent}%

    # Appearance
    theme = "${theme.toolThemes.ghostty}"

    # Window padding
    window-padding-x = 12
    window-padding-y = 12
    window-theme = ghostty
    window-colorspace = srgb
    maximize = true
    macos-icon = xray

    # Cursor
    cursor-style = block
    cursor-style-blink = true
    cursor-opacity = 1.0

    # Copy behavior (single declaration — was duplicated before)
    copy-on-select = clipboard
    clipboard-read = allow
    clipboard-write = allow

    # Mouse
    mouse-hide-while-typing = true

    # Shell integration
    shell-integration = detect
    shell-integration-features = cursor,sudo,title

    # macOS appearance
    macos-option-as-alt = true
    window-decoration = true
    macos-titlebar-style = hidden
    command = ${if pkgs.stdenv.isDarwin then "/bin/zsh -l" else "${pkgs.zsh}/bin/zsh"}

    # Keybindings
    keybind = cmd+shift+r=reload_config
    keybind = cmd+k=clear_screen
    keybind = cmd+t=new_tab
    keybind = cmd+w=close_surface
    keybind = cmd+1=goto_tab:1
    keybind = cmd+2=goto_tab:2
    keybind = cmd+3=goto_tab:3
    keybind = cmd+4=goto_tab:4
    keybind = cmd+5=goto_tab:5
    keybind = cmd+6=goto_tab:6
    keybind = cmd+7=goto_tab:7
    keybind = cmd+8=goto_tab:8
    keybind = cmd+9=goto_tab:9
  '';
}

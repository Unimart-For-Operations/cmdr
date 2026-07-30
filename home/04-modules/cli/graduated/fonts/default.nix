{ pkgs, ... }:

{
  # Install fonts into the user profile.
  # On non-NixOS systems fonts.packages is unavailable, so all fonts must
  # live in home.packages and fontconfig must be enabled explicitly so
  # Home Manager registers them with the font cache.
  #
  # These fonts live in cli/ because they're data files useful even in
  # TTY-only (no display server) environments — SSH sessions, terminal
  # emulators on remote desktops, etc. Note: raw Linux VT consoles can't
  # render these fonts; console fonts are a kernel-level concern managed
  # via /etc/vconsole.conf, outside Home Manager's scope.
  home.packages = with pkgs; [
    # --- Nerd Fonts ---
    nerd-fonts.fira-code # Primary terminal font (current default)
    nerd-fonts.atkynson-mono # AtkynsonMono Nerd Font Mono
    nerd-fonts.jetbrains-mono # General-purpose coding font
    nerd-fonts.symbols-only # Icon/symbol glyphs without a base font

    # --- General UI / system fonts ---
    inter # Modern sans-serif UI font
    liberation_ttf # Metric-compatible Microsoft font replacements
    noto-fonts # Broad Unicode coverage
    noto-fonts-color-emoji # Colour emoji support
  ];

  # Tell Home Manager to manage fontconfig so the fonts above are picked up
  # without requiring a system-level fc-cache run.
  fonts.fontconfig.enable = true;
}

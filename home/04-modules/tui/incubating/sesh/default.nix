# Sesh — tmux session manager
# No Home Manager module; deployed via xdg.configFile.
{ pkgs, ... }:

{
  home.packages = [ pkgs.sesh ];

  xdg.configFile."sesh/sesh.toml".text = ''
    # Sesh Configuration
    # https://github.com/joshmedeski/sesh

    [default_session]
    startup_dir = "~"
    startup_command = "nvim-astro"
    preview_command = "eza --all --git --icons --color=always {}"

    [[session_paths]]
    path = "~/Documents"
    depth = 2
    hidden = false

    [[session_paths]]
    path = "~/projects"
    depth = 2
    hidden = false

    [[session_paths]]
    path = "~/work"
    depth = 2
    hidden = false

    [[session_paths]]
    path = "~/.config"
    depth = 1
    hidden = false

    [[session_paths]]
    path = "~/.dotfiles"
    depth = 1
    hidden = false

    # ── Named sessions ─────────────────────────────────────────────
    # Quick-access sessions that appear in sesh list -c

    [[session]]
    name = "dotfiles"
    path = "~/Documents/dev-control-plane"
    startup_command = "nvim-astro"

    # ── Wildcard configs ───────────────────────────────────────────
    # Auto-apply startup commands to matching directories.
    # Uses nvim-astro (AstroNvim wrapper) as the default editor.

    [[wildcard]]
    pattern = "~/Documents/*"
    startup_command = "nvim-astro"

    [[wildcard]]
    pattern = "~/projects/*"
    startup_command = "nvim-astro"

    [[wildcard]]
    pattern = "~/work/*"
    startup_command = "nvim-astro"

    # ── Tmux settings ─────────────────────────────────────────────

    [tmux]
    window_name_format = "#I:#W"

    [zoxide]
    enabled = true
    weight = 10
  '';
}

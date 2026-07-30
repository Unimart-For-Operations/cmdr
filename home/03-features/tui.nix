# home/03-features/tui.nix — Terminal UI Feature
#
# Full-screen terminal applications: editors, multiplexers, file managers,
# git TUI, Kubernetes dashboard. Requires a terminal emulator but no
# display server — works over SSH and in TTY-only environments.
#
# Includes graduated + incubating modules. Sandbox modules are opt-in
# per host via the `sandbox` field in meta.nix.
#
# Replaces: terminal.nix (TUI portion), cloud.nix (k9s)
#
#   features = [ "tui" ];
{ ... }:

{
  imports = [
    # ── Graduated ────────────────────────────────────────────────────────
    ../04-modules/tui/graduated/tmux
    ../04-modules/tui/graduated/nvim
    ../04-modules/tui/graduated/lazygit
    ../04-modules/tui/graduated/yazi

    # ── Incubating ───────────────────────────────────────────────────────
    ../04-modules/tui/incubating/sesh
    ../04-modules/tui/incubating/k9s
  ];
}

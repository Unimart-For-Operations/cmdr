# home/03-features/gaming.nix — Gaming Feature
#
# Gaming applications and tools for Linux systems with GPU support.
# Includes Steam, Lutris, Wine, and gaming utilities.
# Requires a GUI environment and GPU drivers (NVIDIA/AMD).
#
# Only enable on hosts with gaming capability.
#
#   features = [ "gaming" ];
{ pkgs, ... }:

{
  imports = [
    # ── Graduated ────────────────────────────────────────────────────────
    ../04-modules/gui/graduated/gaming
  ];
}

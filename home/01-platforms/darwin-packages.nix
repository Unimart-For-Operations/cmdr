{ pkgs, ... }:

# macOS-specific packages installed via Nix.
# Note: GUI applications are typically installed via Homebrew (see .Brewfile).
# This file is for CLI tools or utilities that either:
#   1. Don't exist in nixpkgs for Linux, or
#   2. Need macOS-specific configuration
{
  home.packages = with pkgs; [
    # autoraise temporarily removed — nixpkgs 26.11 (cctools 1010.6 / clang)
    # linker crashes when building AutoRaise.mm. Reinstate once upstream
    # is fixed, or install via Homebrew tap dimentium/autoraise.
    # autoraise
  ];
}

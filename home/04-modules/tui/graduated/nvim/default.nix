# Neovim Configuration
# Deploys AstroNvim to ~/.config/nvim-astro/ and nixvim as a standalone executable.
#
# Architecture:
#   ~/.local/bin/nvim        -> execs nvim-astro (the active distro)
#   ~/.local/bin/nvim-astro  -> sets NVIM_APPNAME + LAZY, execs the real neovim binary
#   nixvim                   -> standalone Nix-built neovim (separate binary)
#
# ~/.local/bin is on PATH before the Nix profile, so the wrappers shadow the
# plain neovim binary from Nix. To switch distros, change what nvim points to.
# No shell aliases needed — wrappers work in scripts, tmux, cron, everywhere.
{ inputs, pkgs, hostMeta ? { }, ... }:

let
  # Build nixvim configuration
  # This creates a standalone nvim executable with all plugins and config baked in
  nixvimConfig = inputs.nixvim.legacyPackages.${pkgs.stdenv.hostPlatform.system}.makeNixvimWithModule {
    inherit pkgs;
    module = import ./nixvim-config.nix { inherit hostMeta; };
  };

  # Wrap the nixvim binary under the name 'nixvim' so it doesn't conflict with
  # plain neovim on PATH (both would otherwise install as ~/.nix-profile/bin/nvim)
  nixvimWrapped = pkgs.symlinkJoin {
    name = "nixvim";
    paths = [ nixvimConfig ];
    postBuild = ''
      mv $out/bin/nvim $out/bin/nixvim
    '';
  };

  # Pre-fetch lazy.nvim at the commit pinned in lazy-lock.json so nvim-astro never
  # needs a network clone at runtime (eliminates failures in air-gapped / CI envs
  # where SSH git clones are blocked by the global url.insteadOf rewrite rule).
  # To update: bump the commit + hash to match the new lazy-lock.json entry.
  lazyNvim = pkgs.fetchFromGitHub {
    owner = "folke";
    repo = "lazy.nvim";
    rev = "85c7ff3711b730b4030d03144f6db6375044ae82";
    hash = "sha256-h5404njTAfqMJFQ3MAr2PWSbV81eS4aIs0cxAXkT0EM=";
  };

  # Resolve the real neovim binary path so wrappers never recurse back to
  # themselves (they live in ~/.local/bin which shadows the Nix nvim).
  realNvim = "${pkgs.neovim}/bin/nvim";
  gitBin = "${pkgs.git}/bin/git";
in
{
  imports = [
    ./lsp-tools.nix # Global LSP tools, formatters, linters
  ];

  # Install plain neovim (used by the wrapper scripts via absolute path) and
  # nixvim under its own 'nixvim' binary name.
  home.packages = [ pkgs.neovim nixvimWrapped ];

  # Deploy AstroNvim config to ~/.config/nvim-astro/
  # Home Manager symlinks each file to the Nix store (read-only).
  # To update: edit files in this directory, then rebuild.
  xdg.configFile."nvim-astro" = {
    source = ./nvim-astro;
    recursive = true;
    force = true;
  };

  # Seed lazy-lock.json as a mutable copy into ~/.local/share/nvim-astro/.
  # lazy_setup.lua redirects Lazy.nvim's lockfile there so :Lazy update can write
  # to it — ~/.config/nvim-astro/ files are read-only Nix store symlinks.
  # We use an activation script (not home.file) because home.file creates an
  # immutable Nix store symlink, which causes "Permission denied" on :Lazy update.
  # The copy is only seeded if the file doesn't already exist, so :Lazy update
  # changes are preserved across rebuilds.
  # After running :Lazy update, copy it back to the repo:
  #   cp ~/.local/share/nvim-astro/lazy-lock.json \
  #      home/04-modules/tui/graduated/nvim/nvim-astro/lazy-lock.json
  home.activation.seedLazyLock = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    lockdir="$HOME/.local/share/nvim-astro"
    lockfile="$lockdir/lazy-lock.json"
    marker="$lockdir/.lazy-lock-source"
    src="${./nvim-astro/lazy-lock.json}"
    mkdir -p "$lockdir"
    if [ ! -f "$lockfile" ] || [ -L "$lockfile" ] || [ ! -f "$marker" ] || [ "$(cat "$marker")" != "$src" ]; then
      # Remove stale symlink from previous home.file approach, then copy
      rm -f "$lockfile"
      cp "$src" "$lockfile"
      chmod u+w "$lockfile"
      echo "$src" > "$marker"
    fi
  '';

  # Pre-populate lazy.nvim into the XDG data dir so nvim-astro never clones it.
  # The LAZY env var in the wrapper points here, bypassing the bootstrap clone.
  # We use an activation script instead of home.file{recursive=true} because the
  # recursive approach creates per-file symlinks, then lazy.nvim writes real files
  # (e.g. .git/FETCH_HEAD) alongside them, causing noisy "Existing file is in the
  # way" warnings on every subsequent Home Manager activation.
  # This script copies once and only re-copies when the pinned version changes.
  home.activation.seedLazyNvim = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    lazydir="$HOME/.local/share/nvim-astro/lazy/lazy.nvim"
    marker="$lazydir/.nix-source"
    src="${lazyNvim}"
    if [ ! -d "$lazydir" ] || [ ! -f "$marker" ] || [ "$(cat "$marker")" != "$src" ]; then
      rm -rf "$lazydir"
      mkdir -p "$(dirname "$lazydir")"
      cp -a "$src" "$lazydir"
      chmod -R u+w "$lazydir"
      # Nix fetchFromGitHub strips .git — init a bare repo so lazy.nvim's
      # lock.lua can call Git.info() without hitting an assert failure.
      "${gitBin}" -C "$lazydir" init -q -b main
      "${gitBin}" -C "$lazydir" add -A
      "${gitBin}" -C "$lazydir" -c core.hooksPath= commit -q --no-verify -m "nix-seed"
      echo "$src" > "$marker"
    fi
  '';

  # Distro-specific wrapper: sets NVIM_APPNAME and LAZY, then execs the real
  # neovim binary (absolute path to avoid recursing through ~/.local/bin/nvim).
  home.file.".local/bin/nvim-astro" = {
    text = ''
      #!/usr/bin/env bash
      exec env NVIM_APPNAME=nvim-astro \
               LAZY="$HOME/.local/share/nvim-astro/lazy/lazy.nvim" \
               ${realNvim} "$@"
    '';
    executable = true;
  };

  # Default editor: delegates to the active distro wrapper.
  # To switch distros, change "nvim-astro" below to another wrapper name.
  # This shadows the plain Nix neovim binary because ~/.local/bin is earlier
  # on PATH (set in platform files: darwin.nix / linux.nix sessionPath).
  home.file.".local/bin/nvim" = {
    text = ''
      #!/usr/bin/env bash
      exec "$(dirname "$0")/nvim-astro" "$@"
    '';
    executable = true;
  };
}

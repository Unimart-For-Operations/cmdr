# DMS Matugen User Templates — propagate DMS theme colors to apps without a
# built-in DMS matugen template (tmux, opencode, nvim-astro).
#
# DMS merges user matugen plugin configs from `~/.config/matugen/dms/configs/`
# into every matugen run (unconditionally, regardless of app detection), so
# these files regenerate on every wallpaper/theme change.
#
# Each configs/*.toml references a deployed template by absolute path — DMS
# appends these sections verbatim (no CONFIG_DIR/placeholders), so the home
# directory and template dir are substituted here at build time.
#
# On non-DMS hosts this module is never imported (it lives under the dms module
# dir), so nothing is deployed and apps keep their Catppuccin themes.
{ config, ... }:

let
  home = config.home.homeDirectory;
  matugenDir = "${home}/.config/matugen";
  templates = "${matugenDir}/templates";

  # Build the deployed plugin config from its source template, substituting the
  # build-time paths (the source files use @HOME@ / @MATUGEN_TEMPLATES@).
  deployConfig = name: builtins.replaceStrings [
    "@HOME@"
    "@MATUGEN_TEMPLATES@"
  ] [
    home
    templates
  ]
    (builtins.readFile ./configs/${name}.toml);
in
{
  # Template sources (matugen {{...}} placeholders)
  xdg.configFile."matugen/templates/tmux.conf" = {
    force = true;
    source = ./templates/tmux.conf;
  };
  xdg.configFile."matugen/templates/opencode.json" = {
    force = true;
    source = ./templates/opencode.json;
  };
  xdg.configFile."matugen/templates/nvim-colors.lua" = {
    force = true;
    source = ./templates/nvim-colors.lua;
  };
  xdg.configFile."matugen/templates/starship.toml" = {
    force = true;
    source = ./templates/starship.toml;
  };

  # Plugin configs telling matugen where to write each generated theme.
  xdg.configFile."matugen/dms/configs/tmux.toml" = {
    force = true;
    text = deployConfig "tmux";
  };
  xdg.configFile."matugen/dms/configs/opencode.toml" = {
    force = true;
    text = deployConfig "opencode";
  };
  xdg.configFile."matugen/dms/configs/nvim.toml" = {
    force = true;
    text = deployConfig "nvim";
  };
  xdg.configFile."matugen/dms/configs/starship.toml" = {
    force = true;
    text = deployConfig "starship";
  };
}

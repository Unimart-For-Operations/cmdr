# OpenCode — AI coding agent configuration
# Deploys global config, custom theme, TUI settings, global AGENTS.md,
# and skills via ~/.config/opencode/
# Theme: Catppuccin Frappe (sourced from _shared/theme)
{ config, pkgs, hostMeta ? { }, ... }:

let
  theme = (import ../../../_shared/theme).call (if builtins.hasAttr "theme" hostMeta then hostMeta.theme else "catppuccin-frappe");
  p = theme.palette;
  skillsDir = ./skills;
in
{
  # Install OpenCode CLI
  home.packages = with pkgs; [
    opencode
  ];

  # OpenCode global config
  xdg.configFile."opencode/opencode.json".force = true;
  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    theme = theme.toolThemes.opencode;
    instructions = [ "docs/Contributing/AGENTS.md" ];
  };

  # Global AGENTS.md — personal preferences, always loaded regardless of CWD
  xdg.configFile."opencode/AGENTS.md" = {
    force = true;
    source = ./global-agents.md;
  };

  # Skills — on-demand reference material loaded by the agent when relevant
  xdg.configFile."opencode/skills/nix-modules/SKILL.md" = {
    force = true;
    source = "${skillsDir}/nix-modules/SKILL.md";
  };
  xdg.configFile."opencode/skills/docs-sync/SKILL.md" = {
    force = true;
    source = "${skillsDir}/docs-sync/SKILL.md";
  };
  xdg.configFile."opencode/skills/upstream-mgmt/SKILL.md" = {
    force = true;
    source = "${skillsDir}/upstream-mgmt/SKILL.md";
  };
  xdg.configFile."opencode/skills/makefile-convention/SKILL.md" = {
    force = true;
    source = "${skillsDir}/makefile-convention/SKILL.md";
  };

  # TUI config: select the theme
  xdg.configFile."opencode/tui.json".force = true;
  xdg.configFile."opencode/tui.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/tui.json";
    theme = theme.toolThemes.opencode;
  };

  # Catppuccin Frappe theme for OpenCode
  # Generated from shared palette — do not edit hex values here.
  xdg.configFile."opencode/themes/${theme.toolThemes.opencode}.json" = {
    force = true;
    text = builtins.toJSON {
      "$schema" = "https://opencode.ai/theme.json";

      defs = {
        # Catppuccin Frappe palette
        rosewater = p.rosewater;
        flamingo = p.flamingo;
        pink = p.pink;
        mauve = p.mauve;
        red = p.red;
        maroon = p.maroon;
        peach = p.peach;
        yellow = p.yellow;
        green = p.green;
        teal = p.teal;
        sky = p.sky;
        sapphire = p.sapphire;
        blue = p.blue;
        lavender = p.lavender;

        # Base tones
        text = p.text;
        subtext1 = p.subtext1;
        subtext0 = p.subtext0;
        overlay2 = p.overlay2;
        overlay1 = p.overlay1;
        overlay0 = p.overlay0;
        surface2 = p.surface2;
        surface1 = p.surface1;
        surface0 = p.surface0;
        base = p.base;
        mantle = p.mantle;
        crust = p.crust;
      };

      theme = {
        primary = "mauve";
        secondary = "green";
        accent = "sapphire";
        error = "red";
        warning = "peach";
        success = "green";
        info = "blue";

        text = "text";
        textMuted = "overlay1";

        background = "base";
        backgroundPanel = "mantle";
        backgroundElement = "surface0";

        border = "surface1";
        borderActive = "mauve";
        borderSubtle = "surface0";

        # Diff colors
        diffAdded = "green";
        diffRemoved = "red";
        diffContext = "overlay1";
        diffHunkHeader = "sapphire";
        diffHighlightAdded = "green";
        diffHighlightRemoved = "red";
        diffAddedBg = "surface0";
        diffRemovedBg = "surface0";
        diffContextBg = "mantle";
        diffLineNumber = "overlay0";
        diffAddedLineNumberBg = "surface0";
        diffRemovedLineNumberBg = "surface0";

        # Markdown rendering
        markdownText = "text";
        markdownHeading = "mauve";
        markdownLink = "sapphire";
        markdownLinkText = "blue";
        markdownCode = "green";
        markdownBlockQuote = "overlay1";
        markdownEmph = "pink";
        markdownStrong = "peach";
        markdownHorizontalRule = "surface1";
        markdownListItem = "text";
        markdownListEnumeration = "mauve";
        markdownImage = "sapphire";
        markdownImageText = "blue";
        markdownCodeBlock = "text";

        # Syntax highlighting
        syntaxComment = "overlay1";
        syntaxKeyword = "mauve";
        syntaxFunction = "blue";
        syntaxVariable = "text";
        syntaxString = "green";
        syntaxNumber = "peach";
        syntaxType = "yellow";
        syntaxOperator = "sapphire";
        syntaxPunctuation = "overlay2";
      };
    };
  };
}

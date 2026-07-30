# Starship prompt — themed via shared palette
# Theme: Catppuccin Frappe (sourced from _shared/theme)
{ hostMeta ? { }, ... }:

let
  theme = (import ../../../_shared/theme).call (if builtins.hasAttr "theme" hostMeta then hostMeta.theme else "catppuccin-frappe");
  p = theme.palette;
in
{
  programs.starship = {
    enable = true;
    enableZshIntegration = false;

    settings = {
      "$schema" = "https://starship.rs/config-schema.json";

      format = "[](${p.mauve})$os$username[](bg:${p.pink} fg:${p.mauve})$directory[](fg:${p.pink} bg:${p.peach})$git_branch$git_status$terraform[](fg:${p.peach} bg:${p.sapphire})$c$elixir$elm$golang$gradle$haskell$java$julia$nodejs$nim$rust$scala[](fg:${p.sapphire} bg:${p.green})$docker_context[](fg:${p.green} bg:${p.blue})$time[ ](fg:${p.blue})";

      username = {
        show_always = true;
        style_user = "bg:${p.mauve} fg:${p.base}";
        style_root = "bg:${p.mauve} fg:${p.base}";
        format = "[$user ]($style)";
        disabled = false;
      };

      os = {
        style = "bg:${p.mauve} fg:${p.base}";
        disabled = true;
      };

      directory = {
        style = "bg:${p.pink} fg:${p.base}";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = "…/";
        substitutions = {
          "Documents" = "󰈙 ";
          "Downloads" = " ";
          "Music" = " ";
          "Pictures" = " ";
        };
      };

      git_branch = {
        symbol = "";
        style = "bg:${p.peach} fg:${p.base}";
        format = "[ $symbol $branch ]($style)";
      };

      git_status = {
        style = "bg:${p.peach} fg:${p.base}";
        format = "[$all_status$ahead_behind ]($style)";
      };

      terraform = {
        symbol = "󱁢 ";
        style = "bg:${p.peach} fg:${p.base}";
        format = "[ $symbol $workspace ]($style)";
        detect_extensions = [ "tf" "tfvars" ];
        detect_files = [ "terraform.tfstate" ];
        detect_folders = [ ".terraform" ];
      };

      # Language modules (sapphire colour segment)
      c = {
        symbol = " ";
        style = "bg:${p.sapphire} fg:${p.base}";
        format = "[ $symbol ($version) ]($style)";
      };

      cpp = {
        symbol = " ";
        style = "bg:${p.sapphire} fg:${p.base}";
        format = "[ $symbol ($version) ]($style)";
      };

      elixir = {
        symbol = " ";
        style = "bg:${p.sapphire} fg:${p.base}";
        format = "[ $symbol ($version) ]($style)";
      };

      elm = {
        symbol = " ";
        style = "bg:${p.sapphire} fg:${p.base}";
        format = "[ $symbol ($version) ]($style)";
      };

      golang = {
        symbol = " ";
        style = "bg:${p.sapphire} fg:${p.base}";
        format = "[ $symbol ($version) ]($style)";
      };

      gradle = {
        style = "bg:${p.sapphire} fg:${p.base}";
        format = "[ $symbol ($version) ]($style)";
      };

      haskell = {
        symbol = " ";
        style = "bg:${p.sapphire} fg:${p.base}";
        format = "[ $symbol ($version) ]($style)";
      };

      java = {
        symbol = " ";
        style = "bg:${p.sapphire} fg:${p.base}";
        format = "[ $symbol ($version) ]($style)";
      };

      julia = {
        symbol = " ";
        style = "bg:${p.sapphire} fg:${p.base}";
        format = "[ $symbol ($version) ]($style)";
      };

      nodejs = {
        symbol = "";
        style = "bg:${p.sapphire} fg:${p.base}";
        format = "[ $symbol ($version) ]($style)";
      };

      nim = {
        symbol = "󰆥 ";
        style = "bg:${p.sapphire} fg:${p.base}";
        format = "[ $symbol ($version) ]($style)";
      };

      rust = {
        symbol = "";
        style = "bg:${p.sapphire} fg:${p.base}";
        format = "[ $symbol ($version) ]($style)";
      };

      scala = {
        symbol = " ";
        style = "bg:${p.sapphire} fg:${p.base}";
        format = "[ $symbol ($version) ]($style)";
      };

      docker_context = {
        symbol = " ";
        style = "bg:${p.green} fg:${p.base}";
        format = "[ $symbol $context ]($style)";
      };

      time = {
        disabled = false;
        time_format = "%R";
        style = "bg:${p.blue} fg:${p.base}";
        format = "[ ♥ $time ]($style)";
      };
    };
  };
}

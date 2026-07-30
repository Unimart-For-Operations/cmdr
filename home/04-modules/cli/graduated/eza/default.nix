# eza — modern ls replacement with git integration and icons
#
# ZSH integration is disabled here because all eza aliases are defined
# manually in shell/zsh/default.nix with custom --group-directories-first
# and --ignore-glob flags for a consistent experience.
# extraOptions provides base flags inherited when calling `eza` directly.
{ ... }:

{
  programs.eza = {
    enable = true;
    enableZshIntegration = false;
    git = true;
    icons = "auto";
    extraOptions = [
      "--group-directories-first"
    ];
  };
}

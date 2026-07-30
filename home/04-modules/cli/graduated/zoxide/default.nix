# zoxide — smart cd replacement, learns frequently-used directories
{ ... }:

{
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
}

{ ... }:

{
  imports = [
    ./linux-packages.nix
  ];

  home.sessionPath = [
    "$HOME/.local/bin"
    "/usr/local/bin"
    "/opt/bin"
  ];

  home.sessionVariables = {
    LC_ALL = "en_US.UTF-8";
  };
}

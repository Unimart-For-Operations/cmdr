# Go development environment
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    go # Go compiler and toolchain
  ];

  # GOPATH defaults to ~/go — add its bin dir to PATH for `go install`-ed tools
  home.sessionPath = [
    "$HOME/go/bin"
  ];
}

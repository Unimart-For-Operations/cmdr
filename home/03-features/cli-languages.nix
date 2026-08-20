# home/03-features/cli-languages.nix — Programming Language Toolchains
#
# Runtime environments and language-specific tools:
#   - go — Go toolchain + gopls
#   - python — Python runtime + poetry + black
#
#   features = [ "cli-core" "cli-languages" ];
{ ... }:

{
  imports = [
    ../04-modules/cli/graduated/go
    ../04-modules/cli/graduated/python
  ];
}

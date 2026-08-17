{ pkgs, ... }:

# VS Code >= 1.129 ships the darwin ripgrep binary under
# node_modules.asar.unpacked/, but nixpkgs' patchPhase still chmods the old
# node_modules/ path (NixOS/nixpkgs#543690). Shim the old path so the build works.
{
  home.packages = [
    (pkgs.vscode.overrideAttrs (old: {
      prePatch = (old.prePatch or "") + ''
        rgSrc="$PWD/Contents/Resources/app/node_modules.asar.unpacked/@vscode/ripgrep-universal/bin/darwin-arm64/rg"
        rgDst="$PWD/Contents/Resources/app/node_modules/@vscode/ripgrep-universal/bin/darwin-arm64"
        if [ -e "$rgSrc" ]; then
          mkdir -p "$rgDst"
          [ -e "$rgDst/rg" ] || ln -s "$rgSrc" "$rgDst/rg"
        fi
      '';
    }))
  ];
}

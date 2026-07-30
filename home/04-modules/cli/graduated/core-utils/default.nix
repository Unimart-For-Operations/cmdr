# Core CLI utilities — general-purpose tools with no dedicated config module.
# These work identically on both platforms and don't belong to any specific
# functional category.
{ pkgs, ... }:

let
  # notesmd-cli — CLI for programmatic Obsidian vault management.
  # Not in nixpkgs; built from source.
  # https://github.com/Yakitrak/notesmd-cli
  notesmd-cli = (pkgs.buildGoModule.override { go = pkgs.go_1_26; }) rec {
    pname = "notesmd-cli";
    version = "0.3.4";

    src = pkgs.fetchFromGitHub {
      owner = "Yakitrak";
      repo = "notesmd-cli";
      rev = "v${version}";
      hash = "sha256-sZKyXDgDuJI7cFIMQl1w2Ir92HmhZ1Vhz7FUoEkn3Mo=";
    };

    vendorHash = null; # deps vendored in-tree

    env.CGO_ENABLED = 0;

    meta = with pkgs.lib; {
      description = "CLI tool for managing Obsidian vaults";
      homepage = "https://github.com/Yakitrak/notesmd-cli";
      license = licenses.mit;
    };
  };
in
{
  home.packages = with pkgs; [
    # Modern CLI replacements
    ripgrep # Better grep (also required by Telescope in nvim)
    fd # Better find (also required by Telescope in nvim)

    # Core utilities
    jq # JSON processor
    yq-go # YAML processor
    tree # Directory tree viewer
    wget # File downloader
    curl # HTTP client
    unzip # Zip extraction
    gzip # Compression
    btop

    # Language runtimes & package managers
    nodejs_22 # LTS — https://nodejs.org/en/about/previous-releases
    (pnpm.override { nodejs-slim = nodejs_22; }) # Linked to Node 22 (default pkgs.nodejs is 24)

    # AWS SSO helper — provides assume, granted, assumego
    granted

    # Development environments
    devbox # Isolated dev shells per-project

    # Notes / knowledge
    basalt # TUI for managing Obsidian vaults
    notesmd-cli # CLI for programmatic Obsidian vault management
  ];
}

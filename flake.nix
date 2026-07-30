{
  description = "cmdr — Arch-First, Container-Tested, Nix-Native";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nixGL: wraps Nix-managed OpenGL/EGL applications so they can find the
    # host system's GPU drivers on non-NixOS distributions (e.g. CachyOS/Arch).
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # DankMaterialShell: full desktop shell (panel, launcher, lock, notifications)
    # replacing waybar, rofi, mako, hyprlock, swayidle, etc.
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # sops-nix: encrypted secrets management
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # meta: idpbuilder org coordination repo — provides the unimart CLI
    # Uses git+ssh:// (not github:) because this is a private repo.
    # The github: scheme uses the GitHub REST API which requires an access
    # token; git+ssh:// uses the user's existing SSH key.
    meta = {
      url = "git+ssh://git@github.com/idpbuilder/meta.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, nixvim, nixgl, dms, sops-nix, meta, ... }@inputs:
    let
      lib = nixpkgs.lib;

      # Supported systems
      systems = [ "x86_64-linux" "aarch64-darwin" ];

      # Helper to generate attributes for all systems
      forAllSystems = nixpkgs.lib.genAttrs systems;

      # Helper to get pkgs for a system
      pkgsFor = system: import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      hosts = import ./home/02-hosts { inherit lib; };

      # Split hosts by platform/distro for routing to the correct output
      darwinHosts = lib.filterAttrs (_: h: h.platform == "darwin") hosts;
      nixosHosts = lib.filterAttrs
        (name: h:
          h.distro == "nixos"
          && builtins.pathExists ./home/02-hosts/nixos/${name}/hardware-configuration.nix
          && builtins.pathExists ./home/02-hosts/nixos/${name}/system.nix
        )
        hosts;
      linuxHosts = lib.filterAttrs (_: h: h.platform == "linux") hosts;

      # ── Linux hosts: standalone Home Manager (unchanged) ──────────────────
      mkHomeConfiguration = name: host:
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor host.system;
          modules = host.modules
            ++ [
            sops-nix.homeManagerModules.sops
            {
              home = {
                username = host.username;
                homeDirectory = host.homeDirectory;
              };
            }
          ];
          extraSpecialArgs = {
            inherit inputs;
            hostName = name;
            hostMeta = host;
          };
        };

      # ── macOS hosts: nix-darwin with embedded Home Manager ────────────────
      mkDarwinConfiguration = name: host:
        nix-darwin.lib.darwinSystem {
          modules = [
            # Shared system-level config (Homebrew, Nix daemon, defaults)
            ./darwin/system.nix

            # Home Manager as a nix-darwin module
            home-manager.darwinModules.home-manager
            {
              nixpkgs.hostPlatform = host.system;
              system.primaryUser = host.username;

              # nix-darwin's users.users.<name>.home feeds into Home Manager's
              # home.homeDirectory via common.nix. Setting it here avoids a
              # null default that would conflict with our explicit value.
              users.users.${host.username}.home = host.homeDirectory;

              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = {
                  inherit inputs;
                  hostName = name;
                  hostMeta = host;
                };
                users.${host.username} = {
                  imports = host.modules ++ [
                    sops-nix.homeManagerModules.sops
                  ];
                  home = {
                    username = host.username;
                    homeDirectory = host.homeDirectory;
                  };
                };
              };
            }
          ];
          specialArgs = {
            inherit inputs;
            hostName = name;
            hostMeta = host;
          };
        };

      # ── NixOS hosts: nixosSystem with embedded Home Manager ───────────────
      mkNixOSConfiguration = name: host:
        nixpkgs.lib.nixosSystem {
          system = host.system;
          modules = [
            ./nixos/system.nix
            ./home/02-hosts/nixos/${name}/hardware-configuration.nix
            ./home/02-hosts/nixos/${name}/system.nix
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = {
                  inherit inputs;
                  hostName = name;
                  hostMeta = host;
                };
                sharedModules = [
                  sops-nix.homeManagerModules.sops
                ];
                users.${host.username} = {
                  imports = host.modules;
                  home = {
                    username = host.username;
                    homeDirectory = host.homeDirectory;
                  };
                };
              };
            }
          ];
          specialArgs = {
            inherit inputs;
            hostName = name;
            hostMeta = host;
          };
        };
    in
    {
      # Development shells for working ON this repo
      devShells = forAllSystems (system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            name = "cmdr";

            packages = with pkgs; [
              # Nix development tools
              nixpkgs-fmt # Nix code formatter
              nil # Nix LSP for editors

              # Secret management
              age # Age encryption tool for sops-nix
              sops # Secret Operations tool

              # Security
              gitleaks # Secret scanning (pre-commit + CI)

              # Utilities
              jq # JSON processing
            ] ++ [
              # Home Manager CLI from input
              home-manager.packages.${system}.default
            ];

            shellHook = ''
              echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
              echo "cmdr - Development Environment"
              echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
              echo ""
              echo "Available commands:"
              echo "  make help        - Show all available commands"
              echo "  make test        - Spin up Linux test container"
              echo "  make list-hosts  - Show available Home Manager hosts"
              echo "  make fmt         - Format Nix code"
              echo ""
              echo "Home Manager:"
              echo "  make apply HOST=<host>  - Apply a host configuration"
              echo ""
              echo "Repo: $(pwd)"
              echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            '';
          };
        }
      );

      # Formatter for `nix fmt`
      formatter = forAllSystems (system:
        (pkgsFor system).nixpkgs-fmt
      );

      # macOS hosts — nix-darwin with embedded Home Manager
      darwinConfigurations = lib.mapAttrs mkDarwinConfiguration darwinHosts;

      # NixOS hosts — nixosSystem with embedded Home Manager
      nixosConfigurations = lib.mapAttrs mkNixOSConfiguration nixosHosts;

      # Linux hosts — standalone Home Manager (includes NixOS for --home-only)
      homeConfigurations = lib.mapAttrs mkHomeConfiguration linuxHosts;
    };
}

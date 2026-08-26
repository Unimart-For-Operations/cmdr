## =============================================================================
## cmdr — Nix Flake Configuration
## =============================================================================
## 
## This flake defines the complete declarative configuration for the cmdr
## developer workstation. It supports multiple OS targets (macOS via nix-darwin,
## Linux via NixOS and standalone Home Manager) and multiple physical machines
## (detected by hostname at runtime).
##
## Data Flow:
##   Inputs (nixpkgs, home-manager, nix-darwin, etc.)
##     ↓
##   Host Discovery (02-hosts/{distro}/{hostname}/meta.nix → features, desktop)
##     ↓
##   Feature Resolution (03-features/*.nix maps features → modules)
##     ↓
##   Module Assembly (04-modules/cli/graduated/, tui/{graduated,incubating}, gui/graduated/)
##     ↓
##   Target-Specific Config Builder (mkHomeConfiguration / mkDarwinConfiguration / mkNixOSConfiguration)
##     ↓
##   Outputs ({darwin,nixos,home}Configurations, checks)
##
## To apply a configuration to this machine:
##   unimart deli switch
##
## To run checks (format, evaluation, builds):
##   nix flake check
##
## =============================================================================

{
  description = "cmdr — Multi-Platform Declarative Workstation (macOS, NixOS, Arch)";

  ## ───────────────────────────────────────────────────────────────────────────
  ## INPUTS: External Nix flakes and dependencies
  ## ───────────────────────────────────────────────────────────────────────────
  inputs = {
    ## Unstable Nixpkgs: rolling release of ~80k packages. All inputs pin to this
    ## via `follows = "nixpkgs"` to avoid dependency hell.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    ## Home Manager: declarative user-level configuration (shell, editor, dotfiles, etc.)
    ## Works on both NixOS and non-NixOS systems. Pins to nixpkgs to use consistent package versions.
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ## Nix-Darwin: macOS system configuration (similar role to NixOS but for macOS).
    ## Manages launchd, Homebrew, system settings, and embeds Home Manager as a module.
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ## NixVim: Declarative Neovim configuration (plugins, LSP, keymaps, Lua config).
    ## Used by nvim module to generate neovim plugins.
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ## nixGL: GPU wrapper for Nix-managed OpenGL/EGL apps on non-NixOS distributions.
    ## Allows graphical apps (DMS, games) to find host GPU drivers on Arch/CachyOS.
    ## On NixOS, GPU access is handled by the NixOS config. On macOS, unused.
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ## DankMaterialShell (DMS): Full Wayland desktop shell (panel, launcher, notifications, lock screen).
    ## Replaces manual waybar/rofi/mako/hyprlock/swayidle setup. Integrates with matugen for
    ## dynamic color theming tied to wallpaper. Used on Wayland-capable hosts (desktop field in meta.nix).
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ## sops-nix: Encrypted secrets management (age/SSH-key encrypted YAML → environment variables).
    ## Deployed at both system level (NixOS) and user level (Home Manager). Allows safe storage
    ## of secrets (SSH keys, API tokens) in git without exposing plaintext.
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ## meta: Unimart-For-Operations org coordination repo (sibling of cmdr).
    ## Provides the unimart CLI binary (unimart open/close/reload/freezer/deli commands).
    ## Uses git+ssh:// (not github:) because it's a private repo. The github: scheme would
    ## require an access token; git+ssh:// reuses the user's existing SSH key.
    meta = {
      url = "git+ssh://git@github.com/Unimart-For-Operations/meta.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  ## ───────────────────────────────────────────────────────────────────────────
  ## OUTPUTS: Flake derivations and attribute sets
  ## ───────────────────────────────────────────────────────────────────────────
  ##
  ## The outputs attrset contains:
  ##   - devShells: dev environment for *working on* this repo
  ##   - formatter: nixpkgs-fmt for `nix fmt`
  ##   - {darwin,nixos,home}Configurations: target-specific system configs
  ##   - checks: evaluation and format checks run by `nix flake check`
  outputs = { self, nixpkgs, home-manager, nix-darwin, nixvim, nixgl, dms, sops-nix, meta, ... }@inputs:
    let
      lib = nixpkgs.lib;

      ## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      ## SYSTEM DEFINITIONS
      ## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

      ## Supported CPU/OS pairs. Each output attribute set is replicated per system,
      ## allowing the flake to be consumed by both x86_64-linux and aarch64-darwin machines.
      ## Cross-system evaluation (e.g., evaluating the aarch64-darwin config from Linux)
      ## is possible because checks don't try to build — they only evaluate drv paths.
      systems = [ "x86_64-linux" "aarch64-darwin" ];

      ## Helper: map over all supported systems and collect results into an attrset.
      ## Used by checks, devShells, formatter.
      forAllSystems = nixpkgs.lib.genAttrs systems;

      ## Helper: import nixpkgs for a given system with unfree packages allowed.
      ## This is called once per system per outputs attribute, so caching via let-binding
      ## would require calling it per-host instead. It's cheap (~1ms) so repeated calls are fine.
      pkgsFor = system: import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      ## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      ## HOST DISCOVERY ENGINE
      ## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

      ## Import 02-hosts/default.nix: scans distro subdirs (macos, arch, nixos, ubuntu),
      ## finds meta.nix in each <distro>/<hostname>/, parses features/desktop/sandbox fields,
      ## and returns a flat attrset { hostname → { system, platform, distro, modules, ... } }.
      ## This drives all subsequent config routing.
      hosts = import ./home/02-hosts { inherit lib; };


      ## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      ## HOST ROUTING: Filter hosts by platform/distro for correct builder
      ## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

      ## macOS hosts: detected by platform == "darwin".
      ## These will be built with `nix-darwin.lib.darwinSystem`.
      darwinHosts = lib.filterAttrs (_: h: h.platform == "darwin") hosts;

      ## NixOS hosts: detected by:
      ##   1. distro == "nixos"
      ##   2. Both hardware-configuration.nix and system.nix exist (otherwise NixOS system parts are missing)
      ## These will be built with `nixpkgs.lib.nixosSystem` and embed Home Manager as a nixos module.
      nixosHosts = lib.filterAttrs
        (name: h:
          h.distro == "nixos"
          && builtins.pathExists ./home/02-hosts/nixos/${name}/hardware-configuration.nix
          && builtins.pathExists ./home/02-hosts/nixos/${name}/system.nix
        )
        hosts;

      ## Linux hosts: detected by platform == "linux".
      ## This includes NixOS hosts (which also have distro == "nixos" and system files),
      ## as well as non-NixOS Linux hosts (Arch, CachyOS, Ubuntu) that run standalone Home Manager.
      ## These will be built with `home-manager.lib.homeManagerConfiguration`.
      linuxHosts = lib.filterAttrs (_: h: h.platform == "linux") hosts;


      ## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      ## BUILDER: Standalone Home Manager (non-NixOS Linux)
      ## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      ##
      ## Used for: Arch, CachyOS, Ubuntu (non-NixOS) Linux hosts.
      ## Output: .homeConfigurations.<hostname> → activation script to apply user config.
      ##
      ## Module composition (in order):
      ##   1. host.modules (from feature resolution in 02-hosts/default.nix)
      ##   2. sops-nix Home Manager module (secrets)
      ##   3. home.username and home.homeDirectory (user identity)
      ##
      ## Data passed to all submodules via extraSpecialArgs:
      ##   - inputs: all flake inputs (nixpkgs, home-manager, dms, etc.)
      ##   - hostName: the hostname string
      ##   - hostMeta: the full host attrset (meta.nix fields)
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


      ## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      ## BUILDER: macOS via Nix-Darwin with embedded Home Manager
      ## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      ##
      ## Used for: macOS hosts (apple-studio-m2-max, apple-macbook-m3-pro).
      ## Output: .darwinConfigurations.<hostname> → launchd services, Homebrew setup, and Home Manager.
      ##
      ## Module composition:
      ##   1. darwin/system.nix: Nix daemon config, system defaults, Homebrew settings
      ##   2. home-manager.darwinModules.home-manager: HM integration layer
      ##   3. System-level config (primaryUser, home directories, HM options)
      ##   4. Home Manager user config (host.modules from feature resolution)
      ##   5. sops-nix (secrets)
      ##
      ## Why embedded HM: macOS doesn't have a system package manager (unlike apt/pacman/dnf).
      ## Nix-darwin manages /etc and launchd, while Home Manager manages the user shell/dotfiles/packages.
      ## Both must cooperate: useGlobalPkgs=true makes HM use the system nixpkgs, avoiding two separate copies.
      ##
      ## Data passed via specialArgs (to darwin/system.nix):
      ##   - inputs, hostName, hostMeta
      ## Data passed via HM extraSpecialArgs (to HM modules):
      ##   - inputs, hostName, hostMeta (same set)
      mkDarwinConfiguration = name: host:
        nix-darwin.lib.darwinSystem {
          modules = [
            # System-level configuration (Homebrew, Nix daemon, launchd defaults)
            ./darwin/system.nix

            # Home Manager as a nix-darwin module (integrates user config with system config)
            home-manager.darwinModules.home-manager
            {
              # Tell nixpkgs which platform we're building for (used by buildPhase to select binaries)
              nixpkgs.hostPlatform = host.system;

              # Designate the primary user for nix-darwin (affects some launchd contexts)
              system.primaryUser = host.username;

              # Nix-darwin's users.users.<name>.home → Home Manager's home.homeDirectory
              # This line MUST be set here, before HM initialization, to avoid conflicts
              # with HM's default (which might be null on first eval).
              users.users.${host.username}.home = host.homeDirectory;

              # Home Manager configuration embedded in nix-darwin
              home-manager = {
                # useGlobalPkgs: share the system nixpkgs instead of fetching a separate copy
                # (saves ~500MB of disk, makes HM and system upgrades atomic)
                useGlobalPkgs = true;

                # useUserPackages: let HM manage packages in the user's nix profile
                # (keeps home-manager's state.nix in the user's home, not in system output)
                useUserPackages = true;

                # Pass flake inputs and host metadata to HM modules
                extraSpecialArgs = {
                  inherit inputs;
                  hostName = name;
                  hostMeta = host;
                };

                # Configure Home Manager for this user
                users.${host.username} = {
                  # Modules to load (from feature resolution: cli, tui, gui, etc.)
                  imports = host.modules ++ [
                    sops-nix.homeManagerModules.sops
                  ];
                  # User identity
                  home = {
                    username = host.username;
                    homeDirectory = host.homeDirectory;
                  };
                };
              };
            }
          ];
          # Also pass specialArgs to darwin/system.nix
          specialArgs = {
            inherit inputs;
            hostName = name;
            hostMeta = host;
          };
        };


      ## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      ## BUILDER: NixOS with embedded Home Manager
      ## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      ##
      ## Used for: Linux hosts with NixOS (strix-nix).
      ## Output: .nixosConfigurations.<hostname> → /nix/store/...-nixos-system-version
      ##         (bootable system closure: kernel, initrd, /etc, systemd services)
      ##
      ## Module composition:
      ##   1. nixos/system.nix: NixOS defaults (services, networking, security)
      ##   2. <host>/hardware-configuration.nix: Hardware probe (storage, CPU, GPU drivers)
      ##   3. <host>/system.nix: Host-specific overrides and packages
      ##   4. home-manager.nixosModules.home-manager: HM integration
      ##   5. Home Manager user config (host.modules from features)
      ##   6. sops-nix (system-level secrets via sharedModules)
      ##
      ## Why embedded HM: NixOS manages the system; Home Manager manages the user.
      ## They must be in the same eval context to share options (e.g., nixpkgs.overlays).
      ## sharedModules passes sops-nix to all HM users automatically.
      ##
      ## Data passed via specialArgs (to all NixOS modules):
      ##   - inputs, hostName, hostMeta
      mkNixOSConfiguration = name: host:
        nixpkgs.lib.nixosSystem {
          system = host.system;
          modules = [
            # NixOS base config (boot, networking, systemd defaults)
            ./nixos/system.nix

            # Hardware probed at install time (storage, CPU, GPU drivers)
            # MUST exist for this host (checked in nixosHosts filter above)
            ./home/02-hosts/nixos/${name}/hardware-configuration.nix

            # Host-specific system overrides and packages
            # MUST exist for this host (checked in nixosHosts filter above)
            ./home/02-hosts/nixos/${name}/system.nix

            # Home Manager as a NixOS module
            home-manager.nixosModules.home-manager
            {
              # Home Manager configuration
              home-manager = {
                # useGlobalPkgs: HM uses the system nixpkgs (not a separate copy)
                useGlobalPkgs = true;

                # useUserPackages: HM manages user packages via nix profile
                useUserPackages = true;

                # Pass inputs and host metadata to all HM modules
                extraSpecialArgs = {
                  inherit inputs;
                  hostName = name;
                  hostMeta = host;
                };

                # Modules shared across all HM users (e.g., sops secrets)
                sharedModules = [
                  sops-nix.homeManagerModules.sops
                ];

                # Configure Home Manager for the primary user
                users.${host.username} = {
                  # Feature-resolved modules (cli, tui, gui, etc.)
                  imports = host.modules;
                  # User identity
                  home = {
                    username = host.username;
                    homeDirectory = host.homeDirectory;
                  };
                };
              };
            }
          ];
          # Pass to all NixOS modules
          specialArgs = {
            inherit inputs;
            hostName = name;
            hostMeta = host;
          };
        };

      ## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      ## GENERATE OUTPUT CONFIGURATIONS
      ## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      ##
      ## Map each host filter + builder, producing the {darwin,nixos,home}Configurations
      ## attribute sets. These must be hoisted into the `let` block so checks can
      ## reference them without triggering a self-reference loop.
      darwinConfigurations = lib.mapAttrs mkDarwinConfiguration darwinHosts;
      nixosConfigurations = lib.mapAttrs mkNixOSConfiguration nixosHosts;
      homeConfigurations = lib.mapAttrs mkHomeConfiguration linuxHosts;


      ## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      ## CHECKS: Validation run by `nix flake check`
      ## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      ##
      ## Checks are derivations that must be built for `nix flake check` to pass.
      ## They validate:
      ##   1. format: Nix code conforms to nixpkgs-fmt
      ##   2. eval-<host>: Each host config evaluates (catches syntax errors, bad options, broken features)
      ##
      ## Why separate evaluation checks for each host?
      ##   - A NixOS config for strix-nix may fail on an aarch64-darwin machine if we tried to build it.
      ##   - But evaluation (parsing, type checking, option validation) CAN happen cross-platform.
      ##   - Each eval-* check forces drvPath to be evaluated when the check is instantiated,
      ##     then wraps it in a trivial runCommand that echoes OK.
      ##   - This way, we catch module errors, bad feature flags, missing imports, etc., without
      ##     actually building the system (which would require native hardware).
      checks = forAllSystems (system:
        let
          pkgs = pkgsFor system;

          ## ┌─────────────────────────────────────────────────────────────┐
          ## │ Format check: Ensure all .nix files pass nixpkgs-fmt        │
          ## └─────────────────────────────────────────────────────────────┘
          ##
          ## Why: Code consistency and readability. nixpkgs-fmt is the standard
          ## Nix formatter used across the ecosystem.
          ##
          ## How: runCommand instantiates a derivation without building it,
          ## unless the derivation is actually required. Since we never build it
          ## (flake check only instantiates), it acts as an evaluation-time check.
          format = pkgs.runCommand "cmdr-format-check"
            {
              src = self;
              nativeBuildInputs = [ pkgs.nixpkgs-fmt ];
            } ''
            find "$src" -name '*.nix' -type f -print0 | xargs -0 nixpkgs-fmt --check
            echo "format: OK" > $out
          '';

          ## ┌─────────────────────────────────────────────────────────────┐
          ## │ Evaluation checks: Force evaluation of host configs          │
          ## └─────────────────────────────────────────────────────────────┘
          ##
          ## Why: Each host config may reference features, modules, or options
          ## that don't exist. Evaluation catches these errors early.
          ##
          ## How: builtins.seq (drvPath) evaluates drvPath before returning,
          ## then evaluates the runCommand. builtins.trace prints to stderr
          ## as a side effect. The derivation is never built, so we stay
          ## evaluation-only (fast, cross-platform).
          ##
          ## What gets caught:
          ##   - Unknown feature strings → "unknown feature" throw in 02-hosts/default.nix
          ##   - Bad module imports → file not found
          ##   - Invalid option values → type errors, range checks
          ##   - Circular imports → Nix evaluator detects infinite recursion
          ##   - Broken home-manager options → HM module validation
          evalCheck = name: drvPath:
            builtins.seq
              (builtins.trace "cmdr: evaluating host '${name}'" drvPath)
              (pkgs.runCommand "cmdr-eval-${name}" { } ''
                echo "eval ${name}: OK" > $out
              '');

          ## Collect all Home Manager (Linux) evaluation checks
          evalHome = lib.mapAttrs'
            (name: _: lib.nameValuePair "eval-${name}"
              (evalCheck name homeConfigurations.${name}.activationPackage.drvPath))
            linuxHosts;

          ## Collect all Nix-Darwin (macOS) evaluation checks
          evalDarwin = lib.mapAttrs'
            (name: _: lib.nameValuePair "eval-${name}"
              (evalCheck name darwinConfigurations.${name}.system.drvPath))
            darwinHosts;

          ## Collect all NixOS evaluation checks
          evalNixOS = lib.mapAttrs'
            (name: _: lib.nameValuePair "eval-${name}"
              (evalCheck name nixosConfigurations.${name}.config.system.build.toplevel.drvPath))
            nixosHosts;
        in
        {
          inherit format;
        }
        // evalHome
        // evalDarwin
        // evalNixOS
      );
    in
    {
      ## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      ## devShells: Development environment for working ON this repo
      ## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      ##
      ## To enter this environment:
      ##   nix flake enter
      ##   # or:
      ##   nix develop
      ##
      ## This shell provides:
      ##   - Nix development tools (formatter, LSP, secrets management)
      ##   - Home Manager CLI for testing configurations
      ##   - Build/check/test commands via make
      ##
      ## Note: This is NOT the runtime shell — it's for editing the cmdr config itself.
      devShells = forAllSystems (system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            name = "cmdr";

            packages = with pkgs; [
              ## ──────────────────────────────────────────────────────────
              ## Nix development tools
              ## ──────────────────────────────────────────────────────────

              ## Code formatter (mirrors `make fmt` and `nix fmt`)
              nixpkgs-fmt

              ## Language server for Nix in editors (helix, neovim, vscode, etc.)
              nil

              ## ──────────────────────────────────────────────────────────
              ## Secret management (sops-nix tooling)
              ## ──────────────────────────────────────────────────────────

              ## Encryption tool (encrypts/decrypts YAML secrets with SSH or age keys)
              age

              ## Secrets Operations CLI (frontend for age-based encryption in YAML)
              sops

              ## ──────────────────────────────────────────────────────────
              ## Security scanning
              ## ──────────────────────────────────────────────────────────

              ## Git pre-commit hook for detecting secrets (SSH keys, API tokens, etc.)
              ## Used by make ci
              gitleaks

              ## ──────────────────────────────────────────────────────────
              ## Utilities
              ## ──────────────────────────────────────────────────────────

              ## JSON processor (used by make scripts and CI)
              jq
            ] ++ [
              ## Home Manager CLI from the input flake
              ## Allows `home-manager build` and `home-manager switch` in dev
              home-manager.packages.${system}.default
            ];

            ## Shell message when entering this environment
            shellHook = ''
              echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
              echo "cmdr - Development Environment"
              echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
              echo ""
              echo "Available commands:"
              echo "  make help        - Show all available commands"
              echo "  make ci          - Run static checks (gitleaks, fmt, flake, doctor)"
              echo "  make ci-full     - Run ci plus the automated container test"
              echo "  make test        - Spin up Linux test container"
              echo "  make test-run    - Automated container provision + verify + teardown"
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

      ## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      ## formatter: Nix code formatter for `nix fmt`
      ## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      ##
      ## To format all Nix files:
      ##   nix fmt
      ##   # or:
      ##   make fmt
      formatter = forAllSystems (system:
        (pkgsFor system).nixpkgs-fmt
      );

      ## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      ## Flake outputs: configurations and checks
      ## ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      ##
      ## These are defined above (in the `let` block) so checks can reference them.
      ## We re-export them here to make them part of the flake output.
      checks = checks;
      darwinConfigurations = darwinConfigurations;
      nixosConfigurations = nixosConfigurations;
      homeConfigurations = homeConfigurations;
    };
}

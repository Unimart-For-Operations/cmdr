# legion-nix Onboarding Guide

Comprehensive setup guide for the `legion-nix` NixOS host, informed by lessons learned from `strix-nix` deployment.

## Pre-Installation Checklist

Before beginning the NixOS installation:

- [ ] Physical hardware specifications documented (CPU, GPU, RAM, storage)
- [ ] Network connectivity verified (Ethernet or WiFi)
- [ ] USB installation media prepared (NixOS minimal ISO)
- [ ] Backup of any existing data completed
- [ ] BIOS/UEFI settings reviewed (Secure Boot disabled recommended for easier setup)

## NixOS Installation

### Standard Installation Flow

1. Boot from NixOS installation media
2. Partition the disk (example for UEFI):
   ```bash
   # Create partitions (adjust /dev/sdX to your device)
   parted /dev/sdX -- mklabel gpt
   parted /dev/sdX -- mkpart ESP fat32 1MiB 512MiB
   parted /dev/sdX -- set 1 esp on
   parted /dev/sdX -- mkpart primary 512MiB 100%
   
   # Format partitions
   mkfs.fat -F 32 -n boot /dev/sdX1
   mkfs.ext4 -L nixos /dev/sdX2
   
   # Mount filesystems
   mount /dev/disk/by-label/nixos /mnt
   mkdir -p /mnt/boot
   mount /dev/disk/by-label/boot /mnt/boot
   ```

3. Generate initial configuration:
   ```bash
   nixos-generate-config --root /mnt
   ```

4. Edit `/mnt/etc/nixos/configuration.nix` for basic settings:
   - Set `networking.hostName = "legion-nix";`
   - Enable NetworkManager: `networking.networkmanager.enable = true;`
   - Create initial user account
   - Enable SSH if needed: `services.openssh.enable = true;`

5. Install NixOS:
   ```bash
   nixos-install
   reboot
   ```

### Post-Installation: Initial User Setup

After rebooting into the fresh NixOS system:

```bash
# Set password for your user
passwd

# Install git (temporary until cmdr takes over)
nix-shell -p git

# Clone the meta repository
git clone https://github.com/Unimart-For-Operations/meta.git ~/repos/Unimart-For-Operations/meta
cd ~/repos/Unimart-For-Operations/meta

# Initialize submodules
git submodule update --init --recursive
```

## Hardware-Specific Configuration

### Capture Hardware Configuration

The `hardware-configuration.nix` file must be captured from the running system:

```bash
# From within the meta/cmdr directory
sudo nixos-generate-config --show-hardware-config > home/02-hosts/nixos/legion-nix/hardware-configuration.nix
```

**Critical**: Commit this file alongside your host configuration. It contains:
- Filesystem UUIDs
- Boot loader settings
- Kernel modules for your specific hardware
- initrd configuration

### Common Hardware Additions

Based on `strix-nix` experience, you may need to configure:

#### NVIDIA GPU (if present)

```nix
# In system.nix
services.xserver.videoDrivers = [ "nvidia" ];

hardware.nvidia = {
  modesetting.enable = true;
  powerManagement.enable = true;
  powerManagement.finegrained = false;
  open = false;  # Use proprietary driver
  nvidiaSettings = true;
  package = config.boot.kernelPackages.nvidiaPackages.stable;
};

hardware.graphics = {
  enable = true;
  enable32Bit = true;  # For 32-bit games/applications
};
```

#### Bluetooth

```nix
# In system.nix
hardware.bluetooth.enable = true;
```

**Lesson learned**: Bluetooth hardware won't be recognized without explicit enable.

#### Special Keyboard Features

For laptops with backlit keyboards (ASUS example from strix-nix):

```nix
# Grant video group write access for brightnessctl
users.users.${hostMeta.username}.extraGroups = [ "video" ];

services.udev.extraRules = ''
  SUBSYSTEM=="leds", KERNEL=="asus::kbd_backlight", ACTION=="add|change", GROUP="video", MODE="0660"
'';

# Restore brightness at boot
systemd.services.kbd-backlight = {
  description = "Restore keyboard backlight brightness";
  wantedBy = [ "multi-user.target" ];
  after = [ "systemd-udev-settle.service" ];
  wants = [ "systemd-udev-settle.service" ];
  serviceConfig = {
    Type = "oneshot";
    RemainAfterExit = true;
    ExecStart = "${pkgs.bash}/bin/bash -c 'echo 3 > /sys/class/leds/asus::kbd_backlight/brightness'";
  };
};
```

## Host Configuration Files

The `legion-nix` host requires four files in `home/02-hosts/nixos/legion-nix/`:

### 1. meta.nix (already created)

Declares features, capabilities, and user identity. Current configuration:

```nix
{
  description = "legion-nix — NixOS workstation";
  system = "x86_64-linux";
  username = "cmdr";
  homeDirectory = "/home/cmdr";
  gitName = "Andrew Mortimer";
  gitEmail = "andrcmdr@protonmail.com";
  role = "tty-engineer";
  capabilities = [ "baseline" "terminal-dev" "operator" ];
  features = [ "cli" "tui" ];
}
```

**To add GUI later**: Add `"gui"` to features and optionally:
```nix
desktop = [ "hyprland" "dms" ];
```

### 2. default.nix (already created)

Host-specific Home Manager overrides. Currently minimal:

```nix
{ ... }:

{
  # Add overrides here only when this machine diverges from the shared baseline.
}
```

**Common additions**:
- SSH key paths
- Machine-specific program settings
- Shell trampoline (see below)

### 3. system.nix (needs creation)

NixOS system-level configuration. Minimal template:

```nix
{ config, pkgs, lib, hostMeta, ... }:

{
  # ── Boot ──────────────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ── Networking ────────────────────────────────────────────────
  networking.hostName = "legion-nix";
  networking.networkmanager.enable = true;

  # ── Virtualization ────────────────────────────────────────────
  virtualisation.docker.enable = true;

  # ── Nix LD (for running non-NixOS binaries) ──────────────────
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      openssl
    ];
  };

  system.stateVersion = "26.05";  # Match your NixOS version
}
```

### 4. hardware-configuration.nix (captured from system)

**Do not hand-write this file**. Generate it with:

```bash
sudo nixos-generate-config --show-hardware-config > home/02-hosts/nixos/legion-nix/hardware-configuration.nix
```

## Known Pain Points & Solutions

### 1. Shell Trampoline Required

**Problem**: NixOS keeps `/etc/passwd` shell at bash unless changed in system config. Home Manager configures zsh but can't change the login shell without system-level config.

**Solution**: Add bash trampoline to `default.nix`:

```nix
# In default.nix
home.file.".bash_profile".text = ''
  if [ -n "''${BASH_VERSION:-}" ] && [ -t 1 ] && [ -z "''${ZSH_VERSION:-}" ] && command -v zsh >/dev/null 2>&1; then
    exec zsh -l
  fi
'';

home.file.".bashrc".text = ''
  if [ -n "''${BASH_VERSION:-}" ] && [ -t 0 ] && [ -t 1 ] && [ -z "''${ZSH_VERSION:-}" ] && command -v zsh >/dev/null 2>&1; then
    exec zsh
  fi
'';
```

### 2. DNS Resolution for Local IDP (if running idpbuilder)

**Problem**: Default resolver can't reach `*.localtest.me` hostnames. Platform services at `*.cnoe.localtest.me` return DNS errors.

**Solution**: NetworkManager dnsmasq wildcard (add to `system.nix`):

```nix
networking.networkmanager.dns = "dnsmasq";
environment.etc."NetworkManager/dnsmasq.d/idp-localtest.conf".text = ''
  address=/cnoe.localtest.me/127.0.0.1
'';
```

**Benefit**: No per-host `/etc/hosts` entries needed.

### 3. GUI Desktop (if added later): uwsm Session Startup

**Problem**: When using Hyprland with the DMS greeter, login bounces back to greeter with error:
```
wayland-session-bindpid@.service ... exit status 5
```

**Root cause**: uwsm's systemd user units aren't on the search path without explicit opt-in.

**Solution**: Add to `system.nix`:

```nix
programs.hyprland = {
  enable = true;
  xwayland.enable = true;
  withUWSM = true;  # Critical for DMS greeter
};
```

### 4. Container Testing Limitations

**Cannot test GUI/desktop configurations in containers**. Hosts with `features = [ "gui" ]` or `desktop = [ ... ]` will fail to activate in container environments.

**Workaround**: Keep `legion-nix` as CLI+TUI only, or test GUI configs only on bare metal.

### 5. Cross-Platform Build Constraints

**Cannot build NixOS configurations from macOS hosts**, but evaluation (syntax/type checking) works cross-platform.

**Impact**: `nix flake check` will evaluate all hosts but only build configurations matching the current system.

## Bootstrap Flow

### Option 1: Via unimart (Recommended)

From within the meta repository:

```bash
# Build unimart from the flake
nix run .#unimart -- deli bootstrap

# Or if unimart is already installed
unimart deli bootstrap
```

This will:
1. Detect the host (legion-nix)
2. Install prerequisites
3. Apply the NixOS configuration via `nixos-rebuild switch --flake`
4. Deploy Home Manager configuration
5. Install git hooks
6. Verify the installation

### Option 2: Manual Application

```bash
# From the meta/cmdr directory
cd ~/repos/Unimart-For-Operations/meta/cmdr

# Apply NixOS system configuration (requires sudo)
sudo nixos-rebuild switch --flake .#legion-nix

# Apply Home Manager configuration
home-manager switch --flake .#legion-nix@nixos
```

### Post-Bootstrap Verification

```bash
# Check system health
unimart deli doctor

# Verify git hooks are deployed
ls -la ~/.githooks/

# Verify shell configuration
echo $SHELL
which zsh

# Test a few installed tools
nvim --version
tmux -V
docker --version
```

## IDP Platform Setup (if needed)

If this host will run the local Kubernetes IDP:

### Prerequisites

```bash
# Check prerequisites
unimart freezer doctor

# Install missing prerequisites
unimart freezer bootstrap
```

### Platform Startup

```bash
# Full platform startup (7 steps)
unimart open

# Or step-by-step via freezer aisle
unimart freezer up
unimart freezer repos publish-to-gitea
```

### DNS Verification

Verify local IDP endpoints resolve:

```bash
# Should return 127.0.0.1
dig +short gitea.cnoe.localtest.me
dig +short argocd.cnoe.localtest.me
dig +short backstage.cnoe.localtest.me
```

If DNS doesn't resolve, ensure the NetworkManager dnsmasq config is applied (see pain point #2).

## Development Workflow

### Making Changes to Host Config

```bash
# Edit configuration files
nvim home/02-hosts/nixos/legion-nix/system.nix
nvim home/02-hosts/nixos/legion-nix/default.nix

# Format Nix files
nix fmt

# Apply changes
unimart deli switch

# Or manually
sudo nixos-rebuild switch --flake .#legion-nix
```

### Adding New Modules

Modules are auto-discovered by the feature system. To add a new tool:

1. Create module: `cmdr/home/04-modules/cli/graduated/toolname/default.nix`
2. The module is automatically imported by the feature's tier loader
3. Enable via feature in `meta.nix` (e.g., `cli` feature loads all cli modules)
4. Apply: `unimart deli switch`

### Troubleshooting

```bash
# View recent nixos-rebuild logs
journalctl -u nixos-rebuild -n 50

# Check Home Manager generation
home-manager generations

# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# Verify flake structure
nix flake check ~/repos/Unimart-For-Operations/meta/cmdr
```

## Integration with Meta Repository

### Git Workflow

All changes to `legion-nix` configuration should be committed to the meta repository:

```bash
# From meta root
cd ~/repos/Unimart-For-Operations/meta

# Stage legion-nix configuration
git add cmdr/home/02-hosts/nixos/legion-nix/

# Commit with DCO sign-off (required)
git commit -s -m "feat(legion-nix): add system configuration for GPU/networking"

# Push to remote
git push origin main
```

**Note**: The organization requires DCO sign-off (`-s` flag) on all commits.

### Syncing with cmdr Updates

The cmdr submodule is tracked with `ignore = dirty`:

```bash
# Pull latest cmdr changes
cd ~/repos/Unimart-For-Operations/meta/cmdr
git pull origin main

# Update meta's submodule reference
cd ~/repos/Unimart-For-Operations/meta
git add cmdr
git commit -s -m "chore(cmdr): bump submodule to latest"
```

## Reference: strix-nix as Template

The `strix-nix` host serves as the reference implementation for NixOS + GUI:

```bash
# View strix-nix configuration
cat cmdr/home/02-hosts/nixos/strix-nix/meta.nix
cat cmdr/home/02-hosts/nixos/strix-nix/system.nix
cat cmdr/home/02-hosts/nixos/strix-nix/default.nix
```

Key differences between legion-nix and strix-nix:

| Aspect | legion-nix | strix-nix |
|--------|------------|-----------|
| Features | cli, tui | cli, tui, gui, gaming |
| Desktop | None | hyprland, dms |
| Role | tty-engineer | developer-workstation |
| GPU | TBD | NVIDIA RTX 4080 Mobile |
| Display Manager | None | greetd + DMS greeter |

## Appendix: Useful Commands

```bash
# List all available hosts
unimart deli hosts

# View host metadata
cat cmdr/home/02-hosts/nixos/legion-nix/meta.nix

# Check Nix flake inputs
nix flake metadata ~/repos/Unimart-For-Operations/meta/cmdr

# Update all flake inputs
nix flake update ~/repos/Unimart-For-Operations/meta/cmdr

# Build configuration without applying
sudo nixos-rebuild build --flake .#legion-nix

# Diff current vs new configuration
sudo nixos-rebuild dry-activate --flake .#legion-nix

# List all NixOS generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Delete old generations (keep last 3)
sudo nix-collect-garbage --delete-older-than 3d
```

## Support & Documentation

- **Org-wide docs**: `/home/cmdr/repos/Unimart-For-Operations/meta/AGENTS.md`
- **cmdr docs**: `/home/cmdr/repos/Unimart-For-Operations/meta/cmdr/AGENTS.md`
- **Bootstrap acceptance criteria**: `cmdr/home/02-hosts/nixos/BOOTSTRAP-ACCEPTANCE.md`
- **Module system**: Load `nix-modules` skill in OpenCode
- **Upstream sync**: Load `upstream-mgmt` skill for idpbuilder updates

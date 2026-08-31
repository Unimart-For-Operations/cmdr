# legion-nix Setup Checklist

Quick reference for onboarding the legion-nix host. See ONBOARDING.md for detailed instructions.

## Pre-Installation

- [ ] Hardware specifications documented
- [ ] NixOS installation media prepared
- [ ] Network connectivity verified
- [ ] Existing data backed up (if applicable)

## NixOS Base Installation

- [ ] Boot from installation media
- [ ] Partition disk (UEFI: ESP + root)
- [ ] Format filesystems
- [ ] Mount filesystems to /mnt
- [ ] `nixos-generate-config --root /mnt`
- [ ] Edit /mnt/etc/nixos/configuration.nix (hostname, user, NetworkManager)
- [ ] `nixos-install`
- [ ] Reboot and login

## Repository Setup

- [ ] Install git: `nix-shell -p git`
- [ ] Clone meta: `git clone https://github.com/Unimart-For-Operations/meta.git ~/repos/Unimart-For-Operations/meta`
- [ ] Initialize submodules: `git submodule update --init --recursive`
- [ ] Verify host files exist: `ls cmdr/home/02-hosts/nixos/legion-nix/`

## Hardware Configuration

- [ ] Generate hardware-configuration.nix:
      ```
      sudo nixos-generate-config --show-hardware-config > \
        cmdr/home/02-hosts/nixos/legion-nix/hardware-configuration.nix
      ```
- [ ] Review and commit hardware-configuration.nix
- [ ] Add any hardware-specific config to system.nix:
  - [ ] NVIDIA GPU configuration (if present)
  - [ ] Bluetooth (`hardware.bluetooth.enable = true;`)
  - [ ] Keyboard backlight (if applicable)
  - [ ] Audio configuration

## Configuration Files Review

- [ ] meta.nix - features and capabilities correct
- [ ] default.nix - shell trampoline present
- [ ] system.nix - networking, docker, nix-ld configured
- [ ] hardware-configuration.nix - generated from system

## Bootstrap & Apply

- [ ] Run bootstrap:
      ```
      cd ~/repos/Unimart-For-Operations/meta
      nix run .#unimart -- deli bootstrap
      ```
  OR manually:
      ```
      cd ~/repos/Unimart-For-Operations/meta/cmdr
      sudo nixos-rebuild switch --flake .#legion-nix
      ```

## Post-Bootstrap Verification

- [ ] `unimart deli doctor` passes
- [ ] Git hooks deployed: `ls -la ~/.githooks/`
- [ ] Zsh is active: `echo $SHELL` shows zsh
- [ ] Key tools available:
  - [ ] `nvim --version`
  - [ ] `tmux -V`
  - [ ] `docker --version`
  - [ ] `kubectl version --client`
  - [ ] `git --version`

## IDP Platform Setup (Optional)

- [ ] Prerequisites: `unimart freezer doctor`
- [ ] Install missing tools: `unimart freezer bootstrap`
- [ ] DNS resolution works:
  - [ ] `dig +short gitea.cnoe.localtest.me` returns 127.0.0.1
  - [ ] `dig +short argocd.cnoe.localtest.me` returns 127.0.0.1
- [ ] Start platform: `unimart open`
- [ ] Verify services: `unimart freezer status`

## Git Integration

- [ ] Commit legion-nix configuration:
      ```
      git add cmdr/home/02-hosts/nixos/legion-nix/
      git commit -s -m "feat(legion-nix): add NixOS host configuration"
      ```
- [ ] Push to remote: `git push origin main`
- [ ] DCO sign-off verified (commit has `Signed-off-by:` line)

## Known Issues to Watch For

Reference the "Known Pain Points & Solutions" section in ONBOARDING.md:

- [ ] Shell trampoline working (bash → zsh)
- [ ] DNS resolution for *.cnoe.localtest.me working (if using IDP)
- [ ] No uwsm errors in journal (if adding GUI later)
- [ ] Bluetooth detected (if enabled)
- [ ] Docker socket accessible without sudo

## Testing

- [ ] Reboot and verify clean boot
- [ ] Login shell is zsh without manual intervention
- [ ] All expected tools in PATH
- [ ] Git hooks fire on test commit
- [ ] Docker containers can start: `docker run hello-world`
- [ ] Home Manager generations list: `home-manager generations`

## Documentation

- [ ] Update this checklist with any legion-nix-specific quirks
- [ ] Document hardware-specific issues in ONBOARDING.md
- [ ] Add any new pain points discovered during setup

---

**Last Updated**: 2026-08-31  
**Status**: Initial configuration created, awaiting physical installation

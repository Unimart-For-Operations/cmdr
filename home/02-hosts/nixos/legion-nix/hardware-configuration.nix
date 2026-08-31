# hardware-configuration.nix
#
# ⚠️  DO NOT HAND-WRITE THIS FILE ⚠️
#
# This file must be generated from the running legion-nix system.
#
# To generate this file:
#
#   1. Boot into the legion-nix NixOS installation
#   2. Clone the meta/cmdr repository
#   3. Run from within the cmdr directory:
#
#      sudo nixos-generate-config --show-hardware-config > \
#        home/02-hosts/nixos/legion-nix/hardware-configuration.nix
#
#   4. Commit the generated file alongside meta.nix, default.nix, and system.nix
#
# This file will contain:
#   - Filesystem UUIDs for your specific disks
#   - Boot loader configuration
#   - Kernel modules for your hardware
#   - initrd settings
#   - CPU microcode updates
#   - Swap configuration (if applicable)
#
# See strix-nix/hardware-configuration.nix for an example of what this file
# should look like after generation.

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ ];

  # Placeholder - replace this entire file with nixos-generate-config output
  boot.initrd.availableKernelModules = [ ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/REPLACE-ME";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/REPLACE-ME";
    fsType = "vfat";
  };

  # Uncomment if you have swap
  # swapDevices = [ ];

  # Enable CPU microcode updates (adjust based on your CPU)
  # hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  # hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}

{ config, pkgs, lib, hostMeta, ... }:

{
  # ── Boot ──────────────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ── Networking ────────────────────────────────────────────────
  networking.hostName = "legion-nix";
  networking.networkmanager.enable = true;

  # Local IDP endpoints (idpbuilder runs on this host). The default
  # resolver can't reach *.localtest.me, so route every *.cnoe.localtest.me
  # host to loopback via NetworkManager's dnsmasq plugin. The wildcard
  # covers current endpoints and future scaffolded sandboxes alike
  # (e.g. <name>-terminal.cnoe.localtest.me) without per-host /etc/hosts
  # entries.
  networking.networkmanager.dns = "dnsmasq";
  environment.etc."NetworkManager/dnsmasq.d/idp-localtest.conf".text = ''
    address=/cnoe.localtest.me/127.0.0.1
  '';

  # ── Nix LD (for running non-NixOS binaries) ──────────────────
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      openssl
    ];
  };

  # ── Virtualization ────────────────────────────────────────────
  virtualisation.docker.enable = true;

  # ── System Version ────────────────────────────────────────────
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. Don't change this after installation.
  system.stateVersion = "26.05";
}

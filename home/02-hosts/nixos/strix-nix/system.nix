{ config, pkgs, lib, hostMeta, ... }:

{
  # ── Boot ──────────────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ── NVIDIA RTX 4080 Mobile ────────────────────────────────────
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # ── Hyprland (Wayland compositor) ─────────────────────────────
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # UWSM (Universal Wayland Session Manager) for systemd integration
  environment.systemPackages = with pkgs; [ uwsm ];

  # ── greetd Display Manager (TUI login) ────────────────────────
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd '${pkgs.uwsm}/bin/uwsm start hyprland.desktop'";
        user = "greeter";
      };
    };
  };
  networking.hostName = "strix-nix";
  networking.networkmanager.enable = true;

  # Local IDP endpoints (idpbuilder runs on this host). The default
  # resolver can't reach *.localtest.me, so pin the dev hosts to loopback.
  networking.extraHosts = ''
    127.0.0.1 cnoe.localtest.me gitea.cnoe.localtest.me argocd.cnoe.localtest.me backstage.cnoe.localtest.me docs.cnoe.localtest.me
  '';

  # ── Bluetooth (Intel AX211) ─────────────────────────────────────
  hardware.bluetooth.enable = true;

  # ── ASUS ROG keyboard backlight ─────────────────────────────────
  # LED lives at /sys/class/leds/asus::kbd_backlight (max 3). Grant
  # the video group write access so brightnessctl works without sudo,
  # and restore the last brightness at boot.
  users.users.${hostMeta.username}.extraGroups = [ "video" ];

  services.udev.extraRules = ''
    SUBSYSTEM=="leds", KERNEL=="asus::kbd_backlight", ACTION=="add|change", GROUP="video", MODE="0660"
  '';

  systemd.services.kbd-backlight = {
    description = "Restore ASUS keyboard backlight brightness";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udev-settle.service" ];
    wants = [ "systemd-udev-settle.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -c 'echo 3 > /sys/class/leds/asus::kbd_backlight/brightness'";
    };
  };

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      openssl
    ];
  };

  virtualisation.docker.enable = true;

  system.stateVersion = "26.05";
}

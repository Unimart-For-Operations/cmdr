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
    # The DMS greeter launches the session via uwsm. Nixpkgs' uwsm ships
    # static systemd user units that are only put on the unit search path by
    # programs.uwsm (via withUWSM); without it, uwsm fails with
    # "wayland-session-bindpid@.service ... exit status 5" and login bounces
    # back to the greeter.
    withUWSM = true;
  };

  # ── greetd Display Manager (DMS greeter) ──────────────────────
  services.displayManager.dms-greeter = {
    enable = true;
    compositor.name = "hyprland";

    # Seed the greeter with the primary user's DMS settings, wallpaper state,
    # and generated colors so the login screen matches the live desktop.
    configHome = hostMeta.homeDirectory;
  };

  # This host does not intentionally use passwordless local accounts, so do
  # not permit null-password authentication at the greeter.
  security.pam.services.greetd.allowNullPassword = lib.mkForce false;

  networking.hostName = "strix-nix";
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

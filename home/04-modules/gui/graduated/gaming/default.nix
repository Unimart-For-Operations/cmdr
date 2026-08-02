{ pkgs, ... }:

{
  # Gaming platforms and launchers
  home.packages = with pkgs; [
    # Steam - Primary gaming platform
    steam

    # Lutris - Open gaming platform for managing game libraries
    lutris

    # Wine compatibility layer for running Windows games
    wine
    winetricks

    # ProtonUp-Qt - Manage Proton-GE and other compatibility tools
    protonup-qt

    # GameMode - Optimize system performance for games
    gamemode

    # MangoHud - Vulkan and OpenGL overlay for monitoring FPS, temps, CPU/GPU load
    mangohud

    # Gaming utilities
    gamescope # SteamOS session compositing window manager
  ];

  # Enable GameMode daemon (system-level optimization)
  # Note: This requires the host system to have gamemode enabled in NixOS config
}

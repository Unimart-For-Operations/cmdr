# Docker runtime tooling — stable, required by idpbuilder/unimart freezer
#
# Runtime contract:
#   macOS: Colima provides a Docker daemon in a Lima VM.
#   Linux: Docker Engine is installed/enabled by the OS package manager.
#
# Home Manager installs CLI tooling here. On non-NixOS Linux, it cannot manage
# the rootful docker.service daemon or docker group membership.
{ pkgs, lib, ... }:

let
  bootstrapDockerEngine = pkgs.writeShellApplication {
    name = "cmdr-bootstrap-docker-engine";
    runtimeInputs = with pkgs; [ coreutils ];
    text = ''
      if [ "$(uname -s)" = "Darwin" ]; then
        if ! command -v colima >/dev/null 2>&1; then
          echo "[fail] colima is not on PATH; run unimart deli switch first" >&2
          exit 1
        fi
        colima start
        echo "[pass] Colima Docker daemon is running"
        exit 0
      fi

      if [ -f /etc/NIXOS ]; then
        echo "[fail] NixOS detected; enable virtualisation.docker in the system configuration" >&2
        exit 1
      fi

      if ! command -v systemctl >/dev/null 2>&1; then
        echo "[fail] systemd is required to manage docker.service" >&2
        exit 1
      fi

      if ! command -v docker >/dev/null 2>&1; then
        echo "[fail] Docker CLI is not on PATH; run unimart deli switch first" >&2
        exit 1
      fi

      if ! systemctl list-unit-files docker.service >/dev/null 2>&1; then
        if command -v pacman >/dev/null 2>&1; then
          echo "[fail] Docker Engine is not installed" >&2
          echo "       Arch/CachyOS requires an explicit full system sync before installing new packages." >&2
          echo "       Run this yourself so unrelated upgrades are visible and intentional:" >&2
          echo "" >&2
          echo "         sudo pacman -Syu --needed docker" >&2
          echo "" >&2
          echo "       Then rerun: cmdr-bootstrap-docker-engine" >&2
          exit 1
        elif command -v apt-get >/dev/null 2>&1; then
          sudo apt-get update
          sudo apt-get install -y docker.io
        elif command -v dnf >/dev/null 2>&1; then
          sudo dnf install -y moby-engine
        else
          echo "[fail] unsupported package manager; install Docker Engine with your OS package manager" >&2
          exit 1
        fi
      fi

      echo "[info] enabling and starting docker.service"
      sudo systemctl enable --now docker

      if ! id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
        echo "[info] adding $USER to docker group"
        sudo usermod -aG docker "$USER"
        echo "[warn] added $USER to docker group; log out and back in before running docker without sudo"
      fi

      if docker info >/dev/null 2>&1; then
        echo "[pass] Docker Engine is ready"
      else
        echo "[warn] Docker Engine is running, but this shell may not have docker group membership yet"
        echo "       Log out and back in, then run: docker info"
      fi
    '';
  };
in

{
  home.packages = with pkgs; [
    bootstrapDockerEngine
    docker-client
    docker-compose
    kind
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    colima
  ];
}

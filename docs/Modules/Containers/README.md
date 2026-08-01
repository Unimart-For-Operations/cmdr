---
source: idpbuilder-org
synced: 2026-03-30
---
# Container Testing Environment

This directory contains Docker Compose configuration for testing the Dev Control Plane in an isolated Ubuntu Linux environment.

## Purpose

The container provides a safe, reproducible environment to:
- Test Nix configurations without affecting your host system
- Validate cross-platform compatibility (Linux target)
- Practice deployment workflows
- Iterate on Home Manager configs safely
- Debug issues in a clean environment

## Philosophy: Distro-Agnostic Testing

This container uses **Ubuntu 24.04 LTS** rather than any specific distro because:

1. **"The distro is arbitrary"** - When using Nix + Home Manager, the underlying Linux distribution shouldn't matter
2. **Apple Silicon compatibility** - Ubuntu works cleanly on ARM Macs without emulation issues
3. **Cross-platform validation** - Proves your configs work on *any* Linux distro
4. **Deployment practice** - Tests the workflow you'll use on real hardware later

Your actual target hardware may be Arch/CachyOS, but the container validates that **Nix configs are truly portable**.

## Prerequisites

Docker CLI and Kind are managed by Home Manager via `home/04-modules/cli/graduated/containerization/default.nix`.

The Docker daemon must be running before using containers:

```bash
cmdr-bootstrap-docker-engine
docker info
```

## Quick Start

### From Repository Root

```bash
# Automated smoke test: build, provision, verify, teardown (Linux only)
make test-run

# Provision a specific cli/tui host (default: cmdr)
make test-run HOST=<name>

# Build and start container (Linux only, keep it running)
make test

# Enter interactive shell (Linux only)
make test-shell

# Provision config and drop into an interactive zsh (Linux only)
make test-tty

# Clean up completely (Linux only)
make test-clean
```

`make test-run` is the CI-friendly entry point — it runs non-interactively,
asserts on every step, and exits non-zero on failure. It is wired into
`make ci-full` (the `make ci` static gate plus the container test).

**Host selection:** `test-run`/`test-tty` default to the `cmdr` host because it
is cli+tui only and activates cleanly headless. GUI/desktop hosts (e.g.
`strix-nix`) pull in Hyprland/DMS and should not be activated in a container.
Override with `HOST=<name>` or `TEST_HOST=<name>`.

**macOS Note:** Container tests are blocked on macOS due to emulation limitations (QEMU seccomp issues with Nix sandbox). These tests are designed for native Linux systems only — including bare-metal NixOS hosts, where the Docker engine is managed via `virtualisation.docker.enable = true` in the host's `system.nix`.

### From This Directory

```bash
# Build and start
docker compose -f compose.yml up --build

# Run interactive shell
docker compose -f compose.yml run --rm linux-test /bin/bash

# Stop
docker compose -f compose.yml down

# Clean up with volumes
docker compose -f compose.yml down -v
```

## Container Details

- **Base Image:** `docker.io/library/ubuntu:24.04`
- **User:** `nixuser` (uid 1000, non-root with sudo)
- **Nix:** Installed on first run via Determinate Nix (`--init none`)
- **Mounts:** cmdr repo at `/workspace` (read-only), parent meta repo at `/meta` (read-only)
- **Working Dir:** `/home/nixuser`
- **Platform:** `linux/amd64`

The meta repo is mounted (not fetched over `git+ssh`) because the container's
Determinate Nix bundles a different libgit2 than host nix: a fresh `git+ssh`
fetch recomputes the `meta` input's narHash and can mismatch the value pinned
in `flake.lock`. `make test-run` instead overrides the input to a local copy
(`--override-input meta /tmp/meta-src`) and exports it with `git archive` so
submodule content (e.g. the `idpbuilder` module) is excluded exactly like nix's
own git fetcher.

## Usage Examples

### Test the Development Shell

```bash
# Enter container
make test-shell

# Inside container
cd /workspace
nix develop

# You now have all dev tools available (home-manager, nixpkgs-fmt, etc.)
```

### Test Nix Flake Commands

```bash
# Inside container
cd /workspace

# Check flake
nix flake check

# Show flake metadata
nix flake show

# Format code
nix fmt
```

### Test Home Manager Activation

```bash
# Inside container
cd /workspace

# Apply Linux profile
home-manager switch --flake .#cmdr

# Verify packages installed
which ripgrep fzf bat

# Test shell configuration
zsh -c 'echo $EDITOR'
```

## Architecture

```
Host Machine (CachyOS / macOS)
    │
    ├─ dev-control-plane/ (repo)
    │   ├─ flake.nix
    │   ├─ home/ (Home Manager configs)
    │   └─ containers/
    │       ├─ Dockerfile
    │       └─ compose.yml
    │
    └─ Podman (rootless)
        └─ Container: Ubuntu 24.04
            ├─ Nix installed on first run
            ├─ /workspace → repo (read-only)
            └─ User: nixuser
```

## Troubleshooting

### Container won't start

```bash
# Ensure Docker is running
systemctl status docker

# Clean rebuild
make test-clean
make test
```

### Docker daemon unavailable

If `docker compose` cannot connect to the daemon, start Docker Engine on Linux:

```bash
sudo systemctl enable --now docker
```

### Nix commands fail inside container

```bash
# Verify Nix is in PATH
which nix

# If not found, source Nix profile
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

### Can't modify files

The workspace is mounted read-only by design. Edit files on your host machine.

## Workflow: Deploy to Real Hardware

Once you've validated configs in the container:

1. **Test locally:** Use container to iterate quickly
2. **Validate:** Ensure `home-manager switch --flake .#cmdr` works
3. **Deploy:** Copy flake to real Linux machine
4. **Apply:** Run same command on real hardware
5. **Success:** Configs work identically because Nix guarantees reproducibility

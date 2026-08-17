# NixOS Host Bootstrap — Acceptance Criteria

Scope: onboarding of a new NixOS host via the streamlined flow. Does not cover
host drift or maintenance (see unimart deli switch/doctor).

## Entry
- [ ] A NixOS host is installed via the OS installer (partition, encrypt,
      bootloader, initial user) before the flow runs — see `unimart deli plan`.
- [ ] Nix is already part of the OS; the flow does not install it.
- [ ] A single command completes onboarding:
      `curl -fsSL https://raw.githubusercontent.com/Unimart-For-Operations/meta/main/scripts/provision.sh | bash`
- [ ] The one-liner requires no pre-existing SSH key and no installed toolchain.

## Flow invariants
- [ ] The flow skips the Nix install step on NixOS (sources the OS profile
      instead) — no `exec zsh` + re-run interruption.
- [ ] The repo clones over HTTPS (org public); SSH is only needed for the final push.
- [ ] `nix run .#unimart -- deli bootstrap` builds unimart from the flake — Go
      is never required on the host.
- [ ] No make target is invoked during bootstrap.
- [ ] Apply runs `nixos-rebuild switch --flake` (sudo), routing through the
      NixOS output per `flake.nix`.

## Registration
- [ ] The user is prompted (in Go) only for host-specific values — gitName,
      gitEmail, and features/role.
- [ ] Auto-detected values (name, system, username, homeDirectory, theme) are
      shown for confirmation before writing.
- [ ] `hardware-configuration.nix` is captured on the machine
      (`nixos-generate-config`) and committed alongside the host.
- [ ] `meta.nix`, `system.nix`, and `hardware-configuration.nix` are written to
      `home/02-hosts/nixos/<hostname>/` and match the existing schema (see
      `nixos/strix-nix/`).
- [ ] cmdr still passes `nix flake check` with the new host registered.

## Final step
- [ ] The only manual action at the end is `git push` of the new host directory.

## Idempotency
- [ ] Re-running the one-liner on an already-bootstrapped host is a safe no-op.

## Verification
- [ ] A container-based smoke test exercises the pure-Nix path end-to-end
      (`provision.sh` → `nix run .#unimart -- deli bootstrap`).

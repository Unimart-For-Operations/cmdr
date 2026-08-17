# Ubuntu Host Bootstrap — Acceptance Criteria

Scope: onboarding of a new Ubuntu host via the streamlined flow. Does not cover
host drift or maintenance (see unimart deli switch/doctor).

## Entry
- [ ] A freshly-installed Ubuntu host needs only `sudo apt install git curl`
      before running the flow (desktop images usually ship both already).
- [ ] A single command completes onboarding:
      `curl -fsSL https://raw.githubusercontent.com/Unimart-For-Operations/meta/main/scripts/provision.sh | bash`
- [ ] The one-liner requires no pre-existing SSH key, no sudo, and no installed toolchain.

## Flow invariants
- [ ] Nix installs via the Determinate installer and is sourced in-process —
      no `exec zsh` + re-run interruption.
- [ ] The repo clones over HTTPS (org public); SSH is only needed for the final push.
- [ ] `nix run .#unimart -- deli bootstrap` builds unimart from the flake — Go
      is never required on the host.
- [ ] No make target is invoked during bootstrap.

## Registration
- [ ] The user is prompted (in Go) only for host-specific values — gitName,
      gitEmail, and features/role.
- [ ] Auto-detected values (name, system, username, homeDirectory, theme) are
      shown for confirmation before writing.
- [ ] `meta.nix` is written to `home/02-hosts/ubuntu/<hostname>/` and matches the
      existing schema (see the `_template/meta.nix` reference).
- [ ] cmdr still passes `nix flake check` with the new host registered.

## Final step
- [ ] The only manual action at the end is `git push` of the new host directory.

## Idempotency
- [ ] Re-running the one-liner on an already-bootstrapped host is a safe no-op.

## Verification
- [ ] A container-based smoke test exercises the pure-Nix path end-to-end
      (`provision.sh` → `nix run .#unimart -- deli bootstrap`).

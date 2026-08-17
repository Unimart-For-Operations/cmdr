# macOS Host Bootstrap — Acceptance Criteria

Scope: onboarding of a new macOS host via the streamlined flow. Does not cover
host drift or maintenance (see unimart deli switch/doctor).

## Entry
- [ ] A freshly-installed macOS host needs no manual prep — `curl`, `bash`, and
      git are available via Xcode Command Line Tools, which the flow installs.
- [ ] A single command completes onboarding:
      `curl -fsSL https://raw.githubusercontent.com/Unimart-For-Operations/meta/main/scripts/provision.sh | bash`
- [ ] The one-liner requires no pre-existing SSH key and no installed toolchain.

## Flow invariants
- [ ] Xcode Command Line Tools, Homebrew, and Nix are installed by cmdr's
      `bootstrap.sh`; admin consent prompts are handled in-process and the
      script waits for Xcode CLT to finish installing.
- [ ] Nix is sourced in-process — no `exec zsh` + re-run interruption.
- [ ] The repo clones over HTTPS (org public); SSH is only needed for the final push.
- [ ] `nix run .#unimart -- deli bootstrap` builds unimart from the flake — Go
      is never required on the host.
- [ ] No make target is invoked during bootstrap.
- [ ] First-time apply bootstraps nix-darwin (`darwin-rebuild switch --flake`),
      including the documented `/etc/bashrc` move.

## Registration
- [ ] The user is prompted (in Go) only for host-specific values — gitName,
      gitEmail, and features/role.
- [ ] Auto-detected values (name, system, username, homeDirectory, theme) are
      shown for confirmation before writing.
- [ ] `meta.nix` is written to `home/02-hosts/macos/<hostname>/` and matches the
      existing schema (see `macos/apple-macbook-m3-pro/meta.nix`).
- [ ] cmdr still passes `nix flake check` with the new host registered.

## Final step
- [ ] The only manual action at the end is `git push` of the new host directory.

## Idempotency
- [ ] Re-running the one-liner on an already-bootstrapped host is a safe no-op.

## Verification
- [ ] A container-based smoke test exercises the pure-Nix path end-to-end
      (`provision.sh` → `nix run .#unimart -- deli bootstrap`).

---
source: idpbuilder-org
synced: 2026-03-30
---
# Roadmap

**Current status of cmdr's structural evolution and future plans.**

---

## Tier Migration v1 -- Complete

The first major structural initiative reorganized `home/04-modules/` with CNCF-style adoption tiers, a global theme system, and broad code cleanup. The full original plan is preserved in [tier-migration-v1.md](tier-migration-v1.md).

### What Was Done

**Phase 1: Foundation (Deduplication + Theme System)**
- Created `_shared/theme/` with Catppuccin Frappe palette, semantic colors, fonts, and per-tool theme names
- Added a comprehensive Theme System reference: `docs/Reference/theme.md` describing the switchboard, semantic layers, palette contract, and usage examples
- Updated visual consumers to import from the shared theme (starship, opencode, ghostty, kitty, alacritty, tmux, nixvim, k9s)
- Deduplicated eza `--ignore-glob` string, removed duplicate `terraform-ls` and `copy-on-select`, cleaned unused function parameters

**Phase 2: Tier Restructure**
- Moved all 33 modules into `graduated/`, `incubating/`, or `sandbox/` tier directories via `git mv`
- Created new `cli.nix` and `tui.nix` feature files; updated `gui.nix`
- Extended host discovery engine with feature map, desktop paths, and sandbox opt-in support
- Updated all host `meta.nix` files and the `_template`

**Phase 3: Cleanup, Polish & Tooling**
- Deleted dead code (`terminal.nix`, `languages.nix`, `cloud.nix`, `scripts/docs-split-plan.sh`)
- Makefile: extracted `LINUX_GUARD`, renamed `tty` to `test-tty`, added `make tiers` and `make promote`
- Fixed hardcoded values: UPMC SSH `user`, git email, `GITLAB_USER` -- all now use `hostMeta.username`
- Migrated UPMC shell functions from xdg glob pattern to `programs.zsh.initContent`
- Rewrote `docs/README.md` (removed 30 broken links, updated for tier system)
- Restored powerline glyphs stripped during theme migration (rounded style: U+E0B6 / U+E0B4)

**Post-Plan: CLI Module Promotions**
- Promoted 4 modules from incubating/sandbox to graduated: azure, python, opencode, pulumi
- Removed pulumi from sandbox map (only wezterm remains in sandbox)

### Current Tier Counts

| Tier | Count | Modules |
|------|-------|---------|
| **CLI Graduated** | 20 | atuin, aws, azure, bat, containerization, core-utils, direnv, eza, fonts, fzf, git, go, opencode, pulumi, python, ssh, starship, terraform, zoxide, zsh |
| **TUI Graduated** | 4 | lazygit, nvim, tmux, yazi |
| **TUI Incubating** | 2 | k9s, sesh |
| **GUI Graduated** | 3 | dms, ghostty, hyprland |
| **GUI Incubating** | 2 | alacritty, kitty |
| **GUI Sandbox** | 1 | wezterm |

### Remaining (Low Priority)

- **Module metadata comment headers** -- structured `# Tier: / Category: / Since: / Description:` headers for every module's `default.nix`. Cosmetic; deferred indefinitely.

---

## Milestone: Stable Zsh Baseline

Zsh is now functionally stable for daily use across core workflows.

### What is solid

- Reliable startup and shell behavior
- Core aliases, functions, and scripts working as expected
- No known blockers for regular interactive use

### Known debt

- Prompt/theme/UI is still rough
- Visual consistency and polish are below target
- Ergonomics still need cleanup (spacing, colors, information density)

### Next focus

Polish shell UX without destabilizing the current baseline.

---

## Future: IDP Integration

cmdr is the first component of a larger platform engineering effort. A full analysis of the target platform is available in [idpbuilder-analysis.md](idpbuilder-analysis.md).

1. **cmdr** stays tightly scoped as a development-first workstation provisioner
2. An **IDP (Internal Developer Platform)** repo will be built around the CNOE IDP Builder stack (ArgoCD, Gitea, Backstage, Crossplane, Argo Workflows, External Secrets, Keycloak)
3. **cmdr will be absorbed** into the IDP's Gitea instance as a self-contained component
4. The IDP will manage: developer environments, cloud compute, platform infrastructure, CI/CD runners, and developer platform services

The tier system and clean category structure make cmdr a well-defined component ready for that absorption without structural changes. Graduated modules represent the stable API surface.

### What cmdr Does Not Manage

These belong in the future IDP repo, not here:
- Platform infrastructure (Kubernetes clusters, ArgoCD, Gitea)
- Cloud resources (VPCs, EC2 instances, S3 buckets)
- CI/CD pipelines or runners
- Observability stack (Prometheus, Grafana)
- Security tooling (Vault, OPA, Trivy)
- Developer portal (Backstage)

---

## Potential Future Work

Items that may be addressed in future iterations:

- **Theme switching** -- Create additional palette files (e.g., `tokyo-night.nix`) and switch via `default.nix`; all consumers update automatically
- **Automated promotion criteria** -- Encode promotion rules (usage duration, stability) into `make promote`
- **Nix module options** -- Convert tier metadata into proper NixOS module options for machine-readable introspection
- **docs/ cleanup** -- Several architecture sub-documents referenced but not yet written (`philosophy.md`, `layering.md`, `discovery.md`, `evaluation-flow.md`, `first-host.md`)

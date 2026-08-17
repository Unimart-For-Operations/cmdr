# Tier Migration v1 -- Original Plan (Historical Reference)

**Date:** 2026-03-22
**Status:** Complete (with deviations noted below)
**Scope:** Restructure `home/04-modules/` with CNCF-style adoption tiers, global theme system, code deduplication, and general polish to prepare cmdr for IDP integration.

> **Note:** This document preserves the original migration plan as written before implementation. The plan was fully executed with the following deviations from the original tier assignments:
>
> - **opencode** -- planned as Incubating, promoted to Graduated during implementation
> - **python** -- planned as Incubating, promoted to Graduated during implementation
> - **azure** -- planned as Incubating, promoted to Graduated during implementation
> - **pulumi** -- planned as Sandbox, promoted to Graduated during implementation
> - **Task 2.8** (module metadata headers) -- deferred indefinitely as cosmetic
> - **Task 3.3** (`platform-linux.nix`) -- confirmed as a valid stub, not dead code; kept as-is
> - **Task 3.10** (sesh dotfiles path) -- not addressed
> - **Task 3.13** (CI workflows) -- already deleted, no paths to update
>
> Final tier counts: 26 graduated, 5 incubating, 1 sandbox (wezterm only), 1 work.
> See [Roadmap README](README.md) for current state.

---

*The original plan follows unmodified below.*

---

## 1. Background & Context

### 1.1 What is cmdr?

cmdr is a declarative, reproducible development environment management system built with Nix flakes, Home Manager, and nix-darwin. It provisions macOS and Linux developer workstations from a single codebase using a layered module architecture:

```
home/
├── 01-platforms/     # OS-level settings (darwin vs linux)
├── 02-hosts/         # Host discovery engine + per-host metadata
├── 03-features/      # Feature groups that compose modules
└── 04-modules/       # Leaf modules (actual packages + config)
    ├── cli/          # 20 command-line tool modules
    ├── tui/          # 6 terminal UI modules
    ├── gui/          # 6 graphical application modules
    └── work/         # 1 employer-specific config module (UPMC)
```

The system manages 4 hosts across 2 platforms:
- **apple-studio-m2-max** (macOS, personal)
- **apple-macbook-m3-pro** (macOS, work/UPMC)
- **cmdr** (Arch Linux, TTY-only)
- **cachyos** (CachyOS/Arch Linux, full Hyprland desktop)

### 1.2 The Bigger Picture

cmdr is the beginning of a larger platform engineering effort. The long-term vision is:

1. **cmdr** stays tightly scoped as a development-first workstation provisioner
2. An **IDP (Internal Developer Platform)** repo will be built around the CNOE IDP Builder stack (ArgoCD, Gitea, Backstage, Crossplane, Argo Workflows, External Secrets, Keycloak)
3. **cmdr will be absorbed** into the IDP's Gitea instance and managed as a self-contained component within the larger platform
4. The IDP will eventually manage: developer environments, cloud compute instances, platform infrastructure, CI/CD runners, and developer platform services

This migration plan prepares cmdr to be a clean, well-organized, self-contained component ready for that absorption.

---

## 2. How This Plan Evolved

### 2.1 Initial Request

The conversation started with a request to "refine the tooling in modules." Through iterative questioning, the goals crystallized:

1. **Standardize** the module system with a formal adoption lifecycle
2. **Mirror the CNCF adoption tiers** (Sandbox, Incubating, Graduated)
3. **Create a dedicated area for evaluating tools** before committing to them
4. **Apply across all module categories** (cli, tui, gui)

### 2.2 Scope Expansion: IDP Vision

The scope expanded when the broader platform engineering vision was shared. Initial designs included categories for `platform/`, `security/`, and `observability/` modules. However, after discussion, the decision was made to:

- **Keep cmdr workstation-scoped** -- it is not the IDP itself
- **Retain the cli/tui/gui category structure** -- it's intuitive and maps to how developers think about tools
- **Defer platform/security/observability** to the future IDP repo
- **Ensure cmdr is clean and self-contained** for eventual IDP absorption

### 2.3 Feature File Design

The feature file strategy evolved through several options:

- **Option A:** Keep `terminal.nix` (imports cli + tui) + `gui.nix` -- minimal disruption
- **Option B:** Create `cli.nix` + `tui.nix` + `gui.nix` matching categories exactly
- **Option C:** Single `developer.nix` feature for everything

**Decision: Option B** was chosen because it supports different host profiles:
- **Slim TTY profile:** `features = [ "cli" "tui" ]` (no display server)
- **Full desktop profile:** `features = [ "cli" "tui" "gui" ]` (macOS or Wayland)

### 2.4 Theme System

What started as "extract the duplicated Catppuccin Frappe hex values" evolved into a proper **global theme system** that controls:
- Color palette (all Catppuccin Frappe hex values)
- Semantic color mappings (bg, fg, accent, error, success, etc.)
- Font families and sizes per context (terminal, editor, UI)
- Per-tool theme name strings (for tools with named theme support)
- Icon/symbol preferences (Nerd Font, powerline)

The theme module lives outside the tier system at `home/04-modules/_shared/theme/` as cross-cutting infrastructure.

### 2.5 Cleanup Audit

A thorough audit of the codebase identified cleanup opportunities that were folded into the plan:

| Priority | Issue |
|----------|-------|
| High | Catppuccin Frappe palette hardcoded in 7+ files |
| High | 30 broken documentation links |
| High | Legacy UPMC shell function deployment pattern pending migration |
| Medium | Duplicate `terraform-ls` in two modules |
| Medium | `eza --ignore-glob` string repeated 7 times |
| Medium | Font name hardcoded across 3 terminal emulator configs |
| Medium | `user = "mortimera"` hardcoded in 10 SSH blocks |
| Medium | Makefile: 4 test targets with identical macOS rejection boilerplate |
| Medium | Makefile: 8 host shortcuts requiring manual maintenance |
| Medium | Dead code: `scripts/docs-split-plan.sh`, empty `platform-linux.nix` |
| Low | Duplicate `copy-on-select` in ghostty config |
| Low | Unused function parameters in several modules |
| Low | Inconsistent `sessionVariables` mechanisms |

---

## 3. The Tier System

### 3.1 Tier Definitions

Modeled on the CNCF project lifecycle:

| Tier | Meaning | Behavior |
|------|---------|----------|
| **Graduated** | Battle-tested, core to the workflow | Auto-included by feature files |
| **Incubating** | In active use, gaining confidence | Auto-included by feature files (noted as maturing) |
| **Sandbox** | Evaluating, experimental, may be removed | **Opt-in per host** via `sandbox = [...]` in `meta.nix` |

### 3.2 Directory Structure

```
home/04-modules/
├── _shared/
│   └── theme/
│       ├── default.nix                  # Exports the active theme
│       └── palettes/
│           └── catppuccin-frappe.nix    # Current active palette
│
├── cli/
│   ├── graduated/
│   │   ├── core-utils/
│   │   ├── git/
│   │   ├── zsh/
│   │   ├── starship/
│   │   ├── atuin/
│   │   ├── direnv/
│   │   ├── fzf/
│   │   ├── zoxide/
│   │   ├── bat/
│   │   ├── eza/
│   │   ├── ssh/
│   │   ├── fonts/
│   │   ├── aws/
│   │   ├── terraform/
│   │   └── kubernetes/
│   ├── incubating/
│   │   ├── opencode/
│   │   ├── python/
│   │   ├── containers/
│   │   └── azure/
│   └── sandbox/
│       └── pulumi/
│
├── tui/
│   ├── graduated/
│   │   ├── tmux/
│   │   ├── nvim/
│   │   ├── lazygit/
│   │   └── yazi/
│   ├── incubating/
│   │   ├── sesh/
│   │   └── k9s/
│   └── sandbox/
│
├── gui/
│   ├── graduated/
│   │   ├── ghostty/
│   │   ├── hyprland/
│   │   └── dms/
│   ├── incubating/
│   │   ├── kitty/
│   │   └── alacritty/
│   └── sandbox/
│       └── wezterm/
│

```

### 3.3 Module Metadata Headers

Every module's `default.nix` gets a structured header:

```nix
# ── Module: git ──────────────────────────────────────────────────────────
# Tier:        graduated
# Category:    cli
# Since:       2024-01-01
# Description: Git configuration, commit template, and companion tools
# ─────────────────────────────────────────────────────────────────────────
```

### 3.4 Feature Files

Three category-aligned feature files replace the previous four:

**`home/03-features/cli.nix`** -- all CLI graduated + incubating modules
**`home/03-features/tui.nix`** -- all TUI graduated + incubating modules
**`home/03-features/gui.nix`** -- all GUI graduated + incubating modules (+ Obsidian)

Sandbox modules are **never** imported by feature files.

### 3.5 Host Discovery Engine Changes

The `home/02-hosts/default.nix` engine is extended with:

1. **Updated feature map:**
   ```nix
   featureModules = {
     cli = ../03-features/cli.nix;
     tui = ../03-features/tui.nix;
     gui = ../03-features/gui.nix;
   };
   ```

2. **Updated desktop module paths:**
   ```nix
   desktopModules = {
     hyprland = ../04-modules/gui/graduated/hyprland;
     dms      = ../04-modules/gui/graduated/dms;
   };
   ```

3. **New sandbox module resolution:**
   ```nix
   sandboxModules = {
     pulumi  = ../04-modules/cli/sandbox/pulumi;
     wezterm = ../04-modules/gui/sandbox/wezterm;
   };
   ```

4. **New `sandbox` key** in `meta.nix`:
   ```nix
   {
     # ...existing fields...
     sandbox = [ "pulumi" "wezterm" ];  # opt-in sandbox modules
   }
   ```

5. **Updated module load order:**
   ```
   [1] 03-features/base.nix
   [2] 01-platforms/{darwin,linux}.nix
   [3] feature modules (cli, tui, gui)
   [4] desktop modules (hyprland, dms)
   [5] sandbox modules (opt-in per host)
   [6] host-specific overrides (default.nix)
   ```

### 3.6 Updated meta.nix Files

```nix
# apple-studio-m2-max (macOS personal desktop)
{
  description = "Mac Studio M2 Max (cmdr)";
  system = "aarch64-darwin";
  username = "cmdr";
  homeDirectory = "/Users/cmdr";
  features = [ "cli" "tui" "gui" ];
}

# apple-macbook-m3-pro (macOS laptop)
{
  description = "MacBook Pro M3 Pro (mortimera)";
  system = "aarch64-darwin";
  username = "mortimera";
  homeDirectory = "/Users/mortimera";
  features = [ "cli" "tui" "gui" ];
}

# arch/cmdr (TTY-only -- no gui feature)
{
  description = "cmdr -- Arch Linux primary workstation";
  system = "x86_64-linux";
  username = "cmdr";
  homeDirectory = "/home/cmdr";
  features = [ "cli" "tui" ];
}

# arch/cachyos (full desktop with Hyprland)
{
  description = "CachyOS workstation";
  system = "x86_64-linux";
  username = "cmdr";
  homeDirectory = "/home/cmdr";
  features = [ "cli" "tui" "gui" ];
  desktop = [ "hyprland" "dms" ];
}
```

---

## 4. Global Theme System

### 4.1 Architecture

```
home/04-modules/_shared/theme/
├── default.nix                    # Switchboard: imports the active palette
└── palettes/
    └── catppuccin-frappe.nix      # Full theme definition
```

### 4.2 Theme Attrset Shape

```nix
{
  # ── Identity ──
  name = "catppuccin-frappe";
  variant = "frappe";
  style = "dark";

  # ── Colors ──
  palette = {
    rosewater = "#f2d5cf"; flamingo = "#eebebe"; pink = "#f4b8e4";
    mauve = "#ca9ee6"; red = "#e78284"; maroon = "#ea999c";
    peach = "#ef9f76"; yellow = "#e5c890"; green = "#a6d189";
    teal = "#81c8be"; sky = "#99d1db"; sapphire = "#85c1dc";
    blue = "#8caaee"; lavender = "#babbf1";
    text = "#c6d0f5"; subtext1 = "#b5bfe2"; subtext0 = "#a5adce";
    overlay2 = "#949cbb"; overlay1 = "#838ba7"; overlay0 = "#737994";
    surface2 = "#626880"; surface1 = "#51576d"; surface0 = "#414559";
    base = "#303446"; mantle = "#292c3c"; crust = "#232634";
  };

  # ── Semantic mappings ──
  semantic = {
    bg = "#303446"; fg = "#c6d0f5"; accent = "#ca9ee6";
    warn = "#e5c890"; error = "#e78284"; success = "#a6d189";
    info = "#8caaee"; muted = "#737994"; border = "#51576d";
    selection = "#414559"; cursor = "#f2d5cf";
  };

  # ── Fonts ──
  fonts = {
    mono   = { family = "FiraCode Nerd Font Mono"; size = 13; };
    sans   = { family = "Inter"; size = 13; };
    serif  = { family = "Liberation Serif"; size = 13; };
    editor = { family = "FiraCode Nerd Font Mono"; size = 13; };
    term   = { family = "FiraCode Nerd Font Mono"; size = 13; };
  };

  # ── Per-tool theme names ──
  toolThemes = {
    bat = "TwoDark";
    lazygit = "catppuccin-frappe";
    k9s = "catppuccin-frappe";
    starship = "catppuccin-frappe";
    nvim = "catppuccin-frappe";
    tmux = "catppuccin";
  };

  # ── Icons/Symbols ──
  icons = {
    powerline = true;
    nerdFont = true;
    separatorLeft = "";
    separatorRight = "";
  };
}
```

### 4.3 Consumption Pattern

Modules import the theme and reference its values:

```nix
{ pkgs, ... }:
let
  theme = import ../../_shared/theme;
in
{
  programs.ghostty.settings = {
    font-family = theme.fonts.term.family;
    font-size = theme.fonts.term.size;
    background = theme.palette.base;
    foreground = theme.palette.text;
  };
}
```

### 4.4 Theme Switching (Future)

To switch themes: create a new palette file (e.g., `palettes/tokyo-night.nix`) with the same attrset shape, then change `default.nix` to import it. All modules update automatically on rebuild.

---

## 5. Implementation Plan

### Phase 1: Foundation (Deduplication + Theme System)

Do this first because it fixes the duplication that would make directory moves messy.

| # | Task | Priority | Files Affected |
|---|------|----------|----------------|
| 1.1 | Create `_shared/theme/` with Catppuccin Frappe palette | High | New files |
| 1.2 | Update all 7+ visual consumers to import from shared theme | High | starship, opencode, ghostty, kitty, alacritty, tmux, nixvim |
| 1.3 | Extract `darwinIgnore` variable in zsh eza aliases | Medium | `cli/zsh/default.nix` |
| 1.4 | Remove duplicate `terraform-ls` from `nvim/lsp-tools.nix` | Medium | `tui/nvim/lsp-tools.nix` |
| 1.5 | Remove duplicate `copy-on-select` in ghostty | Low | `gui/ghostty/default.nix` |
| 1.6 | Clean unused function parameters | Low | `gui.nix`, `fonts/default.nix` |

### Phase 2: Tier Restructure (The Big Move)

The core structural change. This is the largest phase.

| # | Task | Priority | Details |
|---|------|----------|---------|
| 2.1 | Create tier subdirectories | High | `graduated/`, `incubating/`, `sandbox/` under cli/, tui/, gui/ |
| 2.2 | Move all 33 modules into assigned tier directories | High | See tier assignments in section 3.2 |
| 2.3 | Create `cli.nix`, `tui.nix` feature files | High | Replace terminal.nix, languages.nix, cloud.nix |
| 2.4 | Update `gui.nix` with new paths | High | Point to graduated/incubating subdirectories |
| 2.5 | Update host discovery engine | High | New feature map, desktop paths, sandbox support |
| 2.6 | Update all `meta.nix` files | High | New feature names: cli, tui, gui |
| 2.7 | Update `_template/meta.nix` | High | Add sandbox example |
| 2.8 | Add metadata headers to every module | Medium | Tier, category, since date, description |
| 2.9 | Delete old empty directories | Low | Remove vacated cli/, tui/, gui/ flat dirs |

### Phase 3: Cleanup, Polish & Tooling

Final sweep to clean up technical debt and add operational tooling.

| # | Task | Priority | Details |
|---|------|----------|---------|
| 3.1 | Migrate UPMC shell functions to `programs.zsh.initContent` | Medium | Remove the glob shim in zsh module |
| 3.2 | Delete `scripts/docs-split-plan.sh` | Medium | Dead planning script |
| 3.3 | Clean module-specific platform variants | Medium | Remove dead files or populate placeholders |
| 3.4 | Makefile: extract macOS rejection boilerplate | Medium | 4 test targets share identical message |
| 3.5 | Makefile: address host shortcut maintenance | Medium | 8 targets require manual updates per host |
| 3.6 | Makefile: rename `tty` to `test-tty` | Medium | Naming consistency |
| 3.7 | Add `make tiers` reporting target | Medium | Script that scans tier directories and prints table |
| 3.8 | Add `make promote` target | Medium | Moves module between tiers, updates imports |
| 3.9 | Fix hardcoded `ss` alias path | Medium | Guard behind conditional or move to platform-specific module |
| 3.10 | Fix hardcoded sesh dotfiles path | Medium | Make configurable |
| 3.11 | Extract UPMC SSH `user = "mortimera"` | Medium | Variable at top of file |
| 3.12 | Fix/remove 30 broken links in `docs/README.md` | Medium | Either create files or remove links |
| 3.13 | Update CI workflows for new paths | Low | `.github/workflows/linux-container-test.yml` |

### Validation

After each phase:
- Run `nix flake check --all-systems`
- For macOS host: `make switch HOST=apple-studio-m2-max` (dry run with `make diff`)
- Review `git diff` to verify all import paths resolve correctly

---

## 6. Tier Assignments (Complete Reference)

### CLI Modules

| Module | Current Location | New Tier | Rationale |
|--------|-----------------|----------|-----------|
| core-utils | cli/ | **Graduated** | Foundation utilities, no config needed |
| git | cli/ | **Graduated** | Core dev tool, stable config |
| zsh | cli/ | **Graduated** | Primary shell, extensively configured |
| starship | cli/ | **Graduated** | Prompt, stable and themed |
| atuin | cli/ | **Graduated** | Shell history, stable |
| direnv | cli/ | **Graduated** | Environment switching, stable |
| fzf | cli/ | **Graduated** | Fuzzy finder, stable |
| zoxide | cli/ | **Graduated** | Smart cd, stable |
| bat | cli/ | **Graduated** | cat replacement, stable |
| eza | cli/ | **Graduated** | ls replacement, stable |
| ssh | cli/ | **Graduated** | SSH config, stable |
| fonts | cli/ | **Graduated** | Font packages, stable |
| aws | cli/ | **Graduated** | AWS CLI, daily use, stable |
| terraform | cli/ | **Graduated** | IaC CLI, daily use |
| kubernetes | cli/ | **Graduated** | kubectl + companions, daily use |
| opencode | cli/ | **Incubating** | AI coding agent, newer addition |
| python | cli/ | **Incubating** | Python via uv, still evolving |
| containers | cli/ | **Incubating** | Rootless Podman, usage growing |
| azure | cli/ | **Incubating** | Azure CLI, less frequent use |
| pulumi | cli/ | **Sandbox** | Alternative IaC, evaluating |

### TUI Modules

| Module | Current Location | New Tier | Rationale |
|--------|-----------------|----------|-----------|
| tmux | tui/ | **Graduated** | Terminal multiplexer, core workflow |
| nvim | tui/ | **Graduated** | Primary editor, extensively configured |
| lazygit | tui/ | **Graduated** | Git TUI, daily use |
| yazi | tui/ | **Graduated** | File manager, daily use |
| sesh | tui/ | **Incubating** | Tmux session manager, newer |
| k9s | tui/ | **Incubating** | K8s TUI, usage varies |

### GUI Modules

| Module | Current Location | New Tier | Rationale |
|--------|-----------------|----------|-----------|
| ghostty | gui/ | **Graduated** | Primary terminal emulator |
| hyprland | gui/ | **Graduated** | Primary Wayland compositor |
| dms | gui/ | **Graduated** | Desktop shell theme, fully integrated |
| kitty | gui/ | **Incubating** | Secondary terminal, backup |
| alacritty | gui/ | **Incubating** | Secondary terminal, backup |
| wezterm | gui/ | **Sandbox** | Minimal config, evaluating |

---

## 7. Promotion Workflow

### Criteria for Promotion

**Sandbox -> Incubating:**
- Tool has been used regularly for 2+ weeks
- Configuration is non-trivial (not just a package install)
- No known issues blocking daily use
- Committed to continued evaluation

**Incubating -> Graduated:**
- Tool has been in daily use for 1+ month
- Configuration is stable (no frequent changes)
- Integrated with other graduated tools (theme, shell, etc.)
- Would cause workflow disruption if removed

**Demotion (any tier -> Sandbox or removal):**
- Tool is no longer being used
- Superseded by a better alternative
- Configuration maintenance burden outweighs value

### Promotion Process

```bash
# Promote a module
make promote MODULE=sesh TO=graduated

# This will:
# 1. Move home/04-modules/tui/incubating/sesh/ -> home/04-modules/tui/graduated/sesh/
# 2. Update the import path in home/03-features/tui.nix
# 3. Update the module metadata header
# 4. Print a diff for review before committing
```

---

## 8. Relationship to Future IDP

### What cmdr Is

cmdr is a **development-first workstation provisioner**. It manages:
- Shell environments (zsh, starship, tmux)
- Editor configurations (neovim, AstroNvim, nixvim)
- Developer CLI tools (git, fzf, ripgrep, etc.)
- Cloud CLI tools (aws, terraform, kubectl, etc.)
- Terminal emulators (ghostty, kitty, alacritty)
- Linux desktop environments (Hyprland + DMS)
- Employer-specific overrides (UPMC)

### What cmdr Is Not

cmdr does **not** manage:
- Platform infrastructure (Kubernetes clusters, ArgoCD, Gitea)
- Cloud resources (VPCs, EC2 instances, S3 buckets)
- CI/CD pipelines or runners
- Observability stack (Prometheus, Grafana)
- Security tooling (Vault, OPA, Trivy)
- Developer portal (Backstage)

### Future Integration

When the IDP is built:
1. cmdr will be hosted in the IDP's **Gitea** instance
2. cmdr may be deployed/synced via **ArgoCD** to managed workstations
3. The IDP repo will have its own module system for platform concerns
4. cmdr's tier system provides a clear interface boundary -- graduated modules are the stable API surface

The tier system and clean category structure make cmdr a well-defined, self-contained component that can be absorbed into a larger system without structural changes.

---

## 9. Rollback Plan

If the migration causes issues:

1. **Git revert** -- each phase will be a clean commit (or small series), easily revertable
2. **Nix generations** -- `make rollback HOST=<name>` restores the previous Home Manager generation
3. **No data loss** -- this is purely a structural reorganization; no module configurations change
4. **Incremental validation** -- `nix flake check` after each phase catches path resolution errors before they reach a host

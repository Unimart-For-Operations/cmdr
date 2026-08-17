# CNOE IDP Builder -- Codebase Analysis

**Analyzed:** 2026-03-22
**Upstream:** [`github.com/cnoe-io/idpbuilder`](https://github.com/cnoe-io/idpbuilder)
**Fork:** [`github.com/412andrewmortimer/idpbuilder`](https://github.com/412andrewmortimer/idpbuilder)
**Version:** `main` @ `e1036dd` (ArgoCD v3.1.7, Kind v0.29.0, Gitea latest)

> This is a fork of the upstream CNOE project. The fork tracks `main` and should be regularly synced via `git fetch upstream && git merge upstream/main`. The long-term goal is to contribute back upstream via pull requests.

> This document captures the structure and architecture of the CNOE IDP Builder project -- the platform cmdr will eventually be absorbed into. See [Roadmap README](README.md) for how this relates to cmdr's future.

---

## Overview

**idpbuilder** is a single Go binary that spins up a complete local Internal Developer Platform using only Docker as a prerequisite. One command gives you a full IDP stack:

```bash
idpbuilder create
```

This creates:

1. A **Kind** (Kubernetes in Docker) cluster
2. **ingress-nginx** for HTTP/HTTPS routing
3. **Gitea** as an in-cluster Git server
4. **ArgoCD** for GitOps-based application deployment
5. **CoreDNS** configuration for `*.cnoe.localtest.me` domain resolution
6. **TLS certificates** (self-signed) for HTTPS endpoints

Custom packages (ArgoCD Applications) can be layered on top via the `-p` flag, pointing to local directories, files, or remote Git URLs.

### Use Cases

- Demo IDP reference implementations locally
- CI integration testing of platform configurations
- Local development environment for platform engineers

### Requirements

- **Docker** (Docker Desktop, OrbStack, or Colima on macOS)
- **4 CPU cores**, **4 GiB RAM** minimum
- macOS (Apple Silicon or Intel) or Linux

### Installation

```bash
brew install cnoe-io/tap/idpbuilder
```

---

## Architecture

### Two-Phase Design

idpbuilder operates in two distinct phases:

**Phase 1 -- CLI**: Parses flags, creates the Kind cluster, installs CRDs, starts an in-process Kubernetes controller manager.

**Phase 2 -- Controllers**: Three reconcilers run inside the CLI process (not as in-cluster pods) and manage CRDs to orchestrate package installation:

| Controller | CRD | Responsibility |
|------------|-----|----------------|
| `LocalbuildReconciler` | `Localbuild` | Installs core packages (nginx, ArgoCD, Gitea) in parallel, manages ArgoCD apps, handles custom packages with priority-based conflict resolution |
| `RepositoryReconciler` | `GitRepository` | Manages Git repos on Gitea/GitHub -- clones, commits, pushes content for embedded, local, and remote sources |
| `CustomPackageReconciler` | `CustomPackage` | Handles user-defined ArgoCD Applications/ApplicationSets, resolves `cnoe://` URIs, manages priority-based package conflicts |

### Custom Resource Definitions

All CRDs live in `api/v1alpha1/` using kubebuilder conventions:

**`Localbuild`** -- The top-level resource representing an IDP instance. Contains:
- `BuildCustomizationSpec`: protocol, host, port, TLS, path routing
- `PackageConfigsSpec`: ArgoCD configuration, custom package references

**`GitRepository`** -- Represents a Git repo on the Gitea server. Supports embedded (in-binary), local (filesystem), and remote (URL) source types. Tracks provider info (Gitea or GitHub).

**`CustomPackage`** -- Represents a user-specified ArgoCD Application or ApplicationSet. Supports `cnoe://` scheme for referencing in-cluster Gitea repos.

### Package Flow

```
CLI flags (-p paths/URLs)
  → CustomPackage CRs created
    → CustomPackageReconciler resolves cnoe:// URIs
      → GitRepository CRs created
        → RepositoryReconciler pushes content to Gitea
          → ArgoCD syncs Applications from Gitea repos
```

### Module Load Order

```
[1] Kind cluster created (Docker)
[2] CRDs installed
[3] Controller manager started (in-process)
[4] Localbuild CR created
[5] Core packages installed in parallel:
    - ingress-nginx
    - ArgoCD
    - Gitea
[6] Custom packages processed (priority-based)
[7] ArgoCD syncs all applications
```

---

## CLI Commands

| Command | Description |
|---------|-------------|
| `idpbuilder create` | Create or recreate an IDP cluster (~20 flags: name, protocol, host, port, kube-version, packages, etc.) |
| `idpbuilder delete` | Delete an IDP cluster |
| `idpbuilder get secrets` | Retrieve credentials for ArgoCD and Gitea |
| `idpbuilder get clusters` | List managed clusters |
| `idpbuilder get packages` | List installed packages |
| `idpbuilder version` | Show version info |

### Key `create` Flags

```bash
idpbuilder create \
  --name my-idp \                    # Cluster name
  --port 8443 \                      # Ingress port
  --protocol https \                 # Protocol (http/https)
  --host cnoe.localtest.me \         # Base domain
  --kube-version v1.29.1 \           # Kubernetes version
  -p ./my-packages \                 # Custom packages (repeatable)
  -p https://github.com/org/repo     # Remote packages
```

---

## Codebase Structure

```
idpbuilder/
├── main.go                          # Entry point
├── api/v1alpha1/                    # CRD type definitions (3 CRDs)
├── pkg/
│   ├── cmd/                         # CLI layer (Cobra)
│   │   ├── create/                  #   create command (~270 lines, ~20 flags)
│   │   ├── delete/                  #   delete command
│   │   ├── get/                     #   get secrets/clusters/packages
│   │   ├── version/                 #   version display
│   │   └── helpers/                 #   shared CLI utilities
│   ├── build/                       # Build orchestration, TLS, CoreDNS
│   ├── controllers/                 # Kubernetes controllers (the heart)
│   │   ├── localbuild/              #   LocalbuildReconciler (~971 lines)
│   │   │   └── resources/           #   Embedded YAML for ArgoCD, Gitea, nginx
│   │   ├── gitrepository/           #   RepositoryReconciler (~366 lines)
│   │   └── custompackage/           #   CustomPackageReconciler (~728 lines)
│   ├── kind/                        # Kind cluster lifecycle
│   ├── k8s/                         # Kubernetes client utilities
│   ├── util/                        # Shared utilities (14 files)
│   ├── resources/                   # ArgoCD Application spec helpers
│   ├── logger/                      # Custom log handler
│   └── printer/                     # CLI output formatting
├── hack/                            # Build/generation scripts
│   ├── argo-cd/                     #   ArgoCD kustomize patches
│   ├── gitea/                       #   Gitea Helm values
│   └── ingress-nginx/               #   ingress-nginx kustomize patches
├── tests/e2e/                       # End-to-end test suite
├── docs/                            # Design docs and architecture diagrams
├── .github/workflows/               # 7 CI workflows
├── Makefile                         # Build, test, generate, e2e targets
├── go.mod                           # Go 1.22, module github.com/cnoe-io/idpbuilder
└── .goreleaser.yaml                 # Cross-platform release config
```

### Metrics

| Metric | Value |
|--------|-------|
| Go source files | 77 (~12K lines) |
| Go test files | 19 (~3.6K lines) |
| Embedded YAML manifests | ~73K lines (generated artifacts for ArgoCD/Gitea/nginx) |
| Total files | 187 |
| CRDs | 3 |
| Controllers | 3 |
| CLI commands | 4 top-level, 3 subcommands |
| CI workflows | 7 |

Complexity is medium -- compact Go codebase (~12K lines) but architecturally sophisticated, combining Cobra CLI, controller-runtime patterns, go-git operations, and multi-service orchestration.

---

## Core Dependencies

| Dependency | Version | Purpose |
|------------|---------|---------|
| `sigs.k8s.io/kind` | v0.29.0 | Kind cluster library |
| `sigs.k8s.io/controller-runtime` | v0.18.5 | Kubernetes controller framework |
| `github.com/cnoe-io/argocd-api` | latest | ArgoCD Application/ApplicationSet types |
| `code.gitea.io/sdk/gitea` | v0.16.0 | Gitea API client |
| `github.com/go-git/go-git/v5` | v5.12.0 | Pure Go git implementation |
| `github.com/spf13/cobra` | v1.8.0 | CLI framework |
| `github.com/google/go-github/v61` | v61.0.0 | GitHub API client |
| `github.com/docker/docker` | v25.0.6 | Docker API (Kind provider detection) |
| `k8s.io/client-go` | v0.30.5 | Kubernetes client |
| `k8s.io/apimachinery` | v0.30.5 | Kubernetes object model |

~100+ indirect dependencies (OpenTelemetry, protobuf, gRPC, crypto, Prometheus client).

---

## Build and Tooling

### Makefile Targets

| Target | Description |
|--------|-------------|
| `make build` | Full build: manifests, generate, fmt, vet, embedded-resources, `go build` |
| `make test` | Unit/integration tests with envtest (K8s 1.29.1) |
| `make e2e` | Build binary then run E2E tests (15-min timeout) |
| `make manifests` | Generate CRD YAML via controller-gen |
| `make generate` | Generate DeepCopy methods |
| `make embedded-resources` | Run kustomize/helm to regenerate embedded K8s manifests |
| `make fmt` | `go fmt` |
| `make vet` | `go vet` |

### Release Pipeline

GoReleaser v2 produces cross-compiled binaries for `linux/darwin` on `amd64/arm64`. Published via:
- GitHub Releases (with nightly auto-tagging)
- Homebrew tap (`cnoe-io/homebrew-tap`)

### CI Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `pr.yaml` | Pull requests | Build + unit tests |
| `e2e.yaml` | Push to main, `/e2e` slash command | Full cluster lifecycle E2E |
| `release.yaml` | Version tags | GoReleaser + Homebrew tap |
| `nightly.yaml` | Cron (7 AM UTC) | Auto-tag, build, clean old nightlies |
| `code-scanner.yaml` | PRs + pushes to main | Anchore security scanning |
| `codespell.yaml` | PRs + pushes to main | Spell checking |
| `slash-commands.yaml` | PR comments | Handle `/e2e` commands |

---

## Integration Points

### What idpbuilder Installs

| Component | Role | Version (current) |
|-----------|------|--------------------|
| **Kind** | Local Kubernetes cluster | v0.29.0 |
| **ingress-nginx** | HTTP/HTTPS routing, TLS termination | Latest (via kustomize) |
| **ArgoCD** | GitOps application deployment | v3.1.7 |
| **Gitea** | In-cluster Git server + container registry | Latest (via Helm) |

### What idpbuilder Does Not Install

These are mentioned in CNOE documentation but are not part of idpbuilder core -- they would be added as custom packages:
- **Backstage** (developer portal)
- **Crossplane** (infrastructure provisioning)
- **Argo Workflows** (CI/CD pipelines)
- **External Secrets** (secret management)
- **Keycloak** (identity/auth)

### CNOE Reference Implementations

The CNOE community provides pre-built custom package sets (added via `-p`) that layer these additional components on top of idpbuilder's core stack.

---

## Relationship to cmdr

| Component | Scope | Role |
|-----------|-------|------|
| **cmdr** | Workstation provisioner | Manages developer environments (shell, editor, CLI tools, terminal emulators) |
| **idpbuilder** | Platform provisioner | Manages the IDP stack (Kubernetes, ArgoCD, Gitea) |

### Future Integration Path

1. cmdr manages the developer's **local workstation** (what's installed, how it's configured)
2. idpbuilder manages the **local IDP** (Kubernetes cluster, GitOps, Git server)
3. cmdr will be absorbed into idpbuilder's **Gitea instance** as a self-contained component
4. cmdr could potentially manage idpbuilder installation as a **graduated module** (via Homebrew or Nix)
5. cmdr's graduated modules represent the **stable API surface** for the absorption boundary

### What This Means Practically

- cmdr provisions the developer's tools (zsh, neovim, git, kubectl, etc.)
- idpbuilder provisions the platform those tools interact with (the cluster, ArgoCD UI, Gitea repos)
- Together they form a complete developer experience: workstation + platform

---

## Fork Maintenance

The local clone at `/Users/cmdr/repos/github/412andrewmortimer/idpbuilder` currently has `origin` pointing to the upstream CNOE org. To set up proper fork workflow:

```bash
# Rename current origin to upstream
git remote rename origin upstream

# Add your fork as origin
git remote add origin git@github.com:412andrewmortimer/idpbuilder.git

# Verify
git remote -v
# origin    git@github.com:412andrewmortimer/idpbuilder.git (fetch/push)
# upstream  git@github.com:cnoe-io/idpbuilder.git (fetch/push)
```

To sync from upstream:

```bash
git fetch upstream
git merge upstream/main
git push origin main
```

To contribute back: create a feature branch, push to `origin`, open a PR against `upstream/main`.

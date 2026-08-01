.PHONY: help bootstrap register new-host doctor hooks sync-docs pull-docs dev ci ci-full compat test test-run test-shell test-tty test-clean fmt check update clean list switch diff apply rollback switch-studio switch-macbook switch-cmdr switch-cachyos diff-studio diff-macbook diff-cmdr diff-cachyos tiers promote aliases

# Default target
.DEFAULT_GOAL := help

# Color output
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RESET := \033[0m
BOLD := \033[1m

# Use bash for pipefail and PIPESTATUS support in the switch target.
# Keep this as an executable name (no spaces) so GNU Make can exec it on NixOS.
SHELL := bash
UNAME := $(shell uname -s)
CURRENT_USER := $(shell whoami)
CURRENT_DIR := $(shell pwd)

# Auto-detect current host by matching username in meta.nix.
# Prefer the real platform first and then prefer a hostname match.
ifeq ($(UNAME),Darwin)
	DETECTED_HOST := $(shell \
		HOSTNAME_SHORT=`hostname -s 2>/dev/null || hostname`; \
		FIRST_MATCH=""; \
		for host_dir in home/02-hosts/macos/*/; do \
			[ -f "$$host_dir/meta.nix" ] || continue; \
			username=`grep 'username.*=' "$$host_dir/meta.nix" | sed 's/.*username.*=.*"\(.*\)".*/\1/' | tr -d ' '`; \
			[ "$$username" = "$(CURRENT_USER)" ] || continue; \
			host_name=`basename "$$host_dir"`; \
			if [ "$$host_name" = "$$HOSTNAME_SHORT" ]; then \
				echo "$$host_name"; \
				exit 0; \
			fi; \
			[ -z "$$FIRST_MATCH" ] && FIRST_MATCH="$$host_name"; \
		done; \
		echo "$$FIRST_MATCH" \
	)
else
	DETECTED_HOST := $(shell \
		HOSTNAME_SHORT=`hostname -s 2>/dev/null || hostname`; \
		PRIMARY_PLATFORM="arch"; \
		if [ -f /etc/os-release ]; then \
			OS_ID=`. /etc/os-release && echo "$$ID"`; \
			if [ "$$OS_ID" = "nixos" ]; then \
				PRIMARY_PLATFORM="nixos"; \
			elif [ "$$OS_ID" = "ubuntu" ] || [ "$$OS_ID" = "pop" ] || [ "$$OS_ID" = "linuxmint" ]; then \
				PRIMARY_PLATFORM="ubuntu"; \
			elif [ "$$OS_ID" = "arch" ] || [ "$$OS_ID" = "cachyos" ] || [ "$$OS_ID" = "endeavouros" ] || [ "$$OS_ID" = "manjaro" ]; then \
				PRIMARY_PLATFORM="arch"; \
			fi; \
		fi; \
		if [ "$$PRIMARY_PLATFORM" = "nixos" ]; then \
			PLATFORMS="nixos arch ubuntu"; \
		elif [ "$$PRIMARY_PLATFORM" = "ubuntu" ]; then \
			PLATFORMS="ubuntu arch nixos"; \
		else \
			PLATFORMS="arch nixos ubuntu"; \
		fi; \
		for platform in $$PLATFORMS; do \
			FIRST_MATCH=""; \
			for host_dir in home/02-hosts/$$platform/*/; do \
				[ -f "$$host_dir/meta.nix" ] || continue; \
				username=`grep 'username.*=' "$$host_dir/meta.nix" | sed 's/.*username.*=.*"\(.*\)".*/\1/' | tr -d ' '`; \
				[ "$$username" = "$(CURRENT_USER)" ] || continue; \
				host_name=`basename "$$host_dir"`; \
				if [ "$$host_name" = "$$HOSTNAME_SHORT" ]; then \
					echo "$$host_name"; \
					exit 0; \
				fi; \
				[ -z "$$FIRST_MATCH" ] && FIRST_MATCH="$$host_name"; \
			done; \
			if [ -n "$$FIRST_MATCH" ]; then \
				echo "$$FIRST_MATCH"; \
				exit 0; \
			fi; \
		done \
	)
endif

# Use HOST if provided, otherwise fall back to detected host
CURRENT_HOST := $(or $(HOST),$(DETECTED_HOST))

# Detect NixOS
IS_NIXOS := $(shell [ -f /etc/NIXOS ] && echo 1 || echo 0)

help: ## Show this help message
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@printf "$(BOLD)cmdr — Development Environment$(RESET)\n"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@printf "$(BOLD)Setup & Bootstrap:$(RESET)\n"
	@printf "  $(CYAN)bootstrap$(RESET)       Install prerequisites (Xcode, Homebrew, Nix)\n"
	@printf "  $(CYAN)register$(RESET)        Register this machine (auto-detects platform)\n"
	@printf "  $(CYAN)hooks$(RESET)           Install git hooks (secrets, fmt, flake check)\n"
	@echo ""
	@printf "$(BOLD)Development:$(RESET)\n"
	@printf "  $(CYAN)dev$(RESET)             Enter development shell\n"
	@printf "  $(CYAN)ci$(RESET)              Run all local checks (secrets, fmt, theme-lint, flake, doctor)\n"
	@printf "  $(CYAN)ci-full$(RESET)         Run ci plus automated container test\n"
	@printf "  $(CYAN)doctor$(RESET)          Verify environment health\n"
	@printf "  $(CYAN)check$(RESET)           Run nix flake checks\n"
	@printf "  $(CYAN)compat$(RESET)          Evaluate all host configs (linux + darwin)\n"
	@printf "  $(CYAN)fmt$(RESET)             Format Nix code\n"
	@printf "  $(CYAN)update$(RESET)          Update flake inputs\n"
	@printf "  $(CYAN)clean$(RESET)           Remove build artifacts\n"
	@echo ""
	@printf "$(BOLD)Host Management:$(RESET)\n"
	@printf "  $(CYAN)list$(RESET)            List all available hosts\n"
	@printf "  $(CYAN)switch$(RESET)          Apply config (auto-detects current host)\n"
	@printf "  $(CYAN)diff$(RESET)            Show pending changes (auto-detects)\n"
	@printf "  $(CYAN)apply$(RESET)           Apply config for HOST=<name>\n"
	@printf "  $(CYAN)rollback$(RESET)        Roll back to previous generation\n"
	@printf "  $(CYAN)switch-studio$(RESET)   Switch Apple Studio M2 Max\n"
	@printf "  $(CYAN)switch-macbook$(RESET)  Switch Apple MacBook M3 Pro\n"
	@printf "  $(CYAN)switch-cmdr$(RESET)     Switch cmdr (Arch Linux)\n"
	@printf "  $(CYAN)switch-cachyos$(RESET)  Switch CachyOS\n"
	@printf "  $(CYAN)diff-studio$(RESET)     Diff Apple Studio M2 Max\n"
	@printf "  $(CYAN)diff-macbook$(RESET)    Diff Apple MacBook M3 Pro\n"
	@printf "  $(CYAN)diff-cmdr$(RESET)       Diff cmdr (Arch Linux)\n"
	@printf "  $(CYAN)diff-cachyos$(RESET)    Diff CachyOS\n"
	@echo ""
	@printf "$(BOLD)Testing (Linux only):$(RESET)\n"
	@printf "  $(CYAN)test$(RESET)            Build and start test container\n"
	@printf "  $(CYAN)test-run$(RESET)        Automated provision + verify + teardown\n"
	@printf "  $(CYAN)test-shell$(RESET)      Enter interactive container shell\n"
	@printf "  $(CYAN)test-tty$(RESET)        Provision config and open zsh in container\n"
	@printf "  $(CYAN)test-clean$(RESET)      Stop containers and cleanup\n"
	@echo ""
	@printf "$(BOLD)Other:$(RESET)\n"
	@printf "  $(CYAN)sync-docs$(RESET)       Copy docs/ to Obsidian vault\n"
	@printf "  $(CYAN)tiers$(RESET)           Show module adoption tiers\n"
	@printf "  $(CYAN)promote$(RESET)         Move module to a higher tier\n"
	@printf "  $(CYAN)aliases$(RESET)         List all shell aliases with audit warnings\n"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@if [ -n "$(DETECTED_HOST)" ]; then \
		printf "Current host: $(GREEN)$(DETECTED_HOST)$(RESET)\n"; \
	else \
		printf "$(YELLOW)No host detected for this machine$(RESET)\n"; \
	fi
	@echo ""

# ── Setup & Bootstrap ──────────────────────────────────────────────────────

bootstrap: ## Install prerequisites (Xcode CLT + Homebrew on macOS, Nix on all)
	@bash scripts/bootstrap.sh

# Valid distro directories (must match distroToPlatform keys in home/02-hosts/default.nix)
VALID_DISTROS := macos arch nixos ubuntu

# Default features per profile
FEATURES_desktop := cli tui gui
FEATURES_tty     := cli tui

register: ## Register this machine: make register [NAME=<name>] [GIT_NAME="..."] [GIT_EMAIL="..."] [PROFILE=desktop|tty]
	@# ── Auto-detect DISTRO ──────────────────────────────────────────────
	@if [ -n "$(DISTRO)" ]; then \
		DISTRO_RESOLVED="$(DISTRO)"; \
	elif [ "$$(uname -s)" = "Darwin" ]; then \
		DISTRO_RESOLVED="macos"; \
	elif [ -f /etc/os-release ]; then \
		OS_ID=$$(. /etc/os-release && echo "$$ID"); \
		case "$$OS_ID" in \
			arch|cachyos|endeavouros|manjaro) DISTRO_RESOLVED="arch" ;; \
			nixos)                             DISTRO_RESOLVED="nixos" ;; \
			ubuntu|pop|linuxmint)              DISTRO_RESOLVED="ubuntu" ;; \
			*)                                 DISTRO_RESOLVED="arch" ;; \
		esac; \
	else \
		DISTRO_RESOLVED="arch"; \
	fi; \
	if ! echo " $(VALID_DISTROS) " | grep -q " $$DISTRO_RESOLVED "; then \
		printf "$(YELLOW)Invalid DISTRO '$$DISTRO_RESOLVED'. Must be one of: $(VALID_DISTROS)$(RESET)\n"; exit 1; \
	fi; \
	\
	# ── Auto-detect NAME ────────────────────────────────────────────────── \
	if [ -n "$(NAME)" ]; then \
		HOST_NAME="$(NAME)"; \
	elif [ "$$(uname -s)" = "Darwin" ] && command -v scutil >/dev/null 2>&1; then \
		HOST_NAME=$$(scutil --get LocalHostName 2>/dev/null | tr '[:upper:]' '[:lower:]' || hostname -s); \
	else \
		HOST_NAME=$$(hostname -s 2>/dev/null || hostname); \
	fi; \
	\
	# ── Check for existing host ─────────────────────────────────────────── \
	if [ -d "home/02-hosts/$$DISTRO_RESOLVED/$$HOST_NAME" ]; then \
		printf "$(YELLOW)Host already exists: home/02-hosts/$$DISTRO_RESOLVED/$$HOST_NAME/$(RESET)\n"; \
		printf "Use NAME=<other> to choose a different name, or remove the existing directory.\n"; \
		exit 1; \
	fi; \
	\
	# ── Resolve system ──────────────────────────────────────────────────── \
	ARCH="$$(uname -m)"; \
	case "$$DISTRO_RESOLVED" in \
		macos) \
			case "$$ARCH" in \
				arm64)  SYSTEM="aarch64-darwin" ;; \
				x86_64) SYSTEM="x86_64-darwin" ;; \
				*)      SYSTEM="aarch64-darwin" ;; \
			esac; \
			HOME_DIR="/Users/$$(whoami)"; \
			;; \
		*) \
			case "$$ARCH" in \
				aarch64) SYSTEM="aarch64-linux" ;; \
				*)       SYSTEM="x86_64-linux" ;; \
			esac; \
			HOME_DIR="/home/$$(whoami)"; \
			;; \
	esac; \
	\
	# ── Resolve identity ────────────────────────────────────────────────── \
	if [ -n "$(GIT_NAME)" ]; then \
		RESOLVED_GIT_NAME="$(GIT_NAME)"; \
	elif [ -t 0 ]; then \
		EXISTING=$$(git config --global user.name 2>/dev/null || true); \
		if [ -n "$$EXISTING" ]; then \
			printf "Git name [$$EXISTING]: "; \
			read -r RESOLVED_GIT_NAME; \
			[ -z "$$RESOLVED_GIT_NAME" ] && RESOLVED_GIT_NAME="$$EXISTING"; \
		else \
			printf "Git name: "; \
			read -r RESOLVED_GIT_NAME; \
		fi; \
	else \
		RESOLVED_GIT_NAME=$$(git config --global user.name 2>/dev/null || echo "Your Name"); \
	fi; \
	\
	if [ -n "$(GIT_EMAIL)" ]; then \
		RESOLVED_GIT_EMAIL="$(GIT_EMAIL)"; \
	elif [ -t 0 ]; then \
		EXISTING=$$(git config --global user.email 2>/dev/null || true); \
		if [ -n "$$EXISTING" ]; then \
			printf "Git email [$$EXISTING]: "; \
			read -r RESOLVED_GIT_EMAIL; \
			[ -z "$$RESOLVED_GIT_EMAIL" ] && RESOLVED_GIT_EMAIL="$$EXISTING"; \
		else \
			printf "Git email: "; \
			read -r RESOLVED_GIT_EMAIL; \
		fi; \
	else \
		RESOLVED_GIT_EMAIL=$$(git config --global user.email 2>/dev/null || echo "you@example.com"); \
	fi; \
	\
	# ── Resolve features ────────────────────────────────────────────────── \
	PROFILE="$(or $(PROFILE),desktop)"; \
	if [ -n "$(FEATURES)" ]; then \
		RESOLVED_FEATURES="$(FEATURES)"; \
	elif [ "$$PROFILE" = "tty" ]; then \
		RESOLVED_FEATURES="$(FEATURES_tty)"; \
	else \
		RESOLVED_FEATURES="$(FEATURES_desktop)"; \
	fi; \
	NIX_FEATURES=""; \
	for f in $$RESOLVED_FEATURES; do \
		NIX_FEATURES="$$NIX_FEATURES \"$$f\""; \
	done; \
	\
	# ── Build optional fields ─────────────────────────────────────────── \
	OPTIONAL=""; \
	if [ -n "$(DESKTOP)" ]; then \
		NIX_DESKTOP=""; \
		for d in $(DESKTOP); do \
			NIX_DESKTOP="$$NIX_DESKTOP \"$$d\""; \
		done; \
		OPTIONAL="$$OPTIONAL\n  desktop = [$$NIX_DESKTOP ];"; \
	fi; \
	if [ "$(WORK)" = "true" ]; then \
		OPTIONAL="$$OPTIONAL\n  work = true;"; \
	fi; \
	\
	# ── Create host directory and write files ─────────────────────────── \
	HOST_DIR="home/02-hosts/$$DISTRO_RESOLVED/$$HOST_NAME"; \
	mkdir -p "$$HOST_DIR"; \
	\
	printf '{\n  description = "%s";\n  system = "%s";\n  username = "%s";\n  homeDirectory = "%s";\n  gitName = "%s";\n  gitEmail = "%s";\n  features = [%s ];\n' \
		"$$HOST_NAME" "$$SYSTEM" "$$(whoami)" "$$HOME_DIR" "$$RESOLVED_GIT_NAME" "$$RESOLVED_GIT_EMAIL" "$$NIX_FEATURES" \
		> "$$HOST_DIR/meta.nix"; \
	if [ -n "$$OPTIONAL" ]; then \
		printf "$$OPTIONAL\n" >> "$$HOST_DIR/meta.nix"; \
	fi; \
	printf '  theme = "catppuccin-frappe";\n}\n' >> "$$HOST_DIR/meta.nix"; \
	\
	printf '{ ... }:\n\n{\n  # Add overrides here only when this machine diverges from the shared baseline.\n}\n' \
		> "$$HOST_DIR/default.nix"; \
	\
	# ── Summary ───────────────────────────────────────────────────────── \
	echo ""; \
	printf "$(GREEN)✓ Registered host: $$HOST_DIR/$(RESET)\n"; \
	echo ""; \
	cat "$$HOST_DIR/meta.nix"; \
	echo ""; \
	if [ -n "$$EDITOR" ]; then \
		echo "Opening meta.nix in $$EDITOR for review..."; \
		$$EDITOR "$$HOST_DIR/meta.nix"; \
	elif [ -n "$$VISUAL" ]; then \
		echo "Opening meta.nix in $$VISUAL for review..."; \
		$$VISUAL "$$HOST_DIR/meta.nix"; \
	else \
		echo "Set \$$EDITOR to auto-open meta.nix for review."; \
	fi; \
	echo ""; \
	printf "$(BOLD)Next steps:$(RESET)\n"; \
	echo "  make switch    # Apply configuration"

new-host: register ## (alias for register)

hooks: ## Git hooks are Nix-managed (see ADR-005)
	@printf "\033[0;36m[info]\033[0m Hooks are globally managed via Nix (cmdr git module)\n"
	@printf "  Deploy: unimart deli switch\n"
	@printf "  Source: home/04-modules/cli/graduated/git/default.nix\n"

sync-docs: ## Copy docs/ to Obsidian vault (delegated to org-level docs repo)
	@ORG_DIR="$$(dirname "$$(pwd)")"; \
	if [ -x "$$ORG_DIR/docs/scripts/sync-docs.sh" ]; then \
		bash "$$ORG_DIR/docs/scripts/sync-docs.sh"; \
	else \
		printf "\033[0;31mx\033[0m docs repo not found at $$ORG_DIR/docs/\n"; \
		printf "  Clone it: gh repo clone idpbuilder/docs $$ORG_DIR/docs\n"; \
		exit 1; \
	fi

pull-docs: ## Pull Obsidian edits back to repo (reverse sync for phone/tablet edits)
	@OBSIDIAN_SRC="$$HOME/Documents/cmdr/Professional/idpbuilder/cmdr"; \
	if [ ! -d "$$OBSIDIAN_SRC" ]; then \
		printf "\033[0;31mx\033[0m Obsidian docs not found at $$OBSIDIAN_SRC\n"; \
		printf "  Run 'make sync-docs' first to populate the vault.\n"; \
		exit 1; \
	fi; \
	printf "\033[0;33m!\033[0m Pulling from Obsidian vault to docs/ ...\n"; \
	rsync -av --delete "$$OBSIDIAN_SRC/" docs/; \
	printf "\033[0;32mv\033[0m Pull complete. Review changes:\n"; \
	git diff --stat docs/

# ── Development ────────────────────────────────────────────────────────────

dev: ## Enter development shell
	@nix develop

ci: ## Run all local checks (secrets, fmt, theme-lint, flake, doctor, compat)
	@ERRORS=0; \
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; \
	printf "$(BOLD)cmdr — Local CI$(RESET)\n"; \
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; \
	echo ""; \
	\
	printf "$(BOLD)[1/6] Secret scanning (gitleaks)$(RESET)\n"; \
	if command -v gitleaks >/dev/null 2>&1; then \
		if gitleaks detect --verbose --redact 2>&1; then \
			printf "  $(GREEN)✓ No secrets detected$(RESET)\n"; \
		else \
			printf "  $(YELLOW)⚠ Secrets detected — review output above$(RESET)\n"; \
			ERRORS=$$((ERRORS+1)); \
		fi; \
	else \
		printf "  $(YELLOW)⚠ gitleaks not found — skipping$(RESET)\n"; \
	fi; \
	echo ""; \
	\
	printf "$(BOLD)[2/6] Nix formatting$(RESET)\n"; \
	if nix fmt -- --check . 2>/dev/null; then \
		printf "  $(GREEN)✓ All files formatted$(RESET)\n"; \
	else \
		printf "  $(YELLOW)⚠ Formatting issues — run: make fmt$(RESET)\n"; \
		ERRORS=$$((ERRORS+1)); \
	fi; \
	echo ""; \
	\
	printf "$(BOLD)[3/6] Theme lint$(RESET)\n"; \
	if bash scripts/check-theme-lint.sh 2>&1; then \
		printf "  $(GREEN)✓ Theme integrity OK$(RESET)\n"; \
	else \
		printf "  $(YELLOW)⚠ Theme lint failed$(RESET)\n"; \
		ERRORS=$$((ERRORS+1)); \
	fi; \
	echo ""; \
	\
	printf "$(BOLD)[4/6] Nix flake check$(RESET)\n"; \
	if nix flake check 2>&1; then \
		printf "  $(GREEN)✓ Flake check passed$(RESET)\n"; \
	else \
		printf "  $(YELLOW)⚠ Flake check failed$(RESET)\n"; \
		ERRORS=$$((ERRORS+1)); \
	fi; \
	echo ""; \
	\
	printf "$(BOLD)[5/6] Environment health$(RESET)\n"; \
	$(MAKE) --no-print-directory doctor; \
	echo ""; \
	\
	printf "$(BOLD)[6/6] Cross-platform host eval$(RESET)\n"; \
	if $(MAKE) --no-print-directory compat; then \
		printf "  $(GREEN)✓ Host compatibility checks passed$(RESET)\n"; \
	else \
		printf "  $(YELLOW)⚠ Host compatibility checks failed$(RESET)\n"; \
		ERRORS=$$((ERRORS+1)); \
	fi; \
	echo ""; \
	\
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; \
	if [ $$ERRORS -eq 0 ]; then \
		printf "$(GREEN)✓ All CI checks passed$(RESET)\n"; \
	else \
		printf "$(YELLOW)⚠ $$ERRORS check(s) failed$(RESET)\n"; \
	fi; \
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ci-full: ## Run all local checks plus the automated container test (Linux only)
	@$(MAKE) --no-print-directory ci
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@printf "$(BOLD)cmdr — Container Test$(RESET)\n"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ifneq ($(UNAME),Darwin)
	@bash scripts/container-test.sh "$(TEST_HOST)"
else
	$(LINUX_GUARD)
endif

# ── Health check ──────────────────────────────────────────────────────────
DOCTOR_PASS  := \033[0;32m[pass]\033[0m
DOCTOR_FAIL  := \033[0;31m[fail]\033[0m
DOCTOR_WARN  := \033[0;33m[warn]\033[0m

doctor: ## Verify environment health (Nix, tools, config)
	@ERRORS=0; \
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; \
	echo "$(BOLD)cmdr — Health Check$(RESET)"; \
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; \
	echo ""; \
	\
	echo "Prerequisites:"; \
	if command -v git >/dev/null 2>&1; then \
		printf "  $(DOCTOR_PASS) git (%s)\n" "$$(git --version | head -1)"; \
	else \
		printf "  $(DOCTOR_FAIL) git not found\n"; ERRORS=$$((ERRORS+1)); \
	fi; \
	if [ "$$(uname -s)" = "Darwin" ]; then \
		if command -v brew >/dev/null 2>&1; then \
			printf "  $(DOCTOR_PASS) homebrew (%s)\n" "$$(brew --version 2>/dev/null | head -1)"; \
		else \
			printf "  $(DOCTOR_FAIL) homebrew not found (required on macOS)\n"; ERRORS=$$((ERRORS+1)); \
		fi; \
	fi; \
	if command -v nix >/dev/null 2>&1; then \
		printf "  $(DOCTOR_PASS) nix (%s)\n" "$$(nix --version)"; \
	else \
		printf "  $(DOCTOR_FAIL) nix not found — run: make bootstrap\n"; ERRORS=$$((ERRORS+1)); \
	fi; \
	if command -v nix >/dev/null 2>&1 && nix flake --help >/dev/null 2>&1; then \
		printf "  $(DOCTOR_PASS) flakes enabled\n"; \
	elif command -v nix >/dev/null 2>&1; then \
		printf "  $(DOCTOR_FAIL) flakes not enabled\n"; ERRORS=$$((ERRORS+1)); \
	fi; \
	echo ""; \
	\
	echo "Repository:"; \
	if [ -f flake.nix ]; then \
		printf "  $(DOCTOR_PASS) flake.nix found\n"; \
	else \
		printf "  $(DOCTOR_FAIL) flake.nix not found — are you in the repo root?\n"; ERRORS=$$((ERRORS+1)); \
	fi; \
	if [ -f flake.lock ]; then \
		printf "  $(DOCTOR_PASS) flake.lock found\n"; \
	else \
		printf "  $(DOCTOR_WARN) flake.lock missing — run: make update\n"; \
	fi; \
	if [ -d home/04-modules/tui/graduated/nvim/nvim-astro/lua ]; then \
		printf "  $(DOCTOR_PASS) git submodules initialized\n"; \
	else \
		printf "  $(DOCTOR_FAIL) git submodules not initialized — run: git submodule update --init --recursive\n"; ERRORS=$$((ERRORS+1)); \
	fi; \
	echo ""; \
	\
	echo "Shell:"; \
	if [ "$$(basename "$$SHELL")" = "zsh" ]; then \
		printf "  $(DOCTOR_PASS) default shell is zsh\n"; \
	else \
		printf "  $(DOCTOR_WARN) default shell is %s (expected zsh)\n" "$$(basename "$$SHELL")"; \
	fi; \
	if [ -d "$$HOME/.config" ]; then \
		printf "  $(DOCTOR_PASS) XDG config directory exists (~/.config)\n"; \
	else \
		printf "  $(DOCTOR_WARN) XDG config directory missing (~/.config)\n"; \
	fi; \
	echo ""; \
	\
	echo "Managed tools:"; \
	for tool in nvim tmux starship direnv rg fd bat eza zoxide atuin; do \
		if command -v "$$tool" >/dev/null 2>&1; then \
			printf "  $(DOCTOR_PASS) %s\n" "$$tool"; \
		else \
			printf "  $(DOCTOR_FAIL) %s not found\n" "$$tool"; ERRORS=$$((ERRORS+1)); \
		fi; \
	done; \
	echo ""; \
	\
	echo "Home Manager:"; \
	if command -v home-manager >/dev/null 2>&1; then \
		GENS=$$(home-manager generations 2>/dev/null | wc -l | tr -d ' '); \
		printf "  $(DOCTOR_PASS) home-manager available (%s generations)\n" "$$GENS"; \
	else \
		printf "  $(DOCTOR_WARN) home-manager not in PATH (normal before first apply)\n"; \
	fi; \
	if [ "$$(uname -s)" = "Darwin" ]; then \
		if command -v darwin-rebuild >/dev/null 2>&1; then \
			printf "  $(DOCTOR_PASS) darwin-rebuild available\n"; \
		else \
			printf "  $(DOCTOR_WARN) darwin-rebuild not in PATH (normal before first apply)\n"; \
		fi; \
	fi; \
	echo ""; \
	\
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; \
	if [ $$ERRORS -eq 0 ]; then \
		printf "$(GREEN)✓ All checks passed$(RESET)\n"; \
	else \
		printf "$(YELLOW)⚠ $$ERRORS issue(s) found$(RESET)\n"; \
	fi; \
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

fmt: ## Format Nix code
	@echo "Formatting Nix files..."
	@nix fmt
	@printf "$(GREEN)✓ Formatting complete$(RESET)\n"

check: ## Run nix flake checks
	@echo "Running flake checks..."
	@nix flake check
	@printf "$(GREEN)✓ Flake checks passed$(RESET)\n"

compat: ## Evaluate all host configurations for cross-platform compatibility
	@ERRORS=0; \
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; \
	printf "$(BOLD)cmdr — Compatibility Matrix$(RESET)\n"; \
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; \
	echo ""; \
	\
	printf "$(BOLD)Linux Home Manager hosts$(RESET)\n"; \
	LINUX_HOSTS=$$(nix eval --raw '.#homeConfigurations' --apply 'x: builtins.concatStringsSep " " (builtins.attrNames x)' 2>/dev/null || true); \
	if [ -z "$$LINUX_HOSTS" ]; then \
		printf "  $(YELLOW)[warn]$(RESET) no Linux hosts discovered\n"; \
	else \
		for host in $$LINUX_HOSTS; do \
			if nix eval --raw ".#homeConfigurations.$$host.activationPackage.drvPath" >/dev/null 2>&1; then \
				printf "  $(DOCTOR_PASS) %s\n" "$$host"; \
			else \
				printf "  $(DOCTOR_FAIL) %s\n" "$$host"; \
				ERRORS=$$((ERRORS+1)); \
			fi; \
		done; \
	fi; \
	echo ""; \
	\
	printf "$(BOLD)macOS nix-darwin hosts$(RESET)\n"; \
	DARWIN_HOSTS=$$(nix eval --raw '.#darwinConfigurations' --apply 'x: builtins.concatStringsSep " " (builtins.attrNames x)' 2>/dev/null || true); \
	if [ -z "$$DARWIN_HOSTS" ]; then \
		printf "  $(YELLOW)[warn]$(RESET) no macOS hosts discovered\n"; \
	else \
		for host in $$DARWIN_HOSTS; do \
			if nix eval --raw ".#darwinConfigurations.$$host.system" >/dev/null 2>&1; then \
				printf "  $(DOCTOR_PASS) %s\n" "$$host"; \
			else \
				printf "  $(DOCTOR_FAIL) %s\n" "$$host"; \
				ERRORS=$$((ERRORS+1)); \
			fi; \
		done; \
	fi; \
	echo ""; \
	\
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; \
	if [ $$ERRORS -eq 0 ]; then \
		printf "$(GREEN)✓ All host configs evaluate$(RESET)\n"; \
	else \
		printf "$(YELLOW)⚠ $$ERRORS host config(s) failed evaluation$(RESET)\n"; \
		exit 1; \
	fi; \
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

update: ## Update flake inputs
	@echo "Updating flake inputs..."
	@nix flake update
	@printf "$(GREEN)✓ Update complete$(RESET)\n"

clean: ## Remove build artifacts
	@echo "Removing build artifacts..."
	@rm -rf result result-*
	@printf "$(GREEN)✓ Clean complete$(RESET)\n"

# ── Host Management ────────────────────────────────────────────────────────

list: ## List all available hosts
	@printf "$(BOLD)Available hosts:$(RESET)\n"
	@echo ""
	@printf "$(BOLD)Darwin (macOS):$(RESET)\n"
	@nix eval --raw '.#darwinConfigurations' --apply 'x: builtins.concatStringsSep "\n" (builtins.attrNames x)' 2>/dev/null | sed 's/^/  /' | sed "s/\(.*\)/$$(printf '\033[0;36m')\1$$(printf '\033[0m')/"
	@echo ""
	@printf "$(BOLD)Linux:$(RESET)\n"
	@nix eval --raw '.#homeConfigurations' --apply 'x: builtins.concatStringsSep "\n" (builtins.attrNames x)' 2>/dev/null | sed 's/^/  /' | sed "s/\(.*\)/$$(printf '\033[0;36m')\1$$(printf '\033[0m')/"
	@echo ""
	@if [ -n "$(DETECTED_HOST)" ]; then \
		printf "Current host: $(GREEN)$(DETECTED_HOST)$(RESET)\n"; \
	else \
		printf "$(YELLOW)No host detected for this machine$(RESET)\n"; \
	fi

# Filter pattern to suppress noisy darwin-rebuild output:
#   - Home Manager orphan link warnings (lazy.nvim etc.)
#   - Homebrew bundle "Using" lines
#   - darwin-rebuild phase banners (setting up, configuring, etc.)
#   - bat cache rebuild output
#   - Home Manager activation step names
SWITCH_FILTER := grep -v -E '^(Path .*/\.|does not link into|Skipping delete\.|Using |✔︎ |setting up |applying patches|configuring |setting nvram|Homebrew bundle|No (themes|syntaxes) were|Writing (theme|syntax|metadata) |Activat|Starting Home Manager|Cleaning up orphan|Creating home file)'

switch: ## Apply configuration (auto-detects current host, or use HOST=<name>)
	@if [ -z "$(CURRENT_HOST)" ]; then \
		printf "$(YELLOW)No host specified and could not auto-detect.$(RESET)\n"; \
		echo "Use: make switch HOST=<name>"; \
		echo "Or: make list"; \
		exit 1; \
	fi
	@printf "$(BOLD)Applying configuration for: $(GREEN)$(CURRENT_HOST)$(RESET)\n"
	@echo ""
ifeq ($(UNAME),Darwin)
	@if command -v darwin-rebuild >/dev/null 2>&1; then \
		sudo darwin-rebuild switch --flake .#$(CURRENT_HOST) 2>&1 \
			| $(SWITCH_FILTER); \
		EXIT=$${PIPESTATUS[0]}; \
	else \
		echo "darwin-rebuild not found — running first-time bootstrap (requires sudo)..."; \
		if [ -f /etc/bashrc ]; then \
			echo "Moving /etc/bashrc to /etc/bashrc.before-nix-darwin..."; \
			sudo mv /etc/bashrc /etc/bashrc.before-nix-darwin; \
		fi; \
		sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#$(CURRENT_HOST) 2>&1 \
			| $(SWITCH_FILTER); \
		EXIT=$${PIPESTATUS[0]}; \
	fi; \
	if [ "$$EXIT" -ne 0 ]; then \
		printf "\n$(RED)✗ darwin-rebuild failed (exit $$EXIT)$(RESET)\n"; \
		exit "$$EXIT"; \
	fi
else
ifeq ($(IS_NIXOS),1)
	@sudo nixos-rebuild switch --flake .#$(CURRENT_HOST)
else
	@home-manager switch --flake .#$(CURRENT_HOST)
endif
endif
	@echo ""
	@printf "$(GREEN)✓ Configuration applied: $(CURRENT_HOST)$(RESET)\n"

diff: ## Show pending changes (auto-detects current host, or use HOST=<name>)
	@if [ -z "$(CURRENT_HOST)" ]; then \
		printf "$(YELLOW)No host specified and could not auto-detect.$(RESET)\n"; \
		echo "Use: make diff HOST=<name>"; \
		echo "Or: make list"; \
		exit 1; \
	fi
	@printf "$(BOLD)Checking changes for: $(CYAN)$(CURRENT_HOST)$(RESET)\n"
	@echo ""
ifeq ($(UNAME),Darwin)
	@if command -v darwin-rebuild >/dev/null 2>&1; then \
		darwin-rebuild build --flake .#$(CURRENT_HOST) && \
			nix --extra-experimental-features 'nix-command flakes' store diff-closures \
				/run/current-system ./result; \
	else \
		printf "$(YELLOW)darwin-rebuild not found — run 'make switch' first to bootstrap nix-darwin.$(RESET)\n"; \
		exit 1; \
	fi
else
ifeq ($(IS_NIXOS),1)
	@sudo nixos-rebuild build --flake .#$(CURRENT_HOST) && \
		nix --extra-experimental-features 'nix-command flakes' store diff-closures \
			/run/current-system ./result
else
	@home-manager build --flake .#$(CURRENT_HOST) && \
		nix --extra-experimental-features 'nix-command flakes' store diff-closures \
			~/.local/state/home-manager/profiles/home-manager ./result
endif
endif

apply: ## Apply configuration for specific host: make apply HOST=<name>
	@if [ -z "$(HOST)" ]; then \
		printf "$(YELLOW)HOST is required.$(RESET)\n"; \
		echo "Use: make apply HOST=<name>"; \
		echo "Or: make list"; \
		echo "Or: make switch  (auto-detects current host)"; \
		exit 1; \
	fi
	@$(MAKE) --no-print-directory switch HOST=$(HOST)

rollback: ## Roll back to previous generation
	@printf "$(BOLD)Rolling back to previous generation...$(RESET)\n"
ifeq ($(UNAME),Darwin)
	@if command -v darwin-rebuild >/dev/null 2>&1; then \
		sudo darwin-rebuild --rollback; \
	else \
		printf "$(YELLOW)darwin-rebuild not found — cannot rollback$(RESET)\n"; \
		exit 1; \
	fi
else
	@if [ "$(IS_NIXOS)" = "1" ]; then \
		sudo nixos-rebuild switch --rollback; \
	elif command -v home-manager >/dev/null 2>&1; then \
		home-manager generations | head -2 | tail -1 | awk '{print $$NF}' | xargs -I {} bash -c "{}/activate"; \
	else \
		printf "$(YELLOW)home-manager not found — cannot rollback$(RESET)\n"; \
		exit 1; \
	fi
endif
	@printf "$(GREEN)✓ Rolled back to previous generation$(RESET)\n"

# ── Host Shortcuts ─────────────────────────────────────────────────────────

switch-studio: ## Switch Apple Studio M2 Max
	@$(MAKE) --no-print-directory switch HOST=apple-studio-m2-max

switch-macbook: ## Switch Apple MacBook M3 Pro
	@$(MAKE) --no-print-directory switch HOST=apple-macbook-m3-pro

switch-cmdr: ## Switch cmdr (Arch Linux)
	@$(MAKE) --no-print-directory switch HOST=cmdr

switch-cachyos: ## Switch CachyOS
	@$(MAKE) --no-print-directory switch HOST=cachyos

diff-studio: ## Diff Apple Studio M2 Max
	@$(MAKE) --no-print-directory diff HOST=apple-studio-m2-max

diff-macbook: ## Diff Apple MacBook M3 Pro
	@$(MAKE) --no-print-directory diff HOST=apple-macbook-m3-pro

diff-cmdr: ## Diff cmdr (Arch Linux)
	@$(MAKE) --no-print-directory diff HOST=cmdr

diff-cachyos: ## Diff CachyOS
	@$(MAKE) --no-print-directory diff HOST=cachyos

# ── Testing (Linux only) ───────────────────────────────────────────────────

# Guard: reject macOS for container-based targets
define LINUX_GUARD
	@printf "$(YELLOW)Container tests are not supported on macOS due to emulation limitations.$(RESET)\n"
	@echo "These tests are designed to run on native Linux systems only."
	@exit 1
endef

# Guard: require a reachable Docker daemon
define DOCKER_GUARD
	@if ! docker info >/dev/null 2>&1; then \
		printf "$(RED)✗ Docker daemon is not reachable$(RESET)\n"; \
		echo "  Start it and retry: sudo systemctl enable --now docker"; \
		exit 1; \
	fi
endef

# Host used by container tests. Defaults to `cmdr` (cli+tui only, safe to
# activate headless); override with HOST=<name> or TEST_HOST=<name>.
# GUI/desktop hosts (e.g. strix-nix) pull in Hyprland/DMS and won't activate
# in a container.
TEST_HOST := $(or $(HOST),cmdr)

test: ## Build and start Linux test container (Linux only)
ifneq ($(UNAME),Darwin)
	$(DOCKER_GUARD)
	@echo "Starting Linux test container..."
	@cd containers && docker compose -f compose.yml up --build
else
	$(LINUX_GUARD)
endif

test-shell: ## Start container and enter interactive shell (Linux only)
ifneq ($(UNAME),Darwin)
	$(DOCKER_GUARD)
	@echo "Entering Linux container shell..."
	@cd containers && docker compose -f compose.yml run --rm linux-test /bin/bash
else
	$(LINUX_GUARD)
endif

test-run: ## Automated container test: build, provision, verify, teardown (Linux only)
ifneq ($(UNAME),Darwin)
	@bash scripts/container-test.sh "$(TEST_HOST)"
else
	$(LINUX_GUARD)
endif

test-tty: ## Build container, provision $(TEST_HOST) config, open interactive zsh (Linux only)
ifneq ($(UNAME),Darwin)
	$(DOCKER_GUARD)
	@echo "Building container..."
	@cd containers && docker compose -f compose.yml up -d --build
	@echo "Provisioning $(TEST_HOST) config..."
	@cd containers && docker compose -f compose.yml exec -T -e USER=cmdr -e HOME=/home/cmdr linux-test bash -c "\
		if ! command -v nix &> /dev/null && [ ! -f /nix/var/nix/profiles/default/bin/nix ]; then \
			/home/nixuser/install-nix.sh; \
		fi && \
		sudo ln -sfn /home/nixuser /home/cmdr && \
		sudo /nix/var/nix/profiles/default/bin/nix-daemon &>/tmp/nix-daemon.log & \
		sleep 2 && \
		. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && \
		git config --global --add safe.directory /workspace && \
		rm -rf /tmp/cmdr-src /tmp/meta-src && \
		cp -a /workspace/. /tmp/cmdr-src/ && \
		rm -rf /tmp/cmdr-src/.git /tmp/cmdr-src/.direnv && \
		mkdir -p /tmp/meta-src && \
		git -C /meta archive HEAD | tar -x -C /tmp/meta-src && \
		rm -f /home/nixuser/.zshrc && \
		cd /tmp/cmdr-src && \
		nix run .#homeConfigurations.$(TEST_HOST).activationPackage --override-input meta /tmp/meta-src"
	@echo "Dropping into interactive shell..."
	@cd containers && docker compose -f compose.yml exec linux-test /bin/zsh
else
	$(LINUX_GUARD)
endif

test-clean: ## Stop containers and cleanup (Linux only)
ifneq ($(UNAME),Darwin)
	@echo "Cleaning up containers and volumes..."
	@cd containers && docker compose -f compose.yml down -v
	@printf "$(GREEN)✓ Cleanup complete$(RESET)\n"
else
	$(LINUX_GUARD)
endif

# ── Module Tier Management ─────────────────────────────────────────────────

# Module categories to scan
TIER_CATEGORIES := cli tui gui

tiers: ## Show module adoption tiers (graduated, incubating, sandbox)
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@printf "$(BOLD)cmdr — Module Adoption Tiers$(RESET)\n"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@G=0; I=0; S=0; \
	for cat in $(TIER_CATEGORIES); do \
		printf "$(BOLD)%s/$(RESET)\n" "$$cat"; \
		for tier in graduated incubating sandbox; do \
			dir="home/04-modules/$$cat/$$tier"; \
			if [ -d "$$dir" ]; then \
				modules=$$(ls -d "$$dir"/*/ 2>/dev/null | xargs -I{} basename {} | sort); \
				if [ -n "$$modules" ]; then \
					case "$$tier" in \
						graduated)  color="$(GREEN)"; ;; \
						incubating) color="$(YELLOW)"; ;; \
						sandbox)    color="$(CYAN)"; ;; \
					esac; \
					for m in $$modules; do \
						printf "  %b%-11s%b %s\n" "$$color" "$$tier" "$(RESET)" "$$m"; \
						case "$$tier" in \
							graduated)  G=$$((G+1)); ;; \
							incubating) I=$$((I+1)); ;; \
							sandbox)    S=$$((S+1)); ;; \
						esac; \
					done; \
				fi; \
			fi; \
		done; \
		echo ""; \
	done; \
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; \
	printf "$(GREEN)graduated$(RESET): $$G  $(YELLOW)incubating$(RESET): $$I  $(CYAN)sandbox$(RESET): $$S  total: $$((G+I+S))\n"; \
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

promote: ## Promote a module: make promote MODULE=<name> FROM=<tier> TO=<tier> [CAT=cli|tui|gui]
	@if [ -z "$(MODULE)" ] || [ -z "$(FROM)" ] || [ -z "$(TO)" ]; then \
		printf "$(YELLOW)Usage: make promote MODULE=<name> FROM=<tier> TO=<tier> [CAT=cli|tui|gui]$(RESET)\n"; \
		echo ""; \
		echo "Example: make promote MODULE=opencode FROM=incubating TO=graduated CAT=cli"; \
		exit 1; \
	fi
	@# Auto-detect category if not specified
	@if [ -z "$(CAT)" ]; then \
		FOUND=""; \
		for cat in $(TIER_CATEGORIES); do \
			if [ -d "home/04-modules/$$cat/$(FROM)/$(MODULE)" ]; then \
				FOUND="$$cat"; \
				break; \
			fi; \
		done; \
		if [ -z "$$FOUND" ]; then \
			printf "$(YELLOW)Module '$(MODULE)' not found in $(FROM) tier.$(RESET)\n"; \
			exit 1; \
		fi; \
		CAT_RESOLVED="$$FOUND"; \
	else \
		CAT_RESOLVED="$(CAT)"; \
	fi; \
	SRC="home/04-modules/$$CAT_RESOLVED/$(FROM)/$(MODULE)"; \
	DST="home/04-modules/$$CAT_RESOLVED/$(TO)/$(MODULE)"; \
	if [ ! -d "$$SRC" ]; then \
		printf "$(YELLOW)Source not found: $$SRC$(RESET)\n"; \
		exit 1; \
	fi; \
	if [ -d "$$DST" ]; then \
		printf "$(YELLOW)Destination already exists: $$DST$(RESET)\n"; \
		exit 1; \
	fi; \
	mkdir -p "$$(dirname "$$DST")"; \
	git mv "$$SRC" "$$DST"; \
	printf "$(GREEN)✓ Promoted $(MODULE): $(FROM) → $(TO) ($$CAT_RESOLVED)$(RESET)\n"; \
	echo ""; \
	printf "$(BOLD)Next steps:$(RESET)\n"; \
	echo "  1. Update import paths in the feature file (home/03-features/$$CAT_RESOLVED.nix)"; \
	echo "  2. If the module imports _shared/theme, verify the relative path is still correct"; \
	echo "  3. Run: make switch"

# ── Alias Management ──────────────────────────────────────────────────────

# Directories to scan for alias definitions
ALIAS_SCAN_DIRS := home/04-modules home/05-platforms

aliases: ## List all shell aliases grouped by module, with audit warnings
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@printf "$(BOLD)cmdr — Shell Alias Inventory$(RESET)\n"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@ALL_NAMES=$$(mktemp); ALL_CMDS=$$(mktemp); \
	trap "rm -f $$ALL_NAMES $$ALL_CMDS" EXIT; \
	\
	for dir in $(ALIAS_SCAN_DIRS); do \
		[ -d "$$dir" ] || continue; \
		find "$$dir" -name '*.nix' -type f | sort | while read -r nf; do \
			MOD=$$(echo "$$nf" \
				| sed 's|home/04-modules/||;s|home/05-platforms/||;s|/default\.nix$$||;s|\.nix$$||'); \
			HEADER=""; \
			\
			SA=$$(awk ' \
				/shellAliases[[:space:]]*=[[:space:]]*\{/ { d=1; next } \
				d>0 { \
					for(i=1;i<=length($$0);i++){ \
						c=substr($$0,i,1); \
						if(c=="{")d++; \
						if(c=="}"){ d--; if(d==0) next } \
					} \
					if(d>0){ \
						line=$$0; sub(/^[[:space:]]*/,"",line); sub(/;[[:space:]]*$$/,"",line); \
					sub(/;[[:space:]]*#.*$$/,"",line); \
						if(line ~ /^#/ || line=="") next; \
						eq=index(line,"="); \
						if(eq>0){ \
							aname=substr(line,1,eq-1); sub(/[[:space:]]*$$/,"",aname); gsub(/"/,"",aname); \
							aval=substr(line,eq+1);     sub(/^[[:space:]]*/,"",aval); \
							if(aname !~ /^[a-zA-Z._-]+$$/) next; \
						if(aname == "let" || aname == "in") next; \
							print aname "|" aval \
						} \
					} \
				}' "$$nf" 2>/dev/null); \
			if [ -n "$$SA" ]; then \
				if [ -z "$$HEADER" ]; then printf "\n$(BOLD)%s$(RESET)\n" "$$MOD"; HEADER=1; fi; \
				echo "$$SA" | while IFS='|' read -r aname aval; do \
					printf "  $(CYAN)%-14s$(RESET) %s\n" "$$aname" "$$aval"; \
					echo "$$aname|$$nf" >> "$$ALL_NAMES"; \
					echo "$$aval" >> "$$ALL_CMDS"; \
				done; \
			fi; \
			\
			FN=$$(sed -n 's/^[[:space:]]*function[[:space:]]\{1,\}\([a-zA-Z_][a-zA-Z0-9_]*\)().*/\1/p' "$$nf" 2>/dev/null); \
			if [ -n "$$FN" ]; then \
				if [ -z "$$HEADER" ]; then printf "\n$(BOLD)%s$(RESET)\n" "$$MOD"; HEADER=1; fi; \
				echo "$$FN" | while read -r fname; do \
					printf "  $(CYAN)%-14s$(RESET) shell function\n" "$$fname()"; \
					echo "$$fname|$$nf" >> "$$ALL_NAMES"; \
				done; \
			fi; \
			\
			RA=$$(sed -n 's/^[[:space:]]*alias[[:space:]]\{1,\}\([a-zA-Z_][a-zA-Z0-9_-]*\)=\(.*\)/\1|\2/p' "$$nf" 2>/dev/null); \
			if [ -n "$$RA" ]; then \
				if [ -z "$$HEADER" ]; then printf "\n$(BOLD)%s$(RESET)\n" "$$MOD"; HEADER=1; fi; \
				echo "$$RA" | while IFS='|' read -r rname rval; do \
					printf "  $(CYAN)%-14s$(RESET) %s\n" "$$rname" "$$rval"; \
					echo "$$rname|$$nf" >> "$$ALL_NAMES"; \
					echo "$$rval" >> "$$ALL_CMDS"; \
				done; \
			fi; \
		done; \
	done; \
	\
	TOTAL=$$(wc -l < "$$ALL_NAMES" | tr -d ' '); \
	echo ""; \
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; \
	printf "$(BOLD)Audit$(RESET)  ($$TOTAL aliases/functions total)\n"; \
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; \
	echo ""; \
	\
	DUPES_FOUND=0; \
	DUPE_NAMES=$$(cut -d'|' -f1 "$$ALL_NAMES" | sort | uniq -d); \
	if [ -n "$$DUPE_NAMES" ]; then \
		for dn in $$DUPE_NAMES; do \
			FILES=$$(grep "^$$dn|" "$$ALL_NAMES" | cut -d'|' -f2 | sort -u | tr '\n' ' '); \
			printf "  $(YELLOW)[warn]$(RESET) duplicate $(BOLD)$$dn$(RESET) in: $$FILES\n"; \
			DUPES_FOUND=$$((DUPES_FOUND + 1)); \
		done; \
	fi; \
	if [ "$$DUPES_FOUND" -eq 0 ]; then \
		printf "  $(GREEN)[pass]$(RESET) No duplicate aliases\n"; \
	fi; \
	echo ""; \
	\
	DEAD_FOUND=0; \
	sed 's/^"//;s/[" ].*//' "$$ALL_CMDS" | tr -d "'" | sort -u | while read -r cmd; do \
		case "$$cmd" in \
			""|cd|source|eval|echo|printf|export|return|local|if|then|else|fi|deactivate) continue ;; \
			*"/"*|*"{"*|*"}"*|*"("*|*")"*|*'$$'*|*";"*|*"~"*|*"="*) continue ;; \
		esac; \
		if ! command -v "$$cmd" >/dev/null 2>&1; then \
			printf "  $(YELLOW)[warn]$(RESET) $(BOLD)$$cmd$(RESET) not found in PATH\n"; \
			DEAD_FOUND=$$((DEAD_FOUND + 1)); \
		fi; \
	done; \
	if [ "$${DEAD_FOUND:-0}" -eq 0 ]; then \
		printf "  $(GREEN)[pass]$(RESET) All alias targets found in PATH\n"; \
	fi; \
	echo ""; \
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

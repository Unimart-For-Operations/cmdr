#!/usr/bin/env bash
# scripts/bootstrap.sh — Idempotent prerequisites installer
#
# Gets a bare machine from "has bash + curl" to "ready for make apply".
# Handles: Xcode CLT (macOS), Homebrew (macOS), Nix (all platforms).
#
# Usage:
#   bash scripts/bootstrap.sh          # run from inside the repo
#   curl -fsSL <raw-url> | bash        # run before cloning (future)
#
# Safe to run multiple times — every step checks before acting.

set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Helpers ───────────────────────────────────────────────────────────────
info() { printf "${CYAN}[info]${RESET}  %s\n" "$*"; }
ok() { printf "${GREEN}[ok]${RESET}    %s\n" "$*"; }
warn() { printf "${YELLOW}[warn]${RESET}  %s\n" "$*"; }
fail() {
	printf "${RED}[fail]${RESET}  %s\n" "$*" >&2
	exit 1
}
step() { printf "\n${BOLD}── %s ──${RESET}\n" "$*"; }

# ── Detect platform ──────────────────────────────────────────────────────
OS="$(uname -s)"   # Darwin | Linux
ARCH="$(uname -m)" # arm64 / aarch64 / x86_64

case "$OS" in
Darwin) PLATFORM="macOS" ;;
Linux) PLATFORM="Linux" ;;
*) fail "Unsupported OS: $OS" ;;
esac

info "Detected: $PLATFORM ($ARCH)"

# ── Step 1: Xcode Command Line Tools (macOS only) ────────────────────────
if [[ "$OS" == "Darwin" ]]; then
	step "Xcode Command Line Tools"
	if xcode-select -p &>/dev/null; then
		ok "Xcode CLT already installed"
	else
		info "Installing Xcode Command Line Tools..."
		xcode-select --install 2>/dev/null || true
		# Wait for the installer to finish
		info "Waiting for Xcode CLT installation to complete..."
		until xcode-select -p &>/dev/null; do
			sleep 5
		done
		ok "Xcode CLT installed"
	fi
fi

# ── Step 2: Homebrew (macOS only) ────────────────────────────────────────
if [[ "$OS" == "Darwin" ]]; then
	step "Homebrew"
	if command -v brew &>/dev/null; then
		ok "Homebrew already installed ($(brew --version | head -1))"
	else
		info "Installing Homebrew..."
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

		# Add Homebrew to PATH for the rest of this script
		if [[ "$ARCH" == "arm64" ]]; then
			eval "$(/opt/homebrew/bin/brew shellenv)"
		else
			eval "$(/usr/local/bin/brew shellenv)"
		fi
		ok "Homebrew installed"
	fi
fi

# ── Step 3: Nix ──────────────────────────────────────────────────────────
step "Nix"
if command -v nix &>/dev/null; then
	ok "Nix already installed ($(nix --version))"
else
	# Check if we're on NixOS (Nix is present but maybe not in this shell)
	if [[ -f /etc/NIXOS ]]; then
		warn "NixOS detected but 'nix' not in PATH — sourcing profile"
		# shellcheck disable=SC1091
		. /etc/profile.d/nix.sh 2>/dev/null || true
		if command -v nix &>/dev/null; then
			ok "Nix available after sourcing profile ($(nix --version))"
		else
			fail "NixOS detected but cannot find nix in PATH"
		fi
	else
		info "Installing Nix via Determinate Systems installer..."
		curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix |
			sh -s -- install

		# Source Nix profile so it's available for the rest of this session.
		# The Determinate installer uses the daemon model on both platforms.
		if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
			# shellcheck disable=SC1091
			. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
		elif [[ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]]; then
			# shellcheck disable=SC1091
			. "$HOME/.nix-profile/etc/profile.d/nix.sh"
		fi

		if command -v nix &>/dev/null; then
			ok "Nix installed ($(nix --version))"
		else
			warn "Nix installed but not in current shell PATH"
			warn "Restart your shell (exec zsh) then continue"
		fi
	fi
fi

# ── Step 4: Verify flakes ────────────────────────────────────────────────
step "Flakes"
if command -v nix &>/dev/null; then
	if nix flake --help &>/dev/null 2>&1; then
		ok "Flakes enabled"
	else
		warn "Nix is installed but flakes are not enabled"
		warn "The Determinate installer should enable flakes by default"
		warn "If you used a different installer, add to ~/.config/nix/nix.conf:"
		warn "  experimental-features = nix-command flakes"
	fi
else
	warn "Skipping flakes check — Nix not in current PATH"
fi

# ── Summary ───────────────────────────────────────────────────────────────
step "Bootstrap complete"

printf "\n"
if [[ "$OS" == "Darwin" ]]; then
	ok "Xcode CLT:  installed"
	ok "Homebrew:   installed"
fi
ok "Nix:        installed"
printf "\n"

echo "Next steps:"
echo ""
echo "  1. Restart your shell to pick up Nix in PATH:"
echo "       exec zsh"
echo ""
echo "  2. If this is a new machine, register it:"
echo "       make register"
echo ""
echo "  3. Apply your configuration:"
echo "       make switch"
echo ""
echo "  4. Verify everything:"
echo "       make doctor"
echo ""

#!/usr/bin/env bash
# Export a theme from the cmdr theme switchboard as JSON
# Usage: ./scripts/theme-export.sh [theme-name]

set -euo pipefail

THEME_NAME="${1:-catppuccin-frappe}"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

if ! command -v nix >/dev/null 2>&1; then
	echo "nix is required to export the theme" >&2
	exit 2
fi

# Import the callable switchboard and serialize to JSON. Use impure evaluation
# so relative paths work when running from the checked-out repository.
nix eval --impure --raw --expr "builtins.toJSON ((import ./home/04-modules/_shared/theme/default.nix).call \"${THEME_NAME}\")"

#!/usr/bin/env bash
# scripts/check-theme-lint.sh — Lint for direct palette imports and hex colors
#
# Fails if any Nix module under home/ imports palettes/ directly or contains
# raw 6-digit hex color literals (e.g. #aabbcc), excluding the canonical
# palette files in home/04-modules/_shared/theme/palettes.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAIL=0

echo "[lint] scanning Nix modules under: $REPO_ROOT/home"

find "$REPO_ROOT/home" -name '*.nix' -type f | while IFS= read -r file; do
	# Skip the shared palette files and the switchboard itself
	case "$file" in
	*"/home/04-modules/_shared/theme/palettes/"* | *"/home/04-modules/_shared/theme/palettes" | *"/home/04-modules/_shared/theme/default.nix")
		continue
		;;
	esac

	# 1) Direct palette imports
	if grep -En "palettes[\\/].*\.nix|\.\/palettes\/|import[[:space:]]+.*palettes" "$file" >/dev/null 2>&1; then
		echo "[lint][error] direct palette import in: $file"
		grep -En "palettes[\\/].*\.nix|\.\/palettes\/|import[[:space:]]+.*palettes" "$file" || true
		FAIL=1
	fi

	# 2) Raw 6-digit hex color literals (ignore hashed strings like URL fragments by
	# requiring a leading non-word or start-of-line and a trailing non-word)
	if grep -En "(^|[^A-Za-z0-9_])#[0-9a-fA-F]{6}([^A-Za-z0-9_]|$)" "$file" >/dev/null 2>&1; then
		echo "[lint][error] raw hex color literal in: $file"
		grep -En "(^|[^A-Za-z0-9_])#[0-9a-fA-F]{6}([^A-Za-z0-9_]|$)" "$file" || true
		FAIL=1
	fi
done

if [ "$FAIL" -ne 0 ]; then
	echo ""
	echo "[lint] Found disallowed theme usages. Use the theme switchboard instead:" \
		"(import ./home/04-modules/_shared/theme).call(<theme-name>)"
	echo "Exclude the canonical palette files in home/04-modules/_shared/theme/palettes/*"
	exit 1
fi

echo "[lint] OK — no direct palette imports or raw hex literals found in home/**/*.nix"
exit 0

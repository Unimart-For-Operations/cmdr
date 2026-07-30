#!/usr/bin/env bash
# scripts/inject-frontmatter.sh — Add/update source metadata in synced markdown files
#
# Ensures every .md file in a target directory has YAML frontmatter with:
#   source: <repo-name>
#   synced: <ISO date>
#
# Idempotent: updates existing fields, adds frontmatter block if missing.
# Skips files that already have correct values (fast no-op on repeat runs).
# Pure shell — no yq dependency (frontmatter is simple key-value pairs).
#
# Usage:
#   inject-frontmatter.sh <target-dir> <source-name>
#   inject-frontmatter.sh ~/Documents/cmdr/.../cmdr cmdr
#
# Called by the org-level docs repo sync pipeline (Phase 3).

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'

TARGET_DIR="${1:-}"
SOURCE_NAME="${2:-}"

if [ -z "$TARGET_DIR" ] || [ -z "$SOURCE_NAME" ]; then
	printf "${RED}x${RESET} Usage: inject-frontmatter.sh <target-dir> <source-name>\n"
	exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
	printf "${RED}x${RESET} Target directory not found: %s\n" "$TARGET_DIR"
	exit 1
fi

TODAY=$(date +%Y-%m-%d)
COUNT=0
SKIPPED=0

inject_file() {
	local file="$1"

	# Read first line to check for existing frontmatter
	local first_line
	first_line=$(head -1 "$file")

	if [ "$first_line" = "---" ]; then
		# Has frontmatter — find the closing --- line number
		local close_line
		close_line=$(awk '/^---$/{n++; if(n==2){print NR; exit}}' "$file")

		if [ -z "$close_line" ]; then
			# Malformed frontmatter (no closing ---), skip
			return
		fi

		# Extract frontmatter body (between the --- delimiters)
		local fm_body
		fm_body=$(sed -n "2,$((close_line - 1))p" "$file")

		# Check if already up to date (fast path)
		local cur_source cur_synced
		cur_source=$(printf '%s\n' "$fm_body" | grep '^source:' | sed 's/^source:[[:space:]]*//' || echo "")
		cur_synced=$(printf '%s\n' "$fm_body" | grep '^synced:' | sed 's/^synced:[[:space:]]*//' || echo "")

		if [ "$cur_source" = "$SOURCE_NAME" ] && [ "$cur_synced" = "$TODAY" ]; then
			SKIPPED=$((SKIPPED + 1))
			return
		fi

		# Update: strip old source/synced lines, prepend new ones
		local updated_fm
		updated_fm=$(printf '%s\n' "$fm_body" | grep -v '^source:' | grep -v '^synced:' || true)

		local tmpfile
		tmpfile=$(mktemp)
		{
			echo "---"
			echo "source: $SOURCE_NAME"
			echo "synced: $TODAY"
			if [ -n "$updated_fm" ]; then
				printf '%s\n' "$updated_fm"
			fi
			# From the closing --- onward (includes the --- and everything after)
			tail -n +"$close_line" "$file"
		} >"$tmpfile"
	else
		# No frontmatter — prepend new block
		local tmpfile
		tmpfile=$(mktemp)
		{
			echo "---"
			echo "source: $SOURCE_NAME"
			echo "synced: $TODAY"
			echo "---"
			cat "$file"
		} >"$tmpfile"
	fi

	mv "$tmpfile" "$file"
	COUNT=$((COUNT + 1))
}

while IFS= read -r -d '' file; do
	inject_file "$file"
done < <(find "$TARGET_DIR" -name '*.md' -type f -print0)

printf "${GREEN}v${RESET} Frontmatter: %s updated, %s already current (%s)\n" "$COUNT" "$SKIPPED" "$SOURCE_NAME"

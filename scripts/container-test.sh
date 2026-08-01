#!/usr/bin/env bash
# scripts/container-test.sh — Automated container smoke test for cmdr.
#
# Builds the Ubuntu 24.04 test container, provisions a Home Manager config,
# verifies the key tools are on PATH, then tears the container down.
# Fails (non-zero exit) on any step that does not succeed, so it can be wired
# into `make ci-full`.
#
# Usage: scripts/container-test.sh [HOST]
#   HOST   Home Manager host to provision (default: cmdr).

set -euo pipefail

TEST_HOST="${1:-cmdr}"
COMPOSE_FILE="$(cd "$(dirname "$0")/../containers" && pwd)/compose.yml"

cleanup() {
	docker compose -f "${COMPOSE_FILE}" down -v >/dev/null 2>&1 || true
}
trap cleanup EXIT

if ! docker info >/dev/null 2>&1; then
	echo "[fail] Docker daemon is not reachable" >&2
	echo "       Start it and retry: sudo systemctl enable --now docker" >&2
	exit 1
fi

echo "[1/4] Building and starting container..."
docker compose -f "${COMPOSE_FILE}" up -d --build

echo "[2/4] Waiting for Nix install..."
NIX_BIN="/nix/var/nix/profiles/default/bin/nix"
ready=0
for _ in $(seq 1 60); do
	if docker compose -f "${COMPOSE_FILE}" exec -T linux-test bash -c "test -x ${NIX_BIN}" >/dev/null 2>&1; then
		ready=1
		break
	fi
	sleep 5
done
if [ "${ready}" -ne 1 ]; then
	echo "[fail] timed out waiting for Nix install in container" >&2
	exit 1
fi
echo "  nix: $(docker compose -f "${COMPOSE_FILE}" exec -T linux-test bash -c "source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && nix --version")"

echo "[3/4] Provisioning home config (${TEST_HOST})..."
# /workspace is a read-only mount and, because cmdr is a git submodule of the
# meta repo, its .git is a file pointing outside the mount. Nix would try to
# open `git+file:///workspace` and fail. Copy the source into a writable dir
# and strip the git metadata so Nix treats it as a plain path flake.
#
# The private `meta` input is also overridden with a local path copy: the
# container's Determinate Nix bundles a different libgit2 than the host's
# nixpkgs nix, so a `git+ssh` re-fetch computes a different narHash than the
# one pinned in flake.lock and fails. A path copy avoids the fetch entirely.
docker compose -f "${COMPOSE_FILE}" exec -T \
	-e USER=cmdr -e HOME=/home/cmdr linux-test bash -c "
	sudo ln -sfn /home/nixuser /home/cmdr &&
	sudo /nix/var/nix/profiles/default/bin/nix-daemon &>/tmp/nix-daemon.log &
	sleep 2 &&
	. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh &&
	git config --global --add safe.directory /workspace &&
	rm -rf /tmp/cmdr-src /tmp/meta-src &&
	cp -a /workspace/. /tmp/cmdr-src/ &&
	rm -rf /tmp/cmdr-src/.git /tmp/cmdr-src/.direnv &&
	mkdir -p /tmp/meta-src &&
	git -C /meta archive HEAD | tar -x -C /tmp/meta-src &&
	rm -f /home/nixuser/.zshrc &&
	cd /tmp/cmdr-src &&
	nix run .#homeConfigurations.${TEST_HOST}.activationPackage --override-input meta /tmp/meta-src
"

echo "[4/4] Verifying provisioned config..."
docker compose -f "${COMPOSE_FILE}" exec -T \
	-e USER=cmdr -e HOME=/home/cmdr linux-test zsh -l -c '
	# Real hosts get ~/.nix-profile/bin on PATH via the nix install shell
	# hook (profile.d); the container installs nix with --init none, so
	# prepend it here to match a provisioned host before checking tools.
	export PATH="$HOME/.nix-profile/bin:$PATH"
	fail=0
	for tool in zsh starship nvim git rg fd fzf bat eza zoxide atuin; do
		if command -v "${tool}" >/dev/null 2>&1; then
			echo "  [pass] ${tool}"
		else
			echo "  [fail] ${tool}"
			fail=1
		fi
	done
	if [[ -f "$HOME/.zshrc" ]]; then
		echo "  [pass] ~/.zshrc"
	else
		echo "  [fail] ~/.zshrc"
		fail=1
	fi
	if [[ "${EDITOR:-}" == "nvim" ]]; then
		echo "  [pass] EDITOR=${EDITOR}"
	else
		echo "  [fail] EDITOR=${EDITOR:-<unset>}"
		fail=1
	fi
	exit "${fail}"
'

echo "  [pass] container test passed: ${TEST_HOST}"

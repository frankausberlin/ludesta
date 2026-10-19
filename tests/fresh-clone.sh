#!/usr/bin/env bash
# Verify that a fresh clone works without local state such as ignore/.
#
# This script clones the current repository (the last commit) into a temporary
# directory, runs the fast test level, initializes one app, and runs the
# generated quality gate.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/lupysta-fresh-XXXXXX")"
CLONE="$TMP_ROOT/clone"

cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

git clone -q --no-local "$REPO_ROOT" "$CLONE"

if [[ -d "$CLONE/ignore" ]]; then
    echo "error: ignore/ must not be part of a fresh clone" >&2
    exit 1
fi

cd "$CLONE"
bash tests/test-pyinit.sh --fast

# shellcheck source=/dev/null
source "$CLONE/Luxus-Python-Stack/luxuspythonstack.sh"
pyinit "$TMP_ROOT/app" --python 3.12

cd "$TMP_ROOT/app"
just check

echo "fresh clone test passed"

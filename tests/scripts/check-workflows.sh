#!/usr/bin/env bash
# Lint the GitHub Actions workflows of this repository and of the project templates.
#
# Uses a local actionlint when it is on PATH, otherwise the official Docker
# image. Fails with a clear message when neither is available.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

shopt -s nullglob
WORKFLOWS=(
    "$REPO_ROOT"/.github/workflows/*.yml
    "$REPO_ROOT"/Luxus-Python-Stack/templates/workflows/*.yml
)
shopt -u nullglob

if [[ ${#WORKFLOWS[@]} -eq 0 ]]; then
    echo "error: no workflow files found to check" >&2
    exit 1
fi

if command -v actionlint >/dev/null 2>&1; then
    actionlint "${WORKFLOWS[@]}"
    echo "actionlint checked ${#WORKFLOWS[@]} workflow file(s)"
    exit 0
fi

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    RELATIVE=()
    for workflow in "${WORKFLOWS[@]}"; do
        RELATIVE+=("${workflow#"$REPO_ROOT"/}")
    done
    docker run --rm -v "$REPO_ROOT:/repo" -w /repo rhysd/actionlint:latest "${RELATIVE[@]}"
    echo "actionlint (docker) checked ${#RELATIVE[@]} workflow file(s)"
    exit 0
fi

echo "error: actionlint is not installed and Docker is not available." >&2
echo "       Install actionlint or provide a working Docker daemon." >&2
exit 1

#!/usr/bin/env bash
# Run the opt-in agent suite. An empty suite exits 0 before any provider call.
set -euo pipefail

cd "$(dirname "$0")/.."

shopt -s nullglob
tests=(tests/agent/test_*.py)
if [[ ${#tests[@]} -eq 0 ]]; then
    cat >&2 <<'MSG'
No agent tests configured yet.
Add tests/agent/test_*.py and run `just test-agent` again.
See tests/agent/README.md for the expected structure.
MSG
    exit 0
fi

if ! command -v uv >/dev/null 2>&1; then
    echo "Error: 'uv' is not installed or not on PATH; agent tests need uv." >&2
    exit 1
fi

LUPYSTA_AGENT=1 uv run pytest tests/agent -v -s

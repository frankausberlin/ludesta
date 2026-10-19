#!/usr/bin/env bash
# Check relative Markdown links in tracked files.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$SCRIPT_DIR/check_links.py" "$@"

#!/usr/bin/env bash
# Test the stack shell library.
#
# Checks that sourcing the library provides the shell functions and aliases and
# that it no longer provides the generator. The prompt test needs zsh.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SCRIPT="$REPO_ROOT/Luxus-Python-Stack/scripts/luxuspythonstack.sh"

PASS=0
FAIL=0
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/ludesta-test-XXXXXX")"

cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

pass() {
    PASS=$((PASS + 1))
    printf 'ok - %s\n' "$1"
}

fail() {
    FAIL=$((FAIL + 1))
    printf 'not ok - %s\n' "$1" >&2
}

if bash -c "source '$SCRIPT'; declare -F jupyter-launcher >/dev/null"; then
    pass "sourcing defines jupyter-launcher"
else
    fail "sourcing defines jupyter-launcher"
fi

if bash -c "source '$SCRIPT'; declare -F prompt_my_jupyter >/dev/null"; then
    pass "sourcing defines prompt_my_jupyter"
else
    fail "sourcing defines prompt_my_jupyter"
fi

if bash -c "source '$SCRIPT'; declare -F pyinit >/dev/null"; then
    fail "sourcing must not define pyinit"
else
    pass "sourcing does not define pyinit"
fi

if command -v zsh >/dev/null 2>&1; then
    mkdir -p "$TMP_ROOT/zsh-data"
    if XDG_DATA_HOME="$TMP_ROOT/zsh-data" \
        zsh -c "source '$SCRIPT'; p10k() { :; }; prompt_my_jupyter; print ok" >"$TMP_ROOT/empty.log" 2>&1; then
        pass "jupyter prompt survives an empty runtime directory"
    else
        fail "jupyter prompt survives an empty runtime directory"
    fi

    mkdir -p "$TMP_ROOT/zsh-data/jupyter/runtime"
    : >"$TMP_ROOT/zsh-data/jupyter/runtime/jpserver-999999.json"
    if XDG_DATA_HOME="$TMP_ROOT/zsh-data" \
        zsh -c "source '$SCRIPT'; p10k() { :; }; prompt_my_jupyter; print ok" >"$TMP_ROOT/single.log" 2>&1; then
        pass "jupyter prompt survives a single runtime file family"
    else
        fail "jupyter prompt survives a single runtime file family"
    fi
else
    echo "# zsh not found; skipping prompt checks"
fi

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[[ $FAIL -eq 0 ]]

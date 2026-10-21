#!/usr/bin/env bash
# Test suite for pyinit and the generated project workflows.
#
# Usage:
#   bash tests/test-pyinit.sh --fast   # argument guards and template preflight
#   bash tests/test-pyinit.sh          # fast plus generated-project integration
#
# The fast level needs no network and creates no projects. The integration
# level creates throwaway projects, resolves dependencies with uv, and runs
# the generated quality gate.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SCRIPT="$REPO_ROOT/Luxus-Python-Stack/scripts/luxuspythonstack.sh"
FAST_ONLY=0
[[ "${1:-}" == "--fast" ]] && FAST_ONLY=1

PASS=0
FAIL=0
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/lupysta-test-XXXXXX")"
LOG="$TMP_ROOT/last.log"

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
    if [[ -f "$LOG" ]]; then
        sed 's/^/    /' "$LOG" >&2
    fi
}

run() {
    "$@" >"$LOG" 2>&1
}

run_in() {
    local directory="$1"
    shift
    (cd "$directory" && "$@") >"$LOG" 2>&1
}

expect_success() {
    local name="$1"
    shift
    if run "$@"; then
        pass "$name"
        return 0
    fi
    fail "$name"
    return 1
}

expect_failure() {
    local name="$1"
    shift
    if run "$@"; then
        fail "$name (unexpected success)"
        return 1
    fi
    pass "$name"
    return 0
}

expect_success_in() {
    local name="$1"
    local directory="$2"
    shift 2
    if run_in "$directory" "$@"; then
        pass "$name"
        return 0
    fi
    fail "$name"
    return 1
}

expect_failure_in() {
    local name="$1"
    local directory="$2"
    shift 2
    if run_in "$directory" "$@"; then
        fail "$name (unexpected success)"
        return 1
    fi
    pass "$name"
    return 0
}

assert_contains() {
    local name="$1"
    local file="$2"
    local expected="$3"
    if grep -qF -- "$expected" "$file"; then
        pass "$name"
    else
        fail "$name (missing: $expected)"
    fi
}

assert_not_contains() {
    local name="$1"
    local file="$2"
    local unexpected="$3"
    if grep -qF -- "$unexpected" "$file"; then
        fail "$name (unexpected: $unexpected)"
    else
        pass "$name"
    fi
}

assert_file() {
    local name="$1"
    local file="$2"
    if [[ -f "$file" ]]; then
        pass "$name"
    else
        fail "$name (missing file: $file)"
    fi
}

assert_dir() {
    local name="$1"
    local directory="$2"
    if [[ -d "$directory" ]]; then
        pass "$name"
    else
        fail "$name (missing directory: $directory)"
    fi
}

# shellcheck source=../Luxus-Python-Stack/scripts/luxuspythonstack.sh
# shellcheck disable=SC1091
source "$SCRIPT"

echo "# Fast checks"

expect_success "pyinit --help exits 0" pyinit --help
assert_contains "help shows usage" "$LOG" "Usage: pyinit"
assert_contains "help shows --no-check" "$LOG" "--no-check"

expect_failure "unknown option is rejected" pyinit --does-not-exist "$TMP_ROOT/unknown"
expect_failure "--python without value is rejected" pyinit --python
expect_failure "invalid Python version is rejected" pyinit --python 3 "$TMP_ROOT/bad-python"
expect_failure "Python older than 3.11 is rejected" pyinit --python 3.10 "$TMP_ROOT/old-python"
expect_failure "--lib --cli is rejected" pyinit --lib --cli "$TMP_ROOT/bad-combo"
expect_failure "too many directories are rejected" pyinit "$TMP_ROOT/one" "$TMP_ROOT/two"
expect_failure "invalid package name is rejected" pyinit "$TMP_ROOT/123bad"
expect_failure "Python keyword is rejected" pyinit "$TMP_ROOT/class"

mkdir -p "$TMP_ROOT/file-target-parent"
: >"$TMP_ROOT/file-target-parent/not-a-dir"
expect_failure "file target is rejected" pyinit "$TMP_ROOT/file-target-parent/not-a-dir"

mkdir -p "$TMP_ROOT/non-empty"
: >"$TMP_ROOT/non-empty/existing.txt"
expect_failure "non-empty target is rejected" pyinit "$TMP_ROOT/non-empty"

mkdir -p "$TMP_ROOT/help-target"
(
    cd "$TMP_ROOT/help-target" || exit 1
    pyinit --help >/dev/null 2>&1
)
if [[ -z "$(ls -A "$TMP_ROOT/help-target")" ]]; then
    pass "help has no side effects"
else
    fail "help has no side effects"
fi

mkdir -p "$TMP_ROOT/script-only"
cp "$SCRIPT" "$TMP_ROOT/script-only/luxuspythonstack.sh"
(
    # shellcheck source=/dev/null
    source "$TMP_ROOT/script-only/luxuspythonstack.sh"
    pyinit "$TMP_ROOT/no-template" >/dev/null 2>&1
)
if [[ ! -e "$TMP_ROOT/no-template" ]]; then
    pass "missing template aborts before writing"
else
    fail "missing template aborts before writing (target was created)"
fi

if [[ $FAST_ONLY -eq 1 ]]; then
    echo "# Fast checks only"
    printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
    [[ $FAIL -eq 0 ]]
    exit $?
fi

echo "# Integration checks"

APP="$TMP_ROOT/app"
if expect_success "pyinit creates an app" pyinit "$APP" --python 3.12; then
    assert_file "app AGENTS.md exists" "$APP/AGENTS.md"
    assert_contains "app selects core and refactor" "$APP/AGENTS.md" "Verwendet: core, refactor"
    assert_contains "app does not select docs" "$APP/AGENTS.md" "Nicht verwendet: docs-lib, docs-cli, e2e, agent"
    assert_not_contains "app AGENTS.md has no old managed block" "$APP/AGENTS.md" "AGENTS_MANAGED_BEGIN"
    expect_success_in "app just check is green" "$APP" just check
    expect_success_in "app rate-design run works" "$APP" just rate-design run
    assert_file "app report.json exists" "$APP/.refactor/report.json"
    expect_success_in "app rate-design save works" "$APP" just rate-design save before
    assert_dir "app baseline exists" "$APP/.refactor/baselines/before"
    expect_failure_in "baseline is never overwritten" "$APP" just rate-design save before
    expect_success_in "app rate-design compare works" "$APP" just rate-design compare before
    expect_success_in "app clean works" "$APP" just clean
    assert_dir "clean keeps baselines" "$APP/.refactor/baselines/before"
    if [[ ! -f "$APP/.refactor/report.json" ]]; then
        pass "clean removes the current report"
    else
        fail "clean removes the current report"
    fi

    expect_success_in "app stages initial state" "$APP" \
        git -c user.name=Test -c user.email=test@example.com add -A
    expect_success_in "app initial commit" "$APP" \
        git -c user.name=Test -c user.email=test@example.com commit -q --no-verify -m init
    expect_success_in "refactor prepares a branch" "$APP" just refactor demo
    if [[ "$(git -C "$APP" branch --show-current)" == "refactor/demo" ]]; then
        pass "refactor creates refactor/demo"
    else
        fail "refactor creates refactor/demo"
    fi
    assert_dir "refactor saves the demo baseline" "$APP/.refactor/baselines/demo"
    printf '# change\n' >>"$APP/README.md"
    expect_success_in "refactor change is committed" "$APP" \
        git -c user.name=Test -c user.email=test@example.com commit -q --no-verify -am change
    expect_success_in "merge from the refactor checkout auto-detects the branch" "$APP" just merge
    if [[ "$(git -C "$APP" branch --show-current)" == "main" ]]; then
        pass "merge switches back to main"
    else
        fail "merge switches back to main"
    fi
    if ! git -C "$APP" show-ref --verify --quiet refs/heads/refactor/demo; then
        pass "merge deletes the merged branch"
    else
        fail "merge deletes the merged branch"
    fi

    git -C "$APP" worktree add -q "$TMP_ROOT/wt-session" -b feat/session
    printf '# worktree\n' >>"$TMP_ROOT/wt-session/README.md"
    (cd "$TMP_ROOT/wt-session" && git -c user.name=Test -c user.email=test@example.com \
        commit -q --no-verify -am worktree)
    printf 'session state\n' >"$TMP_ROOT/wt-session/SESSION.md"
    expect_success_in "merge protects session files" "$APP" just merge feat/session
    assert_file "session file remains in worktree" "$TMP_ROOT/wt-session/SESSION.md"
    if git -C "$APP" worktree list | grep -q "wt-session"; then
        pass "worktree with session files remains registered"
    else
        fail "worktree with session files remains registered"
    fi
fi

LIB="$TMP_ROOT/lib"
if expect_success "pyinit creates a library" pyinit "$LIB" --lib --python 3.12; then
    assert_contains "library selects docs-lib" "$LIB/AGENTS.md" "Verwendet: core, refactor, docs-lib"
    expect_success_in "library just check is green" "$LIB" just check
    expect_success_in "library docs-check is green" "$LIB" just docs-check
fi

CLI="$TMP_ROOT/cli"
if expect_success "pyinit creates a CLI app" pyinit "$CLI" --cli --python 3.12; then
    assert_contains "CLI app selects docs-cli" "$CLI/AGENTS.md" "Verwendet: core, refactor, docs-cli"
    expect_success_in "CLI app just check is green" "$CLI" just check
    expect_success_in "CLI docs-check is green" "$CLI" just docs-check
fi

GIT_ONLY="$TMP_ROOT/git-only"
mkdir -p "$GIT_ONLY"
git -C "$GIT_ONLY" -c init.defaultBranch=master init -q
if expect_success_in ".git-only target is accepted" "$GIT_ONLY" pyinit . --python 3.12 --no-check; then
    assert_dir ".git-only target keeps .git" "$GIT_ONLY/.git"
    if [[ "$(git -C "$GIT_ONLY" branch --show-current)" == "main" ]]; then
        pass ".git-only project uses the main branch"
    else
        fail ".git-only project uses the main branch"
    fi
    expect_success_in ".git-only project passes just check" "$GIT_ONLY" just check
fi

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[[ $FAIL -eq 0 ]]

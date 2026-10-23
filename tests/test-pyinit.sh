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

assert_no_file() {
    local name="$1"
    local file="$2"
    if [[ ! -e "$file" ]]; then
        pass "$name"
    else
        fail "$name (unexpected file: $file)"
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
assert_contains "help shows the opt-in e2e runner" "$LOG" "test-e2e"
assert_contains "help shows the opt-in agent runner" "$LOG" "test-agent"

expect_failure "unknown option is rejected" pyinit --does-not-exist "$TMP_ROOT/unknown"
expect_failure "--python without value is rejected" pyinit --python
expect_failure "invalid Python version is rejected" pyinit --python 3 "$TMP_ROOT/bad-python"
expect_failure "Python older than 3.11 is rejected" pyinit --python 3.10 "$TMP_ROOT/old-python"
expect_failure "--lib --cli is rejected" pyinit --lib --cli "$TMP_ROOT/bad-combo"
expect_failure "too many directories are rejected" pyinit "$TMP_ROOT/one" "$TMP_ROOT/two"
expect_failure "invalid package name is rejected" pyinit "$TMP_ROOT/123bad"
expect_failure "Python keyword is rejected" pyinit "$TMP_ROOT/class"
expect_failure "uppercase keyword is rejected after normalization" \
    pyinit "$TMP_ROOT/Class"
expect_failure "uppercase import is rejected after normalization" \
    pyinit "$TMP_ROOT/IMPORT"

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

E2E_RUNNER="$REPO_ROOT/Luxus-Python-Stack/templates/e2e/test-e2e.sh"
AGENT_RUNNER="$REPO_ROOT/Luxus-Python-Stack/templates/agent/test-agent.sh"

expect_success "e2e runner has valid syntax" bash -n "$E2E_RUNNER"
expect_success "agent runner has valid syntax" bash -n "$AGENT_RUNNER"

mkdir -p "$TMP_ROOT/fake-bin"
DOCKER_MARKER="$TMP_ROOT/docker-called"
UV_MARKER="$TMP_ROOT/uv-called"
cat >"$TMP_ROOT/fake-bin/docker" <<'FAKE_DOCKER'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${DOCKER_MARKER:?DOCKER_MARKER is not set}"
if [[ "${1:-}" == "info" ]]; then
    exit 0
fi
exit 99
FAKE_DOCKER
cat >"$TMP_ROOT/fake-bin/uv" <<FAKE_UV
#!/usr/bin/env bash
printf 'called\n' >"$UV_MARKER"
exit 99
FAKE_UV
chmod +x "$TMP_ROOT/fake-bin/docker" "$TMP_ROOT/fake-bin/uv"

E2E_IDLE="$TMP_ROOT/e2e-idle"
mkdir -p "$E2E_IDLE/scripts" "$E2E_IDLE/tests/e2e"
cp "$E2E_RUNNER" "$E2E_IDLE/scripts/test-e2e.sh"
rm -f "$DOCKER_MARKER"
expect_success "e2e runner exits 0 without tests" \
    env PATH="$TMP_ROOT/fake-bin:$PATH" bash "$E2E_IDLE/scripts/test-e2e.sh"
assert_contains "e2e runner prints the empty-suite hint" "$LOG" "No E2E tests configured"
assert_no_file "e2e runner does not call docker when empty" "$DOCKER_MARKER"

E2E_BUILD="$TMP_ROOT/e2e-build"
mkdir -p "$E2E_BUILD/scripts" "$E2E_BUILD/tests/e2e"
cp "$E2E_RUNNER" "$E2E_BUILD/scripts/test-e2e.sh"
: >"$E2E_BUILD/tests/e2e/test_demo.py"
: >"$E2E_BUILD/tests/e2e/Dockerfile"
rm -f "$DOCKER_MARKER"
expect_failure "e2e runner builds with the suite Dockerfile" \
    env PATH="$TMP_ROOT/fake-bin:$PATH" DOCKER_MARKER="$DOCKER_MARKER" \
    bash "$E2E_BUILD/scripts/test-e2e.sh"
assert_contains "e2e runner passes its Dockerfile to docker build" \
    "$DOCKER_MARKER" "--file tests/e2e/Dockerfile"

E2E_NESTED="$TMP_ROOT/e2e-nested"
mkdir -p "$E2E_NESTED/scripts" "$E2E_NESTED/tests/e2e/cli"
cp "$E2E_RUNNER" "$E2E_NESTED/scripts/test-e2e.sh"
cat >"$E2E_NESTED/tests/e2e/cli/test_nested.py" <<'NESTED_PROBE'
"""Import probe: the module body writes a marker when it is imported."""

from pathlib import Path

Path("e2e-nested-import-ran").write_text("ran")
NESTED_PROBE
: >"$E2E_NESTED/tests/e2e/Dockerfile"
rm -f "$DOCKER_MARKER"
expect_failure "e2e runner finds nested tests" \
    env PATH="$TMP_ROOT/fake-bin:$PATH" DOCKER_MARKER="$DOCKER_MARKER" \
    bash "$E2E_NESTED/scripts/test-e2e.sh"
assert_contains "e2e runner builds for nested tests" \
    "$DOCKER_MARKER" "--file tests/e2e/Dockerfile"
assert_no_file "e2e nested preflight does not import test modules" \
    "$E2E_NESTED/e2e-nested-import-ran"

FIND_FAIL_BIN="$TMP_ROOT/fake-bin-find-fail"
mkdir -p "$FIND_FAIL_BIN"
cat >"$FIND_FAIL_BIN/find" <<'FAKE_FIND'
#!/usr/bin/env bash
printf 'simulated search failure\n' >&2
exit 2
FAKE_FIND
chmod +x "$FIND_FAIL_BIN/find"

E2E_FIND_FAIL="$TMP_ROOT/e2e-find-fail"
mkdir -p "$E2E_FIND_FAIL/scripts" "$E2E_FIND_FAIL/tests/e2e"
cp "$E2E_RUNNER" "$E2E_FIND_FAIL/scripts/test-e2e.sh"
expect_failure "e2e runner fails when the test search fails" \
    env PATH="$FIND_FAIL_BIN:$PATH" bash "$E2E_FIND_FAIL/scripts/test-e2e.sh"
assert_contains "e2e runner reports the search failure" "$LOG" \
    "searching 'tests/e2e' for test files failed"

COPY_FAIL_BIN="$TMP_ROOT/fake-bin-copy-fail"
mkdir -p "$COPY_FAIL_BIN"
cat >"$COPY_FAIL_BIN/docker" <<'FAKE_DOCKER_COPY'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${DOCKER_MARKER:?DOCKER_MARKER is not set}"
case "${1:-}" in
    info|build|create|start|rm) exit 0 ;;
    cp) printf 'simulated copy failure\n' >&2; exit 1 ;;
esac
exit 0
FAKE_DOCKER_COPY
chmod +x "$COPY_FAIL_BIN/docker"

E2E_COPY="$TMP_ROOT/e2e-copy-fail"
mkdir -p "$E2E_COPY/scripts" "$E2E_COPY/tests/e2e"
cp "$E2E_RUNNER" "$E2E_COPY/scripts/test-e2e.sh"
: >"$E2E_COPY/tests/e2e/test_demo.py"
: >"$E2E_COPY/tests/e2e/Dockerfile"
rm -f "$DOCKER_MARKER"
expect_failure "e2e runner fails when artifact copy fails" \
    env PATH="$COPY_FAIL_BIN:$PATH" DOCKER_MARKER="$DOCKER_MARKER" \
    bash "$E2E_COPY/scripts/test-e2e.sh"
assert_contains "e2e runner reports the artifact copy failure" "$LOG" \
    "copying E2E artifacts"

AGENT_IDLE="$TMP_ROOT/agent-idle"
mkdir -p "$AGENT_IDLE/scripts" "$AGENT_IDLE/tests/agent"
cp "$AGENT_RUNNER" "$AGENT_IDLE/scripts/test-agent.sh"
rm -f "$UV_MARKER"
expect_success "agent runner exits 0 without tests" \
    env PATH="$TMP_ROOT/fake-bin:$PATH" bash "$AGENT_IDLE/scripts/test-agent.sh"
assert_contains "agent runner prints the empty-suite hint" "$LOG" "No agent tests configured"
assert_no_file "agent runner does not call uv when empty" "$UV_MARKER"

AGENT_NESTED="$TMP_ROOT/agent-nested"
mkdir -p "$AGENT_NESTED/scripts" "$AGENT_NESTED/tests/agent/providers"
cp "$AGENT_RUNNER" "$AGENT_NESTED/scripts/test-agent.sh"
cat >"$AGENT_NESTED/tests/agent/providers/test_nested.py" <<'NESTED_PROBE'
"""Import probe: the module body writes a marker when it is imported."""

from pathlib import Path

Path("agent-nested-import-ran").write_text("ran")
NESTED_PROBE
rm -f "$UV_MARKER"
expect_failure "agent runner finds nested tests" \
    env PATH="$TMP_ROOT/fake-bin:$PATH" bash "$AGENT_NESTED/scripts/test-agent.sh"
assert_file "agent runner calls uv for nested tests" "$UV_MARKER"
assert_no_file "agent nested preflight does not import test modules" \
    "$AGENT_NESTED/agent-nested-import-ran"

AGENT_FIND_FAIL="$TMP_ROOT/agent-find-fail"
mkdir -p "$AGENT_FIND_FAIL/scripts" "$AGENT_FIND_FAIL/tests/agent"
cp "$AGENT_RUNNER" "$AGENT_FIND_FAIL/scripts/test-agent.sh"
expect_failure "agent runner fails when the test search fails" \
    env PATH="$FIND_FAIL_BIN:$PATH" bash "$AGENT_FIND_FAIL/scripts/test-agent.sh"
assert_contains "agent runner reports the search failure" "$LOG" \
    "searching 'tests/agent' for test files failed"

if command -v zsh >/dev/null 2>&1; then
    mkdir -p "$TMP_ROOT/zsh-data"
    if XDG_DATA_HOME="$TMP_ROOT/zsh-data" \
        zsh -c "source '$SCRIPT'; p10k() { :; }; prompt_my_jupyter; print ok" >"$LOG" 2>&1; then
        pass "jupyter prompt survives an empty runtime directory"
    else
        fail "jupyter prompt survives an empty runtime directory"
    fi

    mkdir -p "$TMP_ROOT/zsh-data/jupyter/runtime"
    : >"$TMP_ROOT/zsh-data/jupyter/runtime/jpserver-999999.json"
    if XDG_DATA_HOME="$TMP_ROOT/zsh-data" \
        zsh -c "source '$SCRIPT'; p10k() { :; }; prompt_my_jupyter; print ok" >"$LOG" 2>&1; then
        pass "jupyter prompt survives a single runtime file family"
    else
        fail "jupyter prompt survives a single runtime file family"
    fi
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
    assert_contains "app AGENTS.md has project profile" "$APP/AGENTS.md" "## Projektprofil"
    assert_contains "app AGENTS.md has ADR section" "$APP/AGENTS.md" "## ADRs"
    assert_contains "app AGENTS.md names the ADR directory" "$APP/AGENTS.md" "docs/adr"
    assert_contains "app AGENTS.md documents decision filenames" "$APP/AGENTS.md" "0001-wir-verwenden-zsh.md"
    assert_not_contains "app AGENTS.md has no legacy ADR directory" "$APP/AGENTS.md" "docs/decisions"
    assert_contains "app AGENTS.md has attention points" "$APP/AGENTS.md" "## Attention Points"
    assert_contains "app AGENTS.md records the project type" "$APP/AGENTS.md" "Projekttyp: App"
    assert_contains "app AGENTS.md has a testing section" "$APP/AGENTS.md" "## Testing"
    assert_contains "app AGENTS.md records the contract version" "$APP/AGENTS.md" 'contract_version: `3`'
    assert_not_contains "app AGENTS.md has no feature list" "$APP/AGENTS.md" "Verwendet:"
    assert_not_contains "app AGENTS.md has no old managed block" "$APP/AGENTS.md" "AGENTS_MANAGED_BEGIN"
    assert_no_file "app has no SESSION.md" "$APP/SESSION.md"
    assert_no_file "app without --cli has no docs scaffold" "$APP/docs/index.md"
    assert_file "app has the collection gate" "$APP/tests/conftest.py"
    assert_file "app has the e2e README" "$APP/tests/e2e/README.md"
    assert_file "app has the e2e conftest" "$APP/tests/e2e/conftest.py"
    assert_file "app has the e2e Dockerfile" "$APP/tests/e2e/Dockerfile"
    assert_file "app has the agent README" "$APP/tests/agent/README.md"
    assert_file "app has the agent conftest" "$APP/tests/agent/conftest.py"
    assert_file "app has the e2e runner" "$APP/scripts/test-e2e.sh"
    assert_file "app has the agent runner" "$APP/scripts/test-agent.sh"
    assert_file "app has a .dockerignore" "$APP/.dockerignore"
    assert_file "app has an e2e workflow" "$APP/.github/workflows/e2e.yml"
    assert_contains "app e2e Dockerfile installs the built wheel" \
        "$APP/tests/e2e/Dockerfile" "--no-editable"
    assert_contains "app e2e workflow uploads artifacts" \
        "$APP/.github/workflows/e2e.yml" "actions/upload-artifact@v4"
    assert_contains "app e2e workflow uploads artifacts after failures" \
        "$APP/.github/workflows/e2e.yml" "if: always()"
    assert_contains "app e2e workflow uploads the artifact directory" \
        "$APP/.github/workflows/e2e.yml" "e2e-artifacts.*/**"
    assert_contains "app e2e workflow excludes pytest temp data" \
        "$APP/.github/workflows/e2e.yml" "!e2e-artifacts.*/work/**"
    assert_contains "app Justfile runs the e2e suite" "$APP/Justfile" "test-e2e:"
    assert_contains "app Justfile runs the agent suite" "$APP/Justfile" "test-agent:"
    assert_contains "app pyproject registers the e2e marker" "$APP/pyproject.toml" '"e2e: opt-in Docker suite'
    assert_contains "app pyproject registers the agent marker" "$APP/pyproject.toml" '"agent: opt-in provider suite'
    assert_contains "app pyproject has the e2e dependency group" "$APP/pyproject.toml" "[dependency-groups]"
    if awk '/^e2e = \[/ { inside = 1 } inside && /pytest/ { found = 1 } inside && /^\]/ { inside = 0 } END { exit !found }' \
        "$APP/pyproject.toml"; then
        pass "app pyproject lists pytest in the e2e group"
    else
        fail "app pyproject lists pytest in the e2e group"
    fi
    assert_contains "app .gitignore ignores e2e artifacts" "$APP/.gitignore" "e2e-artifacts.*"
    assert_contains "app .gitignore ignores agent artifacts" "$APP/.gitignore" "agent-artifacts.*"
    assert_contains "app README mentions the e2e runner" "$APP/README.md" "just test-e2e"
    assert_contains "app CONTRIBUTING mentions the agent runner" "$APP/CONTRIBUTING.md" "just test-agent"
    expect_success_in "app just check is green" "$APP" just check
    rm -f "$DOCKER_MARKER" "$UV_MARKER"
    expect_success_in "app empty e2e suite exits 0" "$APP" \
        env PATH="$TMP_ROOT/fake-bin:$PATH" just test-e2e
    assert_contains "app empty e2e suite prints a hint" "$LOG" "No E2E tests configured"
    assert_no_file "app empty e2e suite does not call docker" "$DOCKER_MARKER"
    expect_success_in "app empty agent suite exits 0" "$APP" \
        env PATH="$TMP_ROOT/fake-bin:$PATH" just test-agent
    assert_contains "app empty agent suite prints a hint" "$LOG" "No agent tests configured"
    assert_no_file "app empty agent suite does not call uv" "$UV_MARKER"

    cat >"$APP/tests/e2e/test_gate_probe.py" <<'GATE_PROBE'
"""Gate probe: must never be collected by the default run."""


def test_gate_probe() -> None:
    """Fail if the collection gate is bypassed."""
    raise AssertionError("the collection gate was bypassed")
GATE_PROBE
    expect_success_in "e2e gate probe does not affect just check" "$APP" just check
    rm -f "$APP/tests/e2e/test_gate_probe.py"

    cat >"$APP/tests/agent/test_gate_probe.py" <<'GATE_PROBE'
"""Gate probe: must never be collected by the default run."""


def test_gate_probe() -> None:
    """Fail if the collection gate is bypassed."""
    raise AssertionError("the collection gate was bypassed")
GATE_PROBE
    expect_success_in "agent gate probe does not affect just check" "$APP" just check
    rm -f "$APP/tests/agent/test_gate_probe.py"

    cat >"$APP/tests/e2e/test_import_probe.py" <<'IMPORT_PROBE'
"""Import probe: the module body writes a marker when it is imported."""

from pathlib import Path

Path("e2e-import-probe-ran").write_text("ran")
IMPORT_PROBE
    expect_failure_in "e2e direct pytest is rejected before imports" "$APP" \
        env -u LUPYSTA_E2E -u LUPYSTA_E2E_CONTAINER uv run pytest tests/e2e
    assert_contains "e2e direct pytest names the runner" "$LOG" "use just test-e2e"
    assert_no_file "e2e direct pytest does not import test modules" \
        "$APP/e2e-import-probe-ran"
    rm -f "$APP/tests/e2e/test_import_probe.py" "$APP/e2e-import-probe-ran"

    cat >"$APP/tests/agent/test_import_probe.py" <<'IMPORT_PROBE'
"""Import probe: the module body writes a marker when it is imported."""

from pathlib import Path

Path("agent-import-probe-ran").write_text("ran")
IMPORT_PROBE
    expect_failure_in "agent direct pytest is rejected before imports" "$APP" \
        env -u LUPYSTA_AGENT uv run pytest tests/agent
    assert_contains "agent direct pytest names the runner" "$LOG" "use just test-agent"
    assert_no_file "agent direct pytest does not import test modules" \
        "$APP/agent-import-probe-ran"
    rm -f "$APP/tests/agent/test_import_probe.py" "$APP/agent-import-probe-ran"

    cat >"$APP/tests/agent/test_skip_probe.py" <<'SKIP_PROBE'
"""Collection skip probe."""

import pytest

pytest.skip("the collection skip probe must fail the run", allow_module_level=True)
SKIP_PROBE
    cat >"$APP/tests/agent/test_pass_probe.py" <<'PASS_PROBE'
"""Passing probe that must not hide the collection skip."""


def test_pass_probe() -> None:
    """Pass so the run would be green without the skip-to-failure rule."""
    assert True
PASS_PROBE
    expect_failure_in "agent runner turns collection skips into failures" "$APP" just test-agent
    assert_contains "agent runner reports the collection skip" "$LOG" \
        "the collection skip probe must fail the run"
    rm -f "$APP/tests/agent/test_skip_probe.py" "$APP/tests/agent/test_pass_probe.py"

    if docker info >/dev/null 2>&1; then
        cat >"$APP/tests/e2e/test_gate_probe.py" <<'GATE_PROBE'
"""Gate probe: must fail when the Docker runner executes it."""


def test_gate_probe() -> None:
    """Fail because the runner must not hide real failures."""
    raise AssertionError("the Docker runner executed the probe")
GATE_PROBE
        expect_failure_in "e2e runner executes real tests" "$APP" just test-e2e
        assert_contains "e2e runner reports the probe failure" "$LOG" \
            "the Docker runner executed the probe"
        assert_contains "e2e runner records the probe failure in JUnit" \
            "$APP"/e2e-artifacts.*/junit.xml "the Docker runner executed the probe"
        rm -f "$APP/tests/e2e/test_gate_probe.py"
        rm -rf "$APP"/e2e-artifacts.*

        cat >"$APP/tests/e2e/test_skip_probe.py" <<'SKIP_PROBE'
"""Collection skip probe."""

import pytest

pytest.skip("the collection skip probe must fail the run", allow_module_level=True)
SKIP_PROBE
        cat >"$APP/tests/e2e/test_pass_probe.py" <<'PASS_PROBE'
"""Passing probe that must not hide the collection skip."""


def test_pass_probe() -> None:
    """Pass so the run would be green without the skip-to-failure rule."""
    assert True
PASS_PROBE
        expect_failure_in "e2e runner turns collection skips into failures" "$APP" just test-e2e
        assert_contains "e2e runner reports the collection skip" "$LOG" \
            "the collection skip probe must fail the run"
        rm -f "$APP/tests/e2e/test_skip_probe.py" "$APP/tests/e2e/test_pass_probe.py"
        rm -rf "$APP"/e2e-artifacts.*
    else
        printf 'skip - e2e runner executes real tests (Docker not available)\n'
        printf 'skip - e2e runner turns collection skips into failures (Docker not available)\n'
    fi

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
    printf 'journal state\n' >"$TMP_ROOT/wt-session/JOURNAL.md"
    expect_success_in "merge protects journal files" "$APP" just merge feat/session
    assert_file "journal file remains in worktree" "$TMP_ROOT/wt-session/JOURNAL.md"
    if git -C "$APP" worktree list | grep -q "wt-session"; then
        pass "worktree with journal remains registered"
    else
        fail "worktree with journal remains registered"
    fi
fi

LIB="$TMP_ROOT/lib"
if expect_success "pyinit creates a library" pyinit "$LIB" --lib --python 3.12; then
    assert_contains "library is typed as library" "$LIB/AGENTS.md" "Projekttyp: Bibliothek"
    assert_file "library has the collection gate" "$LIB/tests/conftest.py"
    assert_file "library has the e2e runner" "$LIB/scripts/test-e2e.sh"
    assert_file "library has the agent runner" "$LIB/scripts/test-agent.sh"
    assert_file "library has the e2e Dockerfile" "$LIB/tests/e2e/Dockerfile"
    assert_file "library has the agent conftest" "$LIB/tests/agent/conftest.py"
    assert_file "library has an e2e workflow" "$LIB/.github/workflows/e2e.yml"
    assert_file "library has a tutorials section" "$LIB/docs/tutorials/index.md"
    assert_file "library has a how-to section" "$LIB/docs/how-to/index.md"
    assert_file "library has a reference section" "$LIB/docs/reference/index.md"
    assert_file "library has an explanation section" "$LIB/docs/explanation/index.md"
    assert_contains "library mkdocs nav includes the tutorials" \
        "$LIB/mkdocs.yml" "tutorials/index.md"
    assert_contains "library mkdocs nav includes the explanation section" \
        "$LIB/mkdocs.yml" "explanation/index.md"
    expect_success_in "library just check is green" "$LIB" just check
    expect_success_in "library docs-check is green" "$LIB" just docs-check
    git -C "$LIB" config user.name Test
    git -C "$LIB" config user.email test@example.com
    git -C "$LIB" add -A
    git -C "$LIB" commit -q --no-verify -m init
    expect_success_in "library bump succeeds" "$LIB" just bump patch
    expect_success_in "library lockfile is current after bump" \
        "$LIB" uv sync --locked --dev
    expect_success_in "library just check is green after bump" "$LIB" just check
    if git -C "$LIB" tag -l v0.1.1 | grep -q 'v0.1.1'; then
        pass "library bump creates the v0.1.1 tag"
    else
        fail "library bump creates the v0.1.1 tag"
    fi
fi

CLI="$TMP_ROOT/cli"
if expect_success "pyinit creates a CLI app" pyinit "$CLI" --cli --python 3.12; then
    assert_contains "CLI app is typed as CLI app" "$CLI/AGENTS.md" "Projekttyp: App (CLI)"
    assert_file "CLI app has the collection gate" "$CLI/tests/conftest.py"
    assert_file "CLI app has the e2e runner" "$CLI/scripts/test-e2e.sh"
    assert_file "CLI app has the agent runner" "$CLI/scripts/test-agent.sh"
    assert_file "CLI app has the agent conftest" "$CLI/tests/agent/conftest.py"
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

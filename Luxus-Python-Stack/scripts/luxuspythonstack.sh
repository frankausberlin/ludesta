# shellcheck shell=bash
# _LUXUS_SCRIPT_DIR — absolute path to the directory containing this sourced script
if [ -n "${BASH_SOURCE[0]:-}" ]; then
    _LUXUS_SOURCE="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION:-}" ]; then
    eval '_LUXUS_SOURCE="${(%):-%x}"'
else
    _LUXUS_SOURCE="$0"
fi
_LUXUS_REAL_SOURCE="$(readlink -f "$_LUXUS_SOURCE" 2>/dev/null || printf '%s\n' "$_LUXUS_SOURCE")"
_LUXUS_SCRIPT_DIR="$(cd "$(dirname "$_LUXUS_REAL_SOURCE")" && pwd)"
unset _LUXUS_SOURCE _LUXUS_REAL_SOURCE

_LUPYSTA_VERSION="0.10.0"
_LUPYSTA_CONTRACT_VERSION="3"





# ─── pyinit ───────────────────────────────────────────────────────────────────
# Luxury Python Project Initializer — initialize a new uv-based Python project.
#
# pyinit is ONLY a new-project initializer. It never updates, repairs, merges, or
# migrates an existing project. The target directory must be empty or not exist.
#
# Usage:
#   pyinit                            # app in the current directory
#   pyinit my-project                 # app in a new directory
#   pyinit my-lib --lib               # library in a new directory
#   pyinit my-app --cli               # app with a Typer CLI reference
#   pyinit my-project --python 3.11   # specify Python version
#   pyinit --help                     # show help
pyinit() {
    # ─── Argument parsing (no side effects) ──────────────────────────────────
    local _dir="."
    local _type="app"
    local _cli=0
    local _no_check=0
    local _py_version="3.12"
    local _saw_dir=0
    local _arg

    while [[ $# -gt 0 ]]; do
        _arg="$1"
        case "$_arg" in
            --help|-h)
                cat <<'PYINIT_HELP'
Usage: pyinit [OPTIONS] [DIRECTORY]

Initialize a new uv-based Python project in DIRECTORY (default: current
directory). The target must be empty, not exist yet, or contain only .git.

Options:
  --lib            Create a library instead of an application (default: app)
  --cli            Add a Typer CLI reference to an application (app only)
  --python X.Y     Python version, 3.11 or newer (default: 3.12)
  --no-check       Skip the final `just check` (useful without a full toolchain)
  --help           Show this help and exit

Examples:
  pyinit                          # app in the current directory
  pyinit my-project               # app in a new directory
  pyinit my-lib --lib             # library in a new directory
  pyinit my-app --cli             # app with a generated CLI reference
  pyinit my-project --python 3.11
  pyinit --python=3.11 my-project

Opt-in test scaffolds:
  Every project gets tests/e2e/ (Docker) and tests/agent/ (provider), both
  without test_*.py files. They are not part of `just check`. Run them with:
    just test-e2e     # empty suite prints a hint and exits 0, no Docker call
    just test-agent   # empty suite prints a hint and exits 0, no provider call

License:
  pyinit writes an MIT LICENSE. The copyright holder is taken from
  `git config user.name` (fallback: "Project Author"). Review the file before
  you publish the project.
PYINIT_HELP
                return 0
                ;;
            --lib)
                _type="lib"
                ;;
            --cli)
                _cli=1
                ;;
            --no-check)
                _no_check=1
                ;;
            --python)
                if [[ $# -lt 2 ]]; then
                    echo "Error: --python requires a value (e.g. --python 3.12)." >&2
                    return 1
                fi
                _py_version="$2"
                shift
                ;;
            --python=*)
                _py_version="${_arg#--python=}"
                ;;
            -*)
                echo "Error: unknown option '$_arg'." >&2
                echo "       Run 'pyinit --help' for usage." >&2
                return 1
                ;;
            *)
                if [[ $_saw_dir -eq 1 ]]; then
                    echo "Error: too many arguments: '$_arg' (only one DIRECTORY is allowed)." >&2
                    return 1
                fi
                _dir="$_arg"
                _saw_dir=1
                ;;
        esac
        shift
    done

    # ─── Option combination guards ───────────────────────────────────────────
    if [[ "$_type" == "lib" && $_cli -eq 1 ]]; then
        echo "Error: --cli is only valid for applications, not libraries." >&2
        return 1
    fi

    # ─── Validate Python version format (X.Y) ────────────────────────────────
    if [[ ! "$_py_version" =~ ^[0-9]+\.[0-9]+$ ]]; then
        echo "Error: invalid Python version '$_py_version' (expected X.Y, e.g. 3.12)." >&2
        return 1
    fi
    local _py_minor="${_py_version#3.}"
    if [[ "$_py_version" != 3.* ]] || (( 10#$_py_minor < 11 )); then
        echo "Error: Python 3.11 or newer is required (got '$_py_version')." >&2
        return 1
    fi

    # ─── Derive and validate package name ────────────────────────────────────
    local _target_name _package_name
    if [[ "$_dir" == "." ]]; then
        _target_name="$(basename "$PWD")"
    else
        _target_name="$(basename "$_dir")"
    fi
    _package_name="${_target_name//-/_}"
    _package_name="$(printf '%s' "$_package_name" | tr '[:upper:]' '[:lower:]')"

    if [[ ! "$_package_name" =~ ^[a-z_][a-z0-9_]*$ ]]; then
        echo "Error: package name '$_package_name' (derived from directory '$_target_name')" >&2
        echo "       is not a valid Python identifier." >&2
        echo "       Project directories must use only [A-Za-z0-9_-] and no leading digit." >&2
        return 1
    fi

    case "$_package_name" in
        and|as|assert|async|await|break|class|continue|def|del|elif|else|except|finally|for|from|global|if|import|in|is|lambda|nonlocal|not|or|pass|raise|return|try|while|with|yield|match|case)
            echo "Error: '$_package_name' is a Python keyword and cannot be a package name." >&2
            return 1
            ;;
    esac

    # ─── Require an empty (or absent) target ─────────────────────────────────
    if [[ -e "$_dir" ]]; then
        if [[ ! -d "$_dir" ]]; then
            echo "Error: target '$_dir' exists but is not a directory." >&2
            return 1
        fi
        local _contents
        _contents="$(ls -A "$_dir" 2>/dev/null)"
        if [[ -n "$_contents" && "$_contents" != ".git" ]]; then
            echo "Error: target directory '$_dir' is not empty." >&2
            echo "       pyinit only initializes empty directories or directories" >&2
            echo "       that contain nothing but a .git directory." >&2
            echo "       Review and remove existing contents yourself, then re-run." >&2
            return 1
        fi
    fi

    # ─── Require tools and resolve local templates before any write ──────────
    local _tool
    for _tool in uv just git; do
        if ! command -v "$_tool" >/dev/null 2>&1; then
            echo "Error: required tool '$_tool' is not installed or not on PATH." >&2
            return 1
        fi
    done

    if ! command -v awk >/dev/null 2>&1; then
        echo "Error: required tool 'awk' is not installed or not on PATH." >&2
        return 1
    fi

    local _template_dir="${_LUXUS_SCRIPT_DIR}/../templates"
    local _agents_template="${_template_dir}/AGENTS.md"
    local _design_report="${_template_dir}/scripts/design_report.py"
    local _e2e_template_dir="${_template_dir}/e2e"
    local _agent_template_dir="${_template_dir}/agent"
    local _workflow_template_dir="${_template_dir}/workflows"
    local _template
    for _template in "$_agents_template" "$_design_report" \
        "$_e2e_template_dir/README.md" "$_e2e_template_dir/conftest.py" \
        "$_e2e_template_dir/Dockerfile" "$_e2e_template_dir/dockerignore" \
        "$_e2e_template_dir/test-e2e.sh" \
        "$_agent_template_dir/README.md" "$_agent_template_dir/conftest.py" \
        "$_agent_template_dir/test-agent.sh" \
        "$_workflow_template_dir/ci.yml" "$_workflow_template_dir/e2e.yml" \
        "$_workflow_template_dir/release.yml"; do
        if [[ ! -f "$_template" ]]; then
            echo "Error: required project template not found at '$_template'." >&2
            return 1
        fi
    done

    echo -e "\e[34m💎 Initializing $_type project '$_target_name' (Python $_py_version)...\e[0m"

    # ─── Scaffold in a subshell so the caller's working directory is preserved
    #     on any failure, and UV_PYTHON_PREFERENCE never leaks to the caller.
    (
        _die() {
            printf '%s\n' "Error: $*" >&2
            exit 1
        }

        export UV_PYTHON_PREFERENCE=only-managed

        if [[ "$_dir" != "." ]]; then
            mkdir -p "$_dir" || _die "cannot create directory '$_dir'"
            cd "$_dir" || _die "cannot enter directory '$_dir'"
        fi

        unset VIRTUAL_ENV UV_PROJECT_ENVIRONMENT UV_PROJECT UV_WORKING_DIR \
            PYTHONHOME PYTHONPATH \
            || _die "cannot clear the inherited Python environment"
        export UV_PROJECT_ENVIRONMENT="$PWD/.venv" \
            || _die "cannot set UV_PROJECT_ENVIRONMENT"

        local PROJECT_NAME PACKAGE_NAME
        PROJECT_NAME="$(basename "$PWD")"
        PACKAGE_NAME="$_package_name"

        # ─── Step 1: uv init (package layout for apps and libraries) ─────────
        if [[ "$_type" == "app" ]]; then
            uv init --app --package --name "$PROJECT_NAME" --python "$_py_version" \
                --vcs none --no-workspace \
                || _die "uv init failed"
        else
            uv init --lib --name "$PROJECT_NAME" --python "$_py_version" \
                --vcs none --no-workspace \
                || _die "uv init failed"
        fi

        # ─── Step 2: dev dependencies (before appending [tool.*]) ────────────
        uv add --dev ruff pytest pytest-cov basedpyright colorlog bump-my-version pre-commit pip-audit \
            radon vulture \
            || _die "adding dev dependencies failed"
        uv add --group e2e pytest \
            || _die "adding the e2e dependency group failed"
        if [[ "$_type" == "lib" ]]; then
            uv add --dev "mkdocs-material" "mkdocstrings[python]" \
                || _die "adding documentation dependencies failed"
        fi
        if [[ "$_type" == "app" && $_cli -eq 1 ]]; then
            uv add typer || _die "adding the typer runtime dependency failed"
        fi

        # ─── Step 3: patch pyproject (entry point + version marker) ──────────
        if [[ "$_type" == "app" ]]; then
            sed -i "s|\"${PACKAGE_NAME}:main\"|\"${PACKAGE_NAME}.main:main\"|" pyproject.toml \
                || _die "patching [project.scripts] failed"
            grep -qF "\"${PACKAGE_NAME}.main:main\"" pyproject.toml \
                || _die "patching [project.scripts] failed"
        fi
        sed -i 's/^version = "0\.1\.0"$/version = "0.1.0"  # project-version/' pyproject.toml \
            || _die "patching version marker failed"
        grep -qF 'version = "0.1.0"  # project-version' pyproject.toml \
            || _die "patching version marker failed"

        # ─── Step 4: package source files ─────────────────────────────────────
        cat > "src/$PACKAGE_NAME/__init__.py" <<PYINIT_INIT
"""${PROJECT_NAME} package."""

__version__ = "0.1.0"
PYINIT_INIT

        if [[ "$_type" == "app" ]]; then
            if [[ $_cli -eq 1 ]]; then
                cat > "src/$PACKAGE_NAME/cli.py" <<PYINIT_CLI
"""Command-line interface for ${PROJECT_NAME}."""

import typer

app = typer.Typer(
    name="${PROJECT_NAME}",
    help="Command-line interface for ${PROJECT_NAME}.",
    no_args_is_help=True,
)


@app.command()
def hello(name: str = "world") -> None:
    """Print a greeting."""
    typer.echo(f"Hello, {name}!")


if __name__ == "__main__":
    app()
PYINIT_CLI
                cat > "src/$PACKAGE_NAME/main.py" <<PYINIT_MAIN_CLI
"""Entry point for ${PROJECT_NAME}."""

from ${PACKAGE_NAME}.cli import app


def main() -> None:
    """Run the ${PROJECT_NAME} command-line interface."""
    app()


if __name__ == "__main__":
    main()
PYINIT_MAIN_CLI
            else
                cat > "src/$PACKAGE_NAME/main.py" <<PYINIT_MAIN
"""Entry point for ${PROJECT_NAME}."""


def main() -> None:
    """Run the ${PROJECT_NAME} application."""
    print("Hello from ${PROJECT_NAME}!")


if __name__ == "__main__":
    main()
PYINIT_MAIN
            fi
        fi

        # ─── Step 5: tests ────────────────────────────────────────────────────
        mkdir -p tests tests/e2e tests/agent scripts
        cat > tests/conftest.py <<'PYINIT_TEST_GATE'
"""Collection gate for the opt-in E2E and agent suites."""

import os

collect_ignore: list[str] = []
if os.environ.get("LUPYSTA_E2E") != "1":
    collect_ignore.append("e2e")
if os.environ.get("LUPYSTA_AGENT") != "1":
    collect_ignore.append("agent")
PYINIT_TEST_GATE
        if [[ "$_type" == "app" ]]; then
            if [[ $_cli -eq 1 ]]; then
                cat > tests/test_smoke.py <<PYINIT_APP_CLI_TEST
"""Smoke test for the ${PROJECT_NAME} application."""

import sys

import pytest
from typer.testing import CliRunner

from ${PACKAGE_NAME} import main as main_module
from ${PACKAGE_NAME}.cli import app

runner = CliRunner()


def test_cli_hello() -> None:
    """Run the CLI with an explicit name."""
    result = runner.invoke(app, ["--name", "tester"])
    assert result.exit_code == 0
    assert "Hello, tester!" in result.output


def test_entry_point_delegates(monkeypatch: pytest.MonkeyPatch) -> None:
    """Run the console entry point with a patched command line."""
    monkeypatch.setattr(sys, "argv", ["${PROJECT_NAME}", "--name", "tester"])
    with pytest.raises(SystemExit) as excinfo:
        main_module.main()
    assert excinfo.value.code == 0
PYINIT_APP_CLI_TEST
            else
                cat > tests/test_smoke.py <<PYINIT_APP_TEST
"""Smoke test for the ${PROJECT_NAME} application."""

from ${PACKAGE_NAME}.main import main


def test_main() -> None:
    """Run the application entry point."""
    main()
PYINIT_APP_TEST
            fi
        else
            cat > tests/test_smoke.py <<PYINIT_LIB_TEST
"""Smoke test for the ${PROJECT_NAME} library."""

from importlib.metadata import version

import ${PACKAGE_NAME}


def test_package_version() -> None:
    """Verify the package version matches the installed project metadata."""
    assert ${PACKAGE_NAME}.__version__ == version("${PROJECT_NAME}")
PYINIT_LIB_TEST
        fi

        cp "$_e2e_template_dir/README.md" tests/e2e/README.md \
            || _die "copying tests/e2e/README.md failed"
        cp "$_e2e_template_dir/conftest.py" tests/e2e/conftest.py \
            || _die "copying tests/e2e/conftest.py failed"
        cp "$_e2e_template_dir/Dockerfile" tests/e2e/Dockerfile \
            || _die "copying tests/e2e/Dockerfile failed"
        cp "$_e2e_template_dir/dockerignore" .dockerignore \
            || _die "copying .dockerignore failed"
        cp "$_e2e_template_dir/test-e2e.sh" scripts/test-e2e.sh \
            || _die "copying scripts/test-e2e.sh failed"
        cp "$_agent_template_dir/README.md" tests/agent/README.md \
            || _die "copying tests/agent/README.md failed"
        cp "$_agent_template_dir/conftest.py" tests/agent/conftest.py \
            || _die "copying tests/agent/conftest.py failed"
        cp "$_agent_template_dir/test-agent.sh" scripts/test-agent.sh \
            || _die "copying scripts/test-agent.sh failed"
        chmod +x scripts/test-e2e.sh scripts/test-agent.sh \
            || _die "making the test runners executable failed"

        # ─── Step 5b: design report tool (rate-design/refactor recipes) ───────
        cp "$_design_report" scripts/design_report.py \
            || _die "copying scripts/design_report.py failed"

        # ─── Step 6: pyproject tool config ────────────────────────────────────
        cat >> pyproject.toml <<PYINIT_TOOLS

[tool.ruff]
target-version = "py${_py_version//./}"
line-length = 120
extend-exclude = [".kilo"]

[tool.ruff.lint]
select = ["E", "F", "W", "I", "N", "D", "UP", "B", "SIM", "RUF"]

[tool.ruff.lint.pydocstyle]
convention = "google"

[tool.basedpyright]
pythonVersion = "${_py_version}"
typeCheckingMode = "strict"
venvPath = "."
venv = ".venv"

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = ["-ra", "-q", "--strict-markers"]
markers = [
    "e2e: opt-in Docker suite; run only via \`just test-e2e\`",
    "agent: opt-in provider suite; run only via \`just test-agent\`",
]

[tool.coverage.report]
fail_under = 90
exclude_also = [
    "if __name__ == .__main__.:",
]

[tool.bumpversion]
current_version = "0.1.0"
commit = true
tag = true
tag_name = "v{new_version}"
message = "chore: bump version from {current_version} to {new_version}"
pre_commit_hooks = ["uv lock", "git add uv.lock"]

[[tool.bumpversion.files]]
filename = "pyproject.toml"
search = 'version = "{current_version}"  # project-version'
replace = 'version = "{new_version}"  # project-version'

[[tool.bumpversion.files]]
filename = "src/${PACKAGE_NAME}/__init__.py"
search = '__version__ = "{current_version}"'
replace = '__version__ = "{new_version}"'
PYINIT_TOOLS

        # ─── Step 7: .gitignore (local template, deterministic) ──────────────
        cat > .gitignore <<'PYINIT_GITIGNORE'
# Python
__pycache__/
*.py[cod]
*.so
.Python
*.egg-info/
build/
dist/

# Environments & secrets
.venv/
.env

# Tool caches
.direnv/
.pytest_cache/
.ruff_cache/
.mypy_cache/
.coverage
htmlcov/

# Documentation build output (library projects)
site/

# Refactoring artifacts (generated)
.refactor/

# Agent journal (volatile)
JOURNAL.md

# Agent artifacts
.kilo/

# Opt-in suite artifacts
e2e-artifacts.*
agent-artifacts.*

# Freestyle scratch space
ignore/
PYINIT_GITIGNORE

        # ─── Step 8: VS Code configuration ────────────────────────────────────
        mkdir -p .vscode
        cat > .vscode/settings.json <<'PYINIT_VSCODE_SETTINGS'
{
    // basedpyright is the single Python language server for this project.
    // Disable the Microsoft Python language server (Pylance) so both do not
    // run at once and produce duplicate, conflicting diagnostics.
    "python.languageServer": "None",
    "python.analysis.typeCheckingMode": "off",
    "editor.formatOnSave": true,
    "[python]": {
        "editor.defaultFormatter": "charliermarsh.ruff"
    },
    "editor.codeActionsOnSave": {
        "source.fixAll.ruff": "always",
        "source.organizeImports.ruff": "always"
    },
    "python.testing.pytestEnabled": true,
    "python.testing.pytestArgs": [],
    "python.terminal.activateEnvironment": true
}
PYINIT_VSCODE_SETTINGS

        cat > .vscode/launch.json <<'PYINIT_LAUNCH'
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Python: Current File",
            "type": "debugpy",
            "request": "launch",
            "program": "${file}",
            "console": "integratedTerminal",
            "justMyCode": false
        },
        {
            "name": "Python: Pytest",
            "type": "debugpy",
            "request": "launch",
            "module": "pytest",
            "args": ["-s", "${file}"],
            "console": "integratedTerminal"
        }
    ]
}
PYINIT_LAUNCH

        cat > .vscode/extensions.json <<'PYINIT_EXTENSIONS'
{
    "recommendations": [
        "ms-python.python",
        "charliermarsh.ruff",
        "detachhead.basedpyright"
    ]
}
PYINIT_EXTENSIONS

        # ─── Step 9: direnv (.envrc, no automatic allow) ─────────────────────
        cat > .envrc <<'PYINIT_ENVRC'
# Deactivate any active non-base Conda environment to prevent variable leakage
if [[ -n "$CONDA_DEFAULT_ENV" && "$CONDA_DEFAULT_ENV" != "base" ]]; then
    conda deactivate 2>/dev/null || true
fi
watch_file uv.lock
unset UV_PROJECT_ENVIRONMENT VIRTUAL_ENV
layout uv  # requires the layout_uv() function in ~/.config/direnv/direnvrc
PYINIT_ENVRC

        # ─── Step 10: Justfile ────────────────────────────────────────────────
        cat > Justfile <<'PYINIT_JUST'
set shell := ["bash", "-uc"]

# Run tests with coverage report
test:
    uv run pytest --cov=src --cov-report=term-missing

# Run the Docker E2E suite locally (CI runs it automatically once tests exist)
test-e2e:
    bash scripts/test-e2e.sh

# Run the provider suite manually (never part of CI; prints a hint until tests exist)
test-agent:
    bash scripts/test-agent.sh

# Run linters and type checker (find errors)
lint:
    uv run ruff check .
    uv run ruff format --check .
    uv run basedpyright

# Type check only
typecheck:
    uv run basedpyright

# Fix linting issues
fix:
    uv run ruff check --fix .
    uv run ruff format .

# Remove local caches and generated artifacts (keeps baselines, .venv, sources and the journal)
clean:
    #!/usr/bin/env bash
    set -euo pipefail
    rm -rf .pytest_cache .ruff_cache .mypy_cache .coverage htmlcov site
    rm -rf build dist ./*.egg-info
    rm -rf e2e-artifacts.* agent-artifacts.*
    if [ -d .refactor ]; then
        find .refactor -mindepth 1 -maxdepth 1 ! -name baselines -exec rm -rf {} +
    fi
    find . -path ./.venv -prune -o -path ./.git -prune -o -type d -name __pycache__ -print -exec rm -rf {} +
    find . -path ./.venv -prune -o -path ./.git -prune -o -type f \( -name '*.pyc' -o -name '*.pyo' \) -print -exec rm -f {} +
    echo "Cleaned caches and generated artifacts, including e2e-artifacts.* and agent-artifacts.* (kept .refactor/baselines, .venv and JOURNAL.md)."

# Audit dependencies for known security vulnerabilities
audit:
    uv run pip-audit

# Bump version — requires a clean working tree (patch | minor | major)
bump part="patch":
    #!/usr/bin/env bash
    if [ -n "$(git status --porcelain)" ]; then
        echo "Error: Working tree is dirty." >&2
        exit 1
    fi
    uv run bump-my-version bump {{part}}

# Write or compare design metrics (run | save <name> | compare <name>)
rate-design *args:
    uv run python scripts/design_report.py {{args}}

# Prepare a refactoring session: clean tree, quality gate, baseline, branch. Changes no code.
refactor name="":
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -n "$(git status --porcelain)" ]; then
        echo "Error: working tree is dirty; commit or stash first." >&2
        exit 1
    fi
    just check
    slug="{{name}}"
    slug="${slug:-$(date -u +%Y%m%d-%H%M%S)}"
    slug="$(printf '%s' "$slug" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9._-' '-')"
    slug="${slug#-}"
    slug="${slug%-}"
    if [ -z "$slug" ]; then
        slug="session"
    fi
    branch="refactor/${slug}"
    if git show-ref --verify --quiet "refs/heads/${branch}"; then
        echo "Error: branch '$branch' already exists." >&2
        exit 1
    fi
    just rate-design save "$slug"
    git switch -c "$branch"
    echo "Branch '$branch' created. Baseline in .refactor/baselines/$slug/."
    echo "Proceed with the lupysta refactoring recipe; this recipe does not refactor."

# Fast-forward target to <branch> (auto-detected when omitted) and clean up safely.
merge branch="" target="main":
    #!/usr/bin/env bash
    set -euo pipefail
    branch="{{branch}}"
    target="{{target}}"
    if ! git rev-parse --verify --quiet "refs/heads/$target" >/dev/null; then
        echo "merge: target branch '$target' does not exist" >&2
        exit 1
    fi

    target_path="$(
        git worktree list --porcelain | awk -v ref="refs/heads/$target" '
            /^worktree / { path = substr($0, 10) }
            /^branch / && $2 == ref { print path; exit }
        '
    )"
    current_path="$(git rev-parse --show-toplevel)"
    current_branch="$(git branch --show-current)"
    switched_current=0

    if [ -z "$target_path" ]; then
        if [ -n "$(git status --porcelain)" ]; then
            echo "merge: no worktree has '$target' checked out and the current tree is dirty" >&2
            exit 1
        fi
        if [ -z "$branch" ] && [ "$current_branch" != "$target" ]; then
            branch="$current_branch"
        fi
        git switch "$target"
        target_path="$current_path"
        switched_current=1
    fi

    if [ -z "$branch" ]; then
        candidates="$(
            git worktree list --porcelain | awk -v ref="refs/heads/$target" '
                /^branch / { b = substr($0, 8); if (b != ref) print b }
            '
        )"
        if [ -z "$candidates" ]; then
            candidates="$(git branch --no-merged "$target" --format='%(refname:short)')"
        fi
        count="$(printf '%s\n' "$candidates" | awk 'NF { n++ } END { print n + 0 }')"
        if [ "$count" -eq 0 ]; then
            echo "merge: nothing to merge" >&2
            exit 1
        fi
        if [ "$count" -gt 1 ]; then
            echo "merge: several branches to choose from:" >&2
            printf '%s\n' "$candidates" | while IFS= read -r candidate; do
                printf '  %s\n' "$candidate" >&2
            done
            echo "merge: run 'just merge <branch>'" >&2
            exit 1
        fi
        branch="$(printf '%s\n' "$candidates" | awk 'NF { print; exit }')"
    fi
    if [ "$branch" = "$target" ]; then
        echo "merge: refusing to merge '$target' into itself" >&2
        exit 1
    fi

    if [ -n "$(git -C "$target_path" status --porcelain)" ]; then
        echo "merge: target worktree '$target_path' is dirty" >&2
        exit 1
    fi
    if git -C "$target_path" remote get-url origin >/dev/null 2>&1; then
        git -C "$target_path" fetch origin
        if git -C "$target_path" rev-parse --verify --quiet "refs/remotes/origin/$target" >/dev/null; then
            if ! git -C "$target_path" merge-base --is-ancestor "refs/remotes/origin/$target" HEAD; then
                echo "merge: origin/$target is not an ancestor of $target; reconcile before merging" >&2
                exit 1
            fi
        fi
    fi
    if ! git -C "$target_path" merge --ff-only "$branch"; then
        echo "merge: '$branch' cannot be fast-forwarded; '$target' has diverged" >&2
        exit 1
    fi

    source_path="$(
        git worktree list --porcelain | awk -v ref="refs/heads/$branch" '
            /^worktree / { path = substr($0, 10) }
            /^branch / && $2 == ref { print path; exit }
        '
    )"
    if [ -n "$source_path" ] && [ "$source_path" != "$target_path" ]; then
        if [ "$source_path" = "$current_path" ]; then
            echo "merge: '$branch' merged into '$target'."
            echo "merge: source worktree is the current checkout; switch to '$target'"
            echo "       and remove the worktree and branch manually if you no longer need them."
        elif [ -e "$source_path/JOURNAL.md" ]; then
            echo "merge: '$branch' merged into '$target'."
            echo "merge: worktree '$source_path' left in place because it contains"
            echo "       JOURNAL.md. Move or review that file, then remove"
            echo "       the worktree and branch manually."
        elif [ -n "$(git -C "$source_path" status --porcelain)" ]; then
            echo "merge: '$branch' merged into '$target'."
            echo "merge: worktree '$source_path' left in place because it is dirty."
        elif git worktree remove "$source_path"; then
            git branch -d "$branch"
            echo "merge: '$branch' merged into '$target'; worktree removed and branch deleted."
        else
            echo "merge: '$branch' merged into '$target'."
            echo "merge: worktree '$source_path' could not be removed; clean it up manually."
        fi
    else
        if [ "$source_path" = "$target_path" ] && [ "$switched_current" -eq 0 ]; then
            echo "merge: '$branch' merged into '$target'; source worktree is the target, leaving it in place."
        else
            git branch -d "$branch"
            echo "merge: '$branch' merged into '$target'; branch deleted."
        fi
    fi
    echo "merge: publish with 'git push origin $target'"
PYINIT_JUST

        # ─── Step 10b: quality gate (docs-check only when the recipe exists) ──
        {
            echo ""
            if [[ "$_type" == "lib" || $_cli -eq 1 ]]; then
                echo "# Full local quality gate (lint + typecheck + docs + tests)"
            else
                echo "# Full local quality gate (lint + typecheck + tests)"
            fi
            echo "check:"
            echo "    uv run ruff check ."
            echo "    uv run ruff format --check ."
            echo "    uv run basedpyright"
            if [[ "$_type" == "lib" || $_cli -eq 1 ]]; then
                echo "    just docs-check"
            fi
            echo "    uv run pytest --cov=src --cov-report=term-missing"
        } >> Justfile

        if [[ "$_type" == "app" ]]; then
            cat >> Justfile <<PYINIT_JUST_RUN

# Run the installed command
run:
    uv run ${PROJECT_NAME}
PYINIT_JUST_RUN
        fi

        # ─── Step 11: GitHub Actions ──────────────────────────────────────────
        mkdir -p .github/workflows || _die "creating .github/workflows failed"
        cp "$_workflow_template_dir/ci.yml" .github/workflows/ci.yml \
            || _die "copying .github/workflows/ci.yml failed"
        cp "$_workflow_template_dir/e2e.yml" .github/workflows/e2e.yml \
            || _die "copying .github/workflows/e2e.yml failed"
        if [[ "$_type" == "lib" ]]; then
            cp "$_workflow_template_dir/release.yml" .github/workflows/release.yml \
                || _die "copying .github/workflows/release.yml failed"
        fi

        # ─── Step 12: AGENTS.md from the project template ─────────────────────
        local PROJECT_TYPE
        PROJECT_TYPE="App"
        if [[ "$_type" == "lib" ]]; then
            PROJECT_TYPE="Bibliothek"
        elif [[ $_cli -eq 1 ]]; then
            PROJECT_TYPE="App (CLI)"
        fi
        sed \
            -e "s|@PROJECT_NAME@|${PROJECT_NAME}|g" \
            -e "s|@PACKAGE_NAME@|${PACKAGE_NAME}|g" \
            -e "s|@PROJECT_TYPE@|${PROJECT_TYPE}|g" \
            -e "s|@PYTHON_VERSION@|${_py_version}|g" \
            -e "s|@SOURCE_PATH@|src/${PACKAGE_NAME}/|g" \
            -e "s|@LUPYSTA_VERSION@|${_LUPYSTA_VERSION}|g" \
            -e "s|@CONTRACT_VERSION@|${_LUPYSTA_CONTRACT_VERSION}|g" \
            "$_agents_template" > AGENTS.md \
            || _die "rendering AGENTS.md failed"

        # ─── Step 13: journal and project documents ───────────────────────────
        cat > JOURNAL.md <<'PYINIT_JOURNAL'
Session history: past sessions are appended here (latest at the end).
PYINIT_JOURNAL

        local _docs_gate="" _readme_docs="" _check_desc=""
        if [[ "$_type" == "lib" || $_cli -eq 1 ]]; then
            _check_desc="full gate (lint + typecheck + docs + tests)"
        else
            _check_desc="full gate (lint + typecheck + tests)"
        fi
        if [[ "$_type" == "lib" ]]; then
            _docs_gate=$'just docs         # build the documentation\njust docs-check   # verify the generated documentation is current\njust docs-serve   # live preview\n'
        elif [[ $_cli -eq 1 ]]; then
            _docs_gate=$'just docs         # regenerate docs/reference/cli.md\njust docs-check   # verify the generated CLI reference is current\n'
        fi
        if [[ -n "$_docs_gate" ]]; then
            _readme_docs=$'## Documentation\n\n```bash\n'"${_docs_gate}"$'```\n\n'
        fi

        cat > README.md <<PYINIT_README
# ${PROJECT_NAME}

## Getting Started

\`\`\`bash
uv sync
just check
\`\`\`

## Development

\`\`\`bash
just test        # run tests
just lint        # lint + type check
just fix         # auto-fix lint issues
just clean       # remove caches and generated artifacts
just rate-design run             # design metrics → .refactor/
just rate-design save <name>     # save an immutable baseline
just rate-design compare <name>  # compare the current run with a baseline
just refactor                    # prepare a refactoring session
just merge       # fast-forward main to a branch from any checkout (no push)
just check       # full quality gate (unit/smoke tests only)
just test-e2e    # Docker E2E suite locally (hint + exit 0 until tests exist)
just test-agent  # provider suite manually (hint + exit 0 until tests exist)
\`\`\`

\`just check\` runs unit and smoke tests only. The E2E suite is not part of the
gate: run it locally with \`just test-e2e\`; CI runs it automatically once test
files exist. Agent tests are manual-only and never run in CI.

${_readme_docs}## Release

\`\`\`bash
just bump patch   # 0.1.0 → 0.1.1
git push origin main --tags
\`\`\`

See [AGENTS.md](AGENTS.md) for AI agent guidelines.
PYINIT_README

        cat > .editorconfig <<'PYINIT_EDITORCONFIG'
root = true

[*]
indent_style = space
indent_size = 4
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true

[*.md]
trim_trailing_whitespace = false

[*.{yml,yaml,toml,json}]
indent_size = 2

[Makefile]
indent_style = tab
PYINIT_EDITORCONFIG

        cat > CONTRIBUTING.md <<PYINIT_CONTRIBUTING
# Contributing to ${PROJECT_NAME}

## Development Setup

\`\`\`bash
git clone <repo-url>
cd ${PROJECT_NAME}
direnv allow      # auto-activates .venv (or run: source .venv/bin/activate)
uv sync           # install all dependencies
\`\`\`

## Workflow

1. Create a branch, preferably in a separate worktree:
   \`git worktree add ../${PROJECT_NAME}-feature -b feat/my-feature\`
2. Make your changes
3. Run the quality gate: \`just check\`
4. Commit: \`git add -A && git commit -m "feat: ..."\`
5. From any checkout, merge locally: \`just merge feat/my-feature\`
   (fast-forward only; it removes a clean source worktree and deletes the
   branch, but keeps a worktree with local JOURNAL.md)
6. Publishing is a maintainer step: review local \`main\` with
   \`git log --oneline origin/main..main\` and \`git diff origin/main..main\`, then
   \`git push origin main\`

## Quality Gate

\`\`\`bash
just lint         # ruff + basedpyright
just typecheck    # type checking only
just test         # pytest with coverage
just clean        # remove caches and generated artifacts
just rate-design run             # design metrics → .refactor/
just rate-design save <name>     # save an immutable baseline
just rate-design compare <name>  # compare the current run with a baseline
just refactor                    # prepare a refactoring session
${_docs_gate}just check        # ${_check_desc}
just test-e2e     # Docker E2E suite locally (not part of just check)
just test-agent   # provider suite manually (not part of just check)
just fix          # auto-fix formatting and lint issues
\`\`\`

\`just check\` runs unit and smoke tests only. The E2E suite is not part of the
gate and runs in CI automatically once tests exist; agent tests are manual-only
and never run in CI. An empty suite prints a hint and exits 0.

## Conventions

- **Python version:** ${_py_version}
- **Typing:** Strict — public functions must have type annotations
- **Docstrings:** Google style
- **Imports:** Sorted by ruff (isort-compatible)
- **Line length:** 120 characters

## Versioning

Never edit version numbers manually. Use:

\`\`\`bash
just bump patch   # bugfix: 0.1.0 → 0.1.1
just bump minor   # feature: 0.1.1 → 0.2.0
just bump major   # breaking: 0.2.0 → 1.0.0
\`\`\`

See [AGENTS.md](AGENTS.md) for AI agent guidelines.
PYINIT_CONTRIBUTING

        cat > LICENSE <<PYINIT_LICENSE
MIT License

Copyright (c) $(date +%Y) $(git config user.name 2>/dev/null || echo "Project Author")

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
PYINIT_LICENSE

        # ─── Step 14: pre-commit ───────────────────────────────────────────────
        cat > .pre-commit-config.yaml <<'PYINIT_PRECOMMIT'
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v6.0.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-toml
  - repo: local
    hooks:
      - id: ruff-check
        name: ruff check
        entry: uv run ruff check --force-exclude
        language: system
        types_or: [python, pyi]
      - id: ruff-format
        name: ruff format
        entry: uv run ruff format --force-exclude
        language: system
        types_or: [python, pyi]
# Note: basedpyright runs in `just check` and CI, not as a pre-commit hook.
PYINIT_PRECOMMIT

        # ─── Step 15: documentation (lib: MkDocs; app --cli: CLI reference) ───
        if [[ "$_type" == "lib" ]]; then
            cat > mkdocs.yml <<PYINIT_MKDOCS
site_name: ${PROJECT_NAME}
site_description: Documentation for ${PROJECT_NAME}
repo_url: https://github.com/YOUR_ORG/${PROJECT_NAME}

theme:
  name: material
  features:
    - navigation.tabs
    - navigation.sections
    - toc.integrate
    - search.suggest

plugins:
  - search
  - mkdocstrings:
      handlers:
        python:
          options:
            docstring_style: google
            show_source: true
            show_root_heading: true

nav:
  - Home: index.md
  - Tutorials: tutorials/index.md
  - How-to Guides: how-to/index.md
  - Reference:
      - Overview: reference/index.md
      - API: api.md
  - Explanation: explanation/index.md
PYINIT_MKDOCS

            mkdir -p docs
            cat > docs/index.md <<PYINIT_DOCS_INDEX
# ${PROJECT_NAME}

## Getting Started

\`\`\`bash
uv sync
just check
\`\`\`

## Installation

\`\`\`bash
pip install ${PROJECT_NAME}
\`\`\`

## Quick Start

\`\`\`python
import ${PACKAGE_NAME}
\`\`\`
PYINIT_DOCS_INDEX

            cat > docs/api.md <<PYINIT_DOCS_API
# API Reference

::: ${PACKAGE_NAME}
PYINIT_DOCS_API

            mkdir -p docs/tutorials docs/how-to docs/reference docs/explanation
            cat > docs/tutorials/index.md <<'PYINIT_DOCS_TUTORIALS'
# Tutorials

Learning-oriented guides for newcomers. A tutorial walks through a complete,
working example and assumes no prior knowledge of the project.

Use this section for getting-started lessons, not for reference details or
background explanations.
PYINIT_DOCS_TUTORIALS

            cat > docs/how-to/index.md <<'PYINIT_DOCS_HOWTO'
# How-to Guides

Task-oriented guides for readers who already know the basics. A how-to guide
solves one concrete problem and focuses on the steps needed to reach the goal.

Use this section for recipes and procedures; conceptual background belongs in
Explanation.
PYINIT_DOCS_HOWTO

            cat > docs/reference/index.md <<'PYINIT_DOCS_REFERENCE'
# Reference

Information-oriented pages that describe the system precisely: public APIs,
configuration options, commands, and formats. Reference is lookup material, not
a tutorial.

- [API Reference](../api.md)
PYINIT_DOCS_REFERENCE

            cat > docs/explanation/index.md <<'PYINIT_DOCS_EXPLANATION'
# Explanation

Understanding-oriented pages that discuss background, design decisions, and
trade-offs. Explanation answers "why" and "how does it fit together" rather
than "how do I do this".

Architecture decisions live in `docs/adr/` and are deliberately separate from
this section.
PYINIT_DOCS_EXPLANATION

            cat >> Justfile <<'PYINIT_JUST_DOCS'

# Build documentation
docs:
    uv run mkdocs build

# Verify the documentation builds strictly (part of `just check`)
docs-check:
    uv run mkdocs build --strict

# Serve documentation locally (with live reload)
docs-serve:
    uv run mkdocs serve
PYINIT_JUST_DOCS
        elif [[ "$_type" == "app" && $_cli -eq 1 ]]; then
            mkdir -p scripts docs/reference
            cat > scripts/gen_cli_docs.py <<'PYINIT_CLI_DOCS'
"""Regenerate or verify ``docs/reference/cli.md`` from the Typer application.

The CLI reference is a generated artifact: the source of truth is the Typer app
in ``src/@PACKAGE@/cli.py`` and its help texts. This script runs Typer's own
documentation generator,
prepends the "do not edit" header and writes ``docs/reference/cli.md`` in place.

Run it through ``just docs`` (write) or ``just docs-check`` (verify only). Never
edit the output by hand.
"""

import argparse
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
OUTPUT = REPO_ROOT / "docs" / "reference" / "cli.md"

HEADER = """<!-- Generated file. Do not edit by hand. -->
<!-- Source: src/@PACKAGE@/cli.py. Regenerate with: just docs -->

"""


def build_document() -> str:
    """Return the full CLI reference (header plus generated body) as text."""
    command = [
        sys.executable,
        "-m",
        "typer",
        "@PACKAGE@.cli",
        "utils",
        "docs",
        "--name",
        "@PROJECT@",
        "--title",
        "CLI reference",
    ]
    result = subprocess.run(command, capture_output=True, text=True, check=False)
    if result.returncode != 0:
        sys.stderr.write(result.stderr)
        raise SystemExit(f"typer docs generation failed with exit code {result.returncode}")

    body = result.stdout.rstrip("\n") + "\n"
    return HEADER + body


def main() -> None:
    """Write ``docs/reference/cli.md`` or, with ``--check``, verify it is current."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check",
        action="store_true",
        help="do not write; fail if the committed page differs from the generated one",
    )
    arguments = parser.parse_args()

    relative = OUTPUT.relative_to(REPO_ROOT)
    content = build_document()

    if arguments.check:
        current = OUTPUT.read_text(encoding="utf-8") if OUTPUT.exists() else ""
        if current != content:
            raise SystemExit(f"{relative} is out of date; run `just docs`.")
        print(f"{relative} is up to date.")
        return

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(content, encoding="utf-8")
    print(f"Wrote {relative}")


if __name__ == "__main__":
    main()
PYINIT_CLI_DOCS
            sed -i "s/@PACKAGE@/${PACKAGE_NAME}/g; s/@PROJECT@/${PROJECT_NAME}/g" scripts/gen_cli_docs.py \
                || _die "parameterising scripts/gen_cli_docs.py failed"

            cat >> Justfile <<'PYINIT_JUST_CLI_DOCS'

# Regenerate docs/reference/cli.md from the Typer app
docs:
    uv run python scripts/gen_cli_docs.py

# Verify docs/reference/cli.md matches the Typer app (no write; part of `just check`)
docs-check:
    uv run python scripts/gen_cli_docs.py --check
PYINIT_JUST_CLI_DOCS
        fi

        # ─── Step 16: git init ────────────────────────────────────────────────
        if [[ -d .git ]]; then
            git init -q || _die "git init failed"
        else
            git init -q -b main || _die "git init failed"
        fi
        if [[ "$(git branch --show-current)" != "main" ]]; then
            git branch -m main || _die "renaming the initial branch to main failed"
        fi

        # ─── Step 17: sync, hooks, and quality gate ───────────────────────────
        uv sync || _die "uv sync failed"
        [[ -d "$PWD/.venv" ]] || _die "uv sync did not create $PWD/.venv"
        uv run pre-commit install || _die "pre-commit install failed"
        if [[ "$_type" == "lib" || $_cli -eq 1 ]]; then
            just docs || _die "documentation generation failed"
        fi
        if [[ $_no_check -eq 0 ]]; then
            just check || _die "just check failed"
        else
            echo "Skipping 'just check' because --no-check was given." >&2
        fi
    )

    local _rc=$?

    if [[ $_rc -eq 0 ]]; then
        if [[ "$_dir" != "." ]]; then
            cd "$_dir" || return 1
        fi
        echo ""
        echo -e "\e[32m✨ Success! Project '$_target_name' is ready.\e[0m"
        echo ""
        echo "  Next steps:"
        echo "  1. direnv allow      # activate the .venv automatically"
        if [[ "$_type" == "app" ]]; then
            echo "  2. just run          # run the application"
            echo "  3. just test         # run tests"
        else
            echo "  2. just test         # run tests"
            echo "  3. just docs         # build documentation"
        fi
        echo "  4. just check        # full quality gate"
        echo "  5. LICENSE prüfen (MIT, Autor aus git config user.name)"
        echo ""
        echo "  Optional test suites:"
        echo "  just test-e2e      # Docker E2E suite locally (CI: automatic once tests exist)"
        echo "  just test-agent    # provider suite manually (never in CI)"
        echo ""
        echo "  To release:"
        echo "  just bump patch"
        echo "  git push origin main --tags"
        return 0
    fi

    echo "Note: a partially initialized project may remain in '$_dir'." >&2
    return 1
}




# ─── jupyter-launcher ─────────────────────────────────────────────────────────
# Flexible Jupyter Lab launcher with optional Colab integration and port selection.
#
# Usage: jupyter-launcher [-n] [-c] [-p PORT] [folder]
#
#   -n          Tokenless mode: disables password/token authentication.
#               Useful for local development or when Google Colab should connect
#               without a token.
#
#   -c          Colab mode: adds the Google Colab CORS/XSRF arguments so that
#               colab.research.google.com can connect to this local server.
#               Can be combined with -n (token is then also disabled).
#
#   -p PORT     Use an alternative port instead of the default 8888.
#               Example: jupyter-launcher -p 9999
#
#   folder      Optional path to use as the notebook directory (--notebook-dir).
#               Use '.' to refer to the current working directory.
#               If omitted, ~/labor is used as the default.
#
# Examples:
#   jupyter-launcher                     # default: port 8888, ~/labor, token required
#   jupyter-launcher -n                  # tokenless, ~/labor
#   jupyter-launcher -c                  # Colab-compatible, ~/labor, token required
#   jupyter-launcher -n -c              # tokenless + Colab-compatible, ~/labor
#   jupyter-launcher -n -c .            # tokenless + Colab, current directory
#   jupyter-launcher -p 9999 myproject  # custom port, ./myproject as notebook-dir
#   jupyter-launcher -n -c -p 9999 .   # all options combined
#
# Personal alias suggestion: alias jl='jupyter-launcher -n -c'
jupyter-launcher() {

    # ─── FLAG ARGUMENT DOCUMENTATION ──────────────────────────────────────────
    # --no-browser
    #     Prevents Jupyter from automatically opening a browser window on start.
    #
    # --ip=127.0.0.1
    #     Binds the server strictly to localhost (security: not reachable from LAN).
    #
    # --port=PORT
    #     Sets the port for the local Jupyter instance (default: 8888).
    #
    # --ServerApp.port_retries=0
    #     Aborts immediately if the chosen port is already in use, instead of
    #     silently falling back to the next port (e.g. 8889). This prevents
    #     accidental multi-instance confusion.
    #
    # --notebook-dir=PATH
    #     Sets the root directory shown in the Jupyter file browser.
    #
    # ─── BUGFIX: FILE-ID ERRORS AND INFINITE LOOPS ────────────────────────────
    # --YDocExtension.disable_rtc=True
    #     Disables Real-Time Collaboration (RTC). Without this, JupyterLab enters
    #     a 404 loop trying to open the "globalAwareness" room, which blocks the
    #     server. Safe to disable when collaboration is not needed.
    #     NOTE: To prevent WebSocket crashes with Google Colab (TypeError on strings),
    #     the underlying server extensions (jupyter_server_documents and 
    #     jupyter_server_ydoc) are globally disabled via ~/.jupyter/jupyter_server_config.json
    #     during the initial Mamba system setup.
    #
    # --FileIdManager.file_id_manager_class=jupyter_server.fileid.manager.ArbitraryFileIdManager
    #     Fixes the recurring "File ID error". By default Jupyter uses a local
    #     SQLite database for file IDs which frequently gets corrupted or loses
    #     track of paths. The ArbitraryFileIdManager keeps IDs in memory only -
    #     files can be opened again without DB corruption issues.
    #
    # ─── GOOGLE COLAB INTEGRATION (only when -c is set) ───────────────────────
    # --ServerApp.allow_origin='https://colab.research.google.com'
    #     Allows Colab to access this local server via CORS.
    #
    # --ServerApp.allow_remote_access=True
    #     Required for any external origin to be permitted at all.
    #
    # --ServerApp.disable_check_xsrf=True
    #     Prevents the server from treating Colab requests as malicious
    #     cross-site request forgery (XSRF) attacks.
    #
    # ─── TOKENLESS MODE (only when -n is set) ─────────────────────────────────
    # --ServerApp.token=''
    #     Disables the password/token prompt entirely.
    #
    # --ServerApp.allow_credentials=True
    #     Required when Colab (or any client) needs to connect without a token.
    # ──────────────────────────────────────────────────────────────────────────

    # ── Default values for all configurable options ───────────────────────────
    local _jl_tokenless=0      # -n flag: 1 = disable token authentication
    local _jl_colab=0          # -c flag: 1 = add Colab CORS/XSRF arguments
    local _jl_port="8888"      # -p PORT: port number (default 8888)
    local _jl_folder=""        # positional: notebook-dir path (empty = use default)

    # ── Parse optional flags with getopts ─────────────────────────────────────
    # getopts processes flags one at a time; OPTIND tracks the position so we
    # can shift to the remaining positional argument (the optional folder) afterward.
    local OPTIND=1
    local _jl_opt
    while getopts ":ncp:" _jl_opt; do
        case "$_jl_opt" in
            n)
                # Tokenless mode: no password/token required
                _jl_tokenless=1
                ;;
            c)
                # Colab mode: enable Google Colab CORS/XSRF arguments
                _jl_colab=1
                ;;
            p)
                # Custom port: OPTARG holds the value that follows -p
                _jl_port="$OPTARG"
                ;;
            :)
                # A flag that requires an argument was given without one (e.g. -p with no number)
                echo "jupyter-launcher: option -${OPTARG} requires an argument." >&2
                return 1
                ;;
            \?)
                # An unknown flag was passed; print usage hint and abort
                echo "jupyter-launcher: unknown option -${OPTARG}." >&2
                echo "Usage: jupyter-launcher [-n] [-c] [-p PORT] [folder]" >&2
                return 1
                ;;
        esac
    done

    # Shift past the flags so that "$1" now refers to the optional folder argument
    shift $(( OPTIND - 1 ))

    # ── Resolve the notebook directory ────────────────────────────────────────
    if [[ $# -ge 1 ]]; then
        # A folder argument was provided. '.' is explicitly valid and resolves to
        # the current working directory via pwd.
        if [[ "$1" == "." ]]; then
            _jl_folder="$(pwd)"
        else
            # Expand to an absolute path so Jupyter always sees a clean path,
            # regardless of how the user typed it (relative or absolute).
            _jl_folder="$(realpath -m "$1")"
        fi
        # Create the directory if it does not exist yet, so Jupyter does not error.
        mkdir -p "$_jl_folder"
    else
        # No folder argument: fall back to the standard workspace directory.
        _jl_folder="$HOME/labor"
        mkdir -p "$_jl_folder"
    fi

    # ── Build the argument list incrementally ─────────────────────────────────
    # Using an array avoids quoting pitfalls and makes conditional flag injection
    # clean and readable.
    local -a _jl_args=(
        --no-browser
        --ip=127.0.0.1
        "--port=${_jl_port}"
        --ServerApp.port_retries=0
        "--notebook-dir=${_jl_folder}"
        # Disable real-time collaboration to prevent the globalAwareness 404 loop
        --YDocExtension.disable_rtc=True
        # Use in-memory file ID manager to avoid SQLite corruption errors
        --FileIdManager.file_id_manager_class=jupyter_server.fileid.manager.ArbitraryFileIdManager
    )

    # ── Conditionally append tokenless-mode arguments ─────────────────────────
    if [[ $_jl_tokenless -eq 1 ]]; then
        _jl_args+=(
            --ServerApp.token=''
            # allow_credentials is required for credential-bearing requests (e.g. from Colab)
            --ServerApp.allow_credentials=True
        )
    fi

    # ── Conditionally append Colab-integration arguments ──────────────────────
    if [[ $_jl_colab -eq 1 ]]; then
        _jl_args+=(
            # Grant Colab cross-origin access to this local server
            "--ServerApp.allow_origin=https://colab.research.google.com"
            --ServerApp.allow_remote_access=True
            # Disable XSRF check so Colab requests are not rejected as attacks
            --ServerApp.disable_check_xsrf=True
        )
    fi

    # ── Print a summary so the user knows exactly what will start ─────────────
    echo "Starting Jupyter Lab:"
    echo "  notebook-dir : $_jl_folder"
    echo "  port         : $_jl_port"
    echo "  tokenless    : $([ $_jl_tokenless -eq 1 ] && echo yes || echo no)"
    echo "  colab mode   : $([ $_jl_colab    -eq 1 ] && echo yes || echo no)"
    echo ""

    # ─── Launch Jupyter with the assembled argument list ───────────────────────
    jupyter lab "${_jl_args[@]}"
}

# Standard alias for quick access (tokenless + Colab mode, default directory)
alias jl='jupyter-launcher -n -c'





# ─── Custom Jupyter P10k Segment (Passive Runtime Tracker) ────────────────────
# otptional: info is folder a jupyter runtime-folder in p10k prompt
# insert in ~/.p10k.zsh to the list of segments in POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS 
# without 'prompt_', just 'my_jupyter'
function prompt_my_jupyter() {
  # Where Jupyter on Linux logs its active server processes
  local runtime_dir="${XDG_DATA_HOME:-$HOME/.local/share}/jupyter/runtime"
  # Under ZSH, unmatched globs must expand to an empty list. Bash parses the
  # line as a simple command and never runs it; there the loop skips literal
  # patterns via the [[ -e ... ]] check below.
  if [ -n "${ZSH_VERSION:-}" ]; then
    setopt localoptions nullglob
  fi
  local json_files=()
  local _json_candidate
  for _json_candidate in "$runtime_dir"/jpserver-*.json "$runtime_dir"/nbserver-*.json; do
    [[ -e "$_json_candidate" ]] || continue
    json_files+=("$_json_candidate")
  done
  # If no JSON files at all -> abort immediately (costs 0 performance)
  if (( ${#json_files} == 0 )); then
    return
  fi

  local is_jupyter_dir=false
  local active_dirs=()

  # Check each JSON file: only consider a live Jupyter server process
  local json_file
  local pid
  local process_args
  local server_dir
  for json_file in "${json_files[@]}"; do
    # Extract PID from filename (e.g. jpserver-17343.json -> 17343)
    pid="${json_file##*-}"
    pid="${pid%.json}"
    # Verify the process is still running (kill -0 returns 0 if alive)
    if kill -0 "$pid" 2>/dev/null; then
      # A stale runtime file can point to an unrelated process after PID reuse.
      process_args=$(ps -p "$pid" -o args= 2>/dev/null)
      if [[ "$process_args" != *jupyter* && "$process_args" != *notebook* ]]; then
        continue
      fi

      # Read root_dir from this active server
      server_dir=$(grep -o '"root_dir"[[:space:]]*:[[:space:]]*"[^\}]*"' "$json_file" 2>/dev/null | head -1 | cut -d'"' -f4)
      if [[ -n "$server_dir" ]]; then
        active_dirs+=("$server_dir")
      fi
    fi
  done

  # If no active servers remain after PID check -> abort
  if (( ${#active_dirs} == 0 )); then
    return
  fi

  # Check whether the current directory ($PWD) is a (sub)folder of an active server
  for server_dir in "${active_dirs[@]}"; do
    if [[ "$PWD" == "$server_dir" || "$PWD" == "$server_dir/"* ]]; then
      is_jupyter_dir=true
      break
    fi
  done

  # Hit! Active server is running and we are within its sphere of influence.
  if $is_jupyter_dir; then
    p10k segment -f 208 -i '' -t 'jupyter'
  fi
}

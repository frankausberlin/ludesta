"""Regression test for the optional-suite collection gate.

The gate in the generated project's ``tests/conftest.py`` must exclude the
``e2e`` and ``agent`` directories themselves, not just their contents.  A glob
such as ``e2e/*`` lets pytest load ``tests/e2e/conftest.py`` first, so an
optional import error breaks the default test run.

Run with pytest available, for example::

    uvx --from pytest pytest tests/test_collection_gate.py

The test builds throwaway projects in temporary directories and runs pytest
in a subprocess; it needs neither Docker nor a provider.
"""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

GATE = """\
import os

collect_ignore = []
if os.environ.get("LUPYSTA_E2E") != "1":
    collect_ignore.append("e2e")
if os.environ.get("LUPYSTA_AGENT") != "1":
    collect_ignore.append("agent")
"""


def _project(tmp_path: Path, name: str, *, broken_e2e: bool, broken_agent: bool) -> Path:
    root = tmp_path / name
    tests = root / "tests"
    (tests / "e2e").mkdir(parents=True)
    (tests / "agent").mkdir(parents=True)
    (tests / "conftest.py").write_text(GATE, encoding="utf-8")
    (tests / "test_smoke.py").write_text("def test_smoke():\n    assert True\n", encoding="utf-8")
    (tests / "e2e" / "test_e2e.py").write_text("def test_e2e():\n    assert True\n", encoding="utf-8")
    (tests / "agent" / "test_agent.py").write_text(
        "def test_agent():\n    assert True\n", encoding="utf-8"
    )
    (tests / "e2e" / "conftest.py").write_text(
        "import missing_optional_dependency_e2e\n" if broken_e2e else "",
        encoding="utf-8",
    )
    (tests / "agent" / "conftest.py").write_text(
        "import missing_optional_dependency_agent\n" if broken_agent else "",
        encoding="utf-8",
    )
    return root


def _run(root: Path, **env: str) -> subprocess.CompletedProcess[str]:
    process_env = {
        key: value
        for key, value in os.environ.items()
        if not key.startswith("LUPYSTA_")
    }
    process_env.update(env)
    return subprocess.run(
        [sys.executable, "-m", "pytest", "-q", "tests"],
        cwd=root,
        env=process_env,
        capture_output=True,
        text=True,
        check=False,
    )


def test_default_run_does_not_load_optional_conftests(tmp_path: Path) -> None:
    root = _project(tmp_path, "default", broken_e2e=True, broken_agent=True)
    result = _run(root)
    assert result.returncode == 0, result.stdout + result.stderr
    assert "missing_optional_dependency_e2e" not in result.stdout + result.stderr
    assert "missing_optional_dependency_agent" not in result.stdout + result.stderr


def test_enabled_e2e_surfaces_its_collection_error(tmp_path: Path) -> None:
    root = _project(tmp_path, "e2e-broken", broken_e2e=True, broken_agent=True)
    result = _run(root, LUPYSTA_E2E="1")
    output = result.stdout + result.stderr
    assert result.returncode != 0
    assert "missing_optional_dependency_e2e" in output
    assert "missing_optional_dependency_agent" not in output


def test_enabled_agent_surfaces_its_collection_error(tmp_path: Path) -> None:
    root = _project(tmp_path, "agent-broken", broken_e2e=True, broken_agent=True)
    result = _run(root, LUPYSTA_AGENT="1")
    output = result.stdout + result.stderr
    assert result.returncode != 0
    assert "missing_optional_dependency_agent" in output
    assert "missing_optional_dependency_e2e" not in output


def test_enabled_suite_runs_its_tests(tmp_path: Path) -> None:
    root = _project(tmp_path, "e2e-valid", broken_e2e=False, broken_agent=True)
    result = _run(root, LUPYSTA_E2E="1")
    assert result.returncode == 0, result.stdout + result.stderr
    assert "2 passed" in result.stdout

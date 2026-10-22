"""Pytest configuration for the opt-in Docker E2E suite."""

from __future__ import annotations

import os
from pathlib import Path

import pytest

_skipped = False


@pytest.fixture(autouse=True)
def _require_container() -> None:
    """Fail when the E2E suite runs outside its opt-in container."""
    if os.environ.get("LUPYSTA_E2E") != "1":
        pytest.fail("tests/e2e collected without the opt-in gate; use just test-e2e")
    if os.environ.get("LUPYSTA_E2E_CONTAINER") != "1":
        pytest.fail("tests/e2e must run inside the E2E container; use just test-e2e")
    if not Path("/.dockerenv").exists():
        pytest.fail("tests/e2e must run inside Docker; use just test-e2e")


def pytest_runtest_logreport(report: pytest.TestReport) -> None:
    """Remember whether any E2E test was skipped."""
    global _skipped
    if report.skipped:
        _skipped = True


def pytest_sessionfinish(session: pytest.Session, exitstatus: int) -> None:
    """Turn skips into failures inside the E2E container."""
    global _skipped
    if exitstatus == 0 and _skipped and os.environ.get("LUPYSTA_E2E_CONTAINER") == "1":
        session.exitstatus = pytest.ExitCode.TESTS_FAILED
    _skipped = False

"""Pytest configuration for the opt-in agent suite.

This skeleton only guards the suite. The provider preflight (endpoint, model,
credentials, limits) belongs in the project-specific harness, not here.
"""

from __future__ import annotations

import os

import pytest

_skipped = False


@pytest.fixture(autouse=True)
def _require_agent_opt_in() -> None:
    """Fail when the agent suite is collected without the opt-in gate."""
    if os.environ.get("LUPYSTA_AGENT") != "1":
        pytest.fail("tests/agent collected without the opt-in gate; use just test-agent")


def pytest_runtest_logreport(report: pytest.TestReport) -> None:
    """Remember whether any agent test was skipped."""
    global _skipped
    if report.skipped:
        _skipped = True


def pytest_sessionfinish(session: pytest.Session, exitstatus: int) -> None:
    """Turn skips into failures for an opted-in agent run."""
    global _skipped
    if exitstatus == 0 and _skipped and os.environ.get("LUPYSTA_AGENT") == "1":
        session.exitstatus = pytest.ExitCode.TESTS_FAILED
    _skipped = False

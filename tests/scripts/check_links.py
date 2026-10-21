#!/usr/bin/env python3
"""Check relative Markdown links in the repository.

Only tracked Markdown files are checked. External URLs, anchors, and absolute
paths are ignored. Fenced code blocks and inline code are skipped so that
examples are not treated as links.
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[1]
LINK_RE = re.compile(r"!?\[[^\]]*\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
FENCE_RE = re.compile(r"^\s*(```|~~~)")


def tracked_markdown() -> list[Path]:
    """Return tracked Markdown files that are part of the repository."""
    result = subprocess.run(
        ["git", "ls-files", "--cached", "--others", "--exclude-standard", "*.md"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        print("error: git ls-files failed", file=sys.stderr)
        raise SystemExit(1)
    files: list[Path] = []
    for line in result.stdout.splitlines():
        path = ROOT / line
        if not path.is_file():
            continue
        if path.relative_to(ROOT).parts[0] in {"ignore", ".kilo", ".git"}:
            continue
        files.append(path)
    return sorted(files)


def iter_links(path: Path) -> list[tuple[int, str]]:
    """Return (line number, target) pairs for *path*."""
    links: list[tuple[int, str]] = []
    in_fence = False
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if FENCE_RE.match(line):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        without_code = re.sub(r"`[^`]*`", "", line)
        for match in LINK_RE.finditer(without_code):
            target = match.group(1).strip()
            if target.startswith("<") and target.endswith(">"):
                target = target[1:-1]
            links.append((number, target))
    return links


def is_external(target: str) -> bool:
    """Return True when *target* does not point into the repository."""
    lowered = target.lower()
    return (
        not target
        or target.startswith("#")
        or target.startswith("/")
        or lowered.startswith(("http://", "https://", "mailto:", "data:"))
    )


def check_file(path: Path) -> list[str]:
    """Return broken-link messages for *path*."""
    problems: list[str] = []
    for number, target in iter_links(path):
        if is_external(target):
            continue
        clean = unquote(target.split("#", 1)[0].split("?", 1)[0])
        if not clean:
            continue
        resolved = (path.parent / clean).resolve()
        if not resolved.exists():
            relative = path.relative_to(ROOT)
            problems.append(f"{relative}:{number}: broken link: {target}")
    return problems


def main() -> int:
    """Check all tracked Markdown files and return an exit code."""
    files = tracked_markdown()
    problems: list[str] = []
    link_count = 0
    for path in files:
        link_count += len(iter_links(path))
        problems.extend(check_file(path))
    if problems:
        for problem in problems:
            print(problem, file=sys.stderr)
        print(f"{len(problems)} broken link(s)", file=sys.stderr)
        return 1
    print(f"checked {len(files)} files and {link_count} links; no broken links")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Classify changed repository paths for the LabKit CI workflow."""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import PurePosixPath

FOCUSED_HOTFIX_PREFIX = "hotfix/focused/"


def normalize(path: str) -> str:
    normalized = path.strip().replace("\\", "/")
    while normalized.startswith("./"):
        normalized = normalized[2:]
    return normalized


def is_governance_document(path: str) -> bool:
    item = PurePosixPath(path)
    return (
        item.name == "AGENTS.md"
        or path.startswith(".agents/")
        or path == ".github/PULL_REQUEST_TEMPLATE.md"
        or path.startswith(".github/ISSUE_TEMPLATE/")
    )


def is_human_documentation(path: str) -> bool:
    return (
        path == "README.md"
        or path.startswith("docs/")
        or path.startswith("site/")
        or (path.endswith(".md") and not is_governance_document(path))
    )


def blocks_focused_hotfix(path: str) -> bool:
    return (
        path.startswith(".github/")
        or path.startswith(".agents/")
        or path.startswith("tests/+labkittest/")
        or path.startswith("tools/")
        or path.startswith("resources/")
        or path in {"AGENTS.md", "buildfile.m", "tests/AGENTS.md"}
    )


def classify(paths: list[str], head_ref: str = "") -> dict[str, bool]:
    normalized = [normalize(path) for path in paths]
    normalized = [path for path in normalized if path]
    docs = any(is_human_documentation(path) for path in normalized)
    governance = any(is_governance_document(path) for path in normalized)
    has_executable_change = any(
        not is_human_documentation(path) and not is_governance_document(path)
        for path in normalized
    )
    focused = (
        head_ref.startswith(FOCUSED_HOTFIX_PREFIX)
        and has_executable_change
        and not any(blocks_focused_hotfix(path) for path in normalized)
    )
    return {
        "full": has_executable_change and not focused,
        "focused": focused,
        "docs": docs,
        "governance": governance,
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--null",
        action="store_true",
        help="Read NUL-delimited paths from standard input.",
    )
    parser.add_argument(
        "--github-output",
        help="Append full/docs/governance outputs to this GitHub output file.",
    )
    parser.add_argument(
        "--head-ref",
        default="",
        help="Pull-request head branch used to recognize focused hotfixes.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    separator = "\0" if args.null else "\n"
    paths = sys.stdin.read().split(separator)
    scope = classify(paths, args.head_ref)
    lines = [f"{name}={str(value).lower()}" for name, value in scope.items()]
    if args.github_output:
        with open(args.github_output, "a", encoding="utf-8") as stream:
            stream.write("\n".join(lines) + "\n")
    print("CI scope: " + ", ".join(lines))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Enforce the permanent develop branch and component version transitions."""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import PurePosixPath
from typing import Callable


VERSION = re.compile(r"^(\d+)\.(\d+)\.(\d+)$")
APP_VERSION = re.compile(r'\bAppVersion\s*=\s*"(\d+\.\d+\.\d+)"')
APP_ENTRYPOINT = re.compile(r'\bEntrypoint\s*=\s*"([^"]+)"')
FACADE_VERSION = re.compile(
    r'\bversionInfo\s*\(\s*(?:\.\.\.\s*)?"([^"]+)"\s*,\s*'
    r'"(\d+\.\d+\.\d+)"',
    re.DOTALL,
)
LAUNCHER_VERSION = re.compile(
    r'"name"\s*,\s*"labkit_launcher".*?'
    r'"version"\s*,\s*"(\d+\.\d+\.\d+)"',
    re.DOTALL,
)
LAUNCHER_METADATA = "+labkit/+app/+internal/+launcher/dispatch.m"


def command(*arguments: str, allow_missing: bool = False) -> str | None:
    result = subprocess.run(
        arguments,
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL if allow_missing else None,
        text=True,
    )
    if result.returncode == 0:
        return result.stdout
    if allow_missing:
        return None
    raise RuntimeError(f"Command failed ({result.returncode}): {' '.join(arguments)}")


def git_text(revision: str, path: str) -> str | None:
    return command("git", "show", f"{revision}:{path}", allow_missing=True)


def changed_paths(base_sha: str, head_sha: str) -> list[str]:
    output = command("git", "diff", "--name-only", base_sha, head_sha)
    assert output is not None
    return [line for line in output.splitlines() if line]


def parse_version(path: str, source: str | None) -> tuple[str, str] | None:
    if source is None:
        return None
    if path.startswith("apps/") and path.endswith("/definition.m"):
        version = APP_VERSION.search(source)
        component = APP_ENTRYPOINT.search(source)
        if version and component:
            return component.group(1), version.group(1)
    if path.startswith("+labkit/") and path.endswith("/version.m"):
        match = FACADE_VERSION.search(source)
        if match:
            return f"labkit.{match.group(1)}", match.group(2)
    if path == LAUNCHER_METADATA:
        match = LAUNCHER_VERSION.search(source)
        if match:
            return "labkit_launcher", match.group(1)
    return None


def is_direct_step(before: str, after: str) -> bool:
    old = tuple(int(item) for item in VERSION.fullmatch(before).groups())
    new = tuple(int(item) for item in VERSION.fullmatch(after).groups())
    return new in {
        (old[0], old[1], old[2] + 1),
        (old[0], old[1] + 1, 0),
        (old[0] + 1, 0, 0),
    }


def metadata_path_for_source(path: str) -> str | None:
    item = PurePosixPath(path)
    if path == "labkit_launcher.m" or path.startswith(
        "+labkit/+app/+internal/+launcher/"
    ):
        return LAUNCHER_METADATA
    if path.startswith("apps/") and path.endswith(".m"):
        parts = item.parts
        if len(parts) >= 4:
            return (
                f"{parts[0]}/{parts[1]}/{parts[2]}/"
                f"+{parts[2]}/definition.m"
            )
    if path.startswith("+labkit/") and path.endswith(".m"):
        parts = item.parts
        if len(parts) >= 2:
            return f"+labkit/{parts[1]}/version.m"
    return None


def validate_branch(
    event_name: str,
    base_ref: str,
    head_ref: str,
    head_repository: str,
    repository: str,
) -> list[str]:
    if event_name != "pull_request" or base_ref != "main":
        return []
    errors = []
    if head_ref != "develop":
        errors.append(
            f'Pull requests to main must come from develop, not "{head_ref}".'
        )
    if head_repository != repository:
        errors.append(
            "Pull requests to main must use the repository-owned develop branch."
        )
    return errors


def validate_versions(
    paths: list[str],
    read_base: Callable[[str], str | None],
    read_head: Callable[[str], str | None],
) -> list[str]:
    errors = []
    metadata = {
        path
        for path in paths
        if path.endswith("/definition.m") or path.endswith("/version.m")
    }
    for path in paths:
        owner = metadata_path_for_source(path)
        if owner:
            metadata.add(owner)

    transitions: list[tuple[str, str, str]] = []
    for path in sorted(metadata):
        before = parse_version(path, read_base(path))
        after = parse_version(path, read_head(path))
        if before is None or after is None:
            continue
        component_before, version_before = before
        component_after, version_after = after
        if component_before != component_after:
            errors.append(f"{path}: component identity changed unexpectedly.")
            continue
        if version_before == version_after:
            if any(metadata_path_for_source(item) == path for item in paths):
                errors.append(
                    f"{component_after}: source changed without a version bump "
                    f"from {version_before}."
                )
            continue
        if not is_direct_step(version_before, version_after):
            errors.append(
                f"{component_after}: {version_before} -> {version_after} is not "
                "one direct patch, minor, or major step."
            )
        transitions.append((component_after, version_before, version_after))

    history = "\n".join(
        read_head(path) or ""
        for path in paths
        if path.startswith("docs/history/records/") and path.endswith(".md")
    )
    for component, before, after in transitions:
        expected = re.compile(
            rf"component:\s*`{re.escape(component)}`\s*\|\s*"
            rf"`{re.escape(before)}\s*->\s*{re.escape(after)}`"
        )
        if not expected.search(history):
            errors.append(
                f"{component}: history must record `{before} -> {after}` "
                "in this change."
            )
    return errors


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--event-name", required=True)
    parser.add_argument("--base-ref", default="")
    parser.add_argument("--head-ref", default="")
    parser.add_argument("--head-repository", default="")
    parser.add_argument("--repository", default="")
    parser.add_argument("--base-sha", required=True)
    parser.add_argument("--head-sha", required=True)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = changed_paths(args.base_sha, args.head_sha)
    errors = validate_branch(
        args.event_name,
        args.base_ref,
        args.head_ref,
        args.head_repository,
        args.repository,
    )
    errors.extend(
        validate_versions(
            paths,
            lambda path: git_text(args.base_sha, path),
            lambda path: git_text(args.head_sha, path),
        )
    )
    if errors:
        for error in errors:
            print(f"::error::{error}")
        return 1
    print("Integration policy passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

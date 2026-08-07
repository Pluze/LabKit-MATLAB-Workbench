#!/usr/bin/env python3
"""Inventory one LabKit squash-PR boundary from repository-owned sources."""

from __future__ import annotations

import argparse
import importlib.util
import pathlib
import re
import subprocess
import sys


def command(*args: str) -> str:
    result = subprocess.run(
        args, check=True, text=True, stdout=subprocess.PIPE
    )
    return result.stdout.strip()


def load_policy(root: pathlib.Path):
    path = root / ".github" / "scripts" / "check_integration_policy.py"
    spec = importlib.util.spec_from_file_location("labkit_integration_policy", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Could not load integration policy from {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def git_text(revision: str, path: str) -> str | None:
    result = subprocess.run(
        ["git", "show", f"{revision}:{path}"],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )
    return result.stdout if result.returncode == 0 else None


def metadata(source: str | None, name: str) -> str:
    if source is None:
        return ""
    match = re.search(rf"^{name}:\s*(.+)$", source, re.MULTILINE)
    return match.group(1).strip() if match else ""


def owning_manual(root: pathlib.Path, component: str, owner: str) -> str | None:
    if component == "labkit.app":
        return "docs/framework/README.md"
    if component == "labkit_launcher":
        return "docs/apps/labkit-core/launcher/README.md"
    parts = pathlib.PurePosixPath(owner).parts
    if len(parts) < 3 or parts[0] != "apps":
        return None
    slug = parts[2].replace("_", "-")
    matches = sorted((root / "docs" / "apps").glob(f"*/{slug}/README.md"))
    if len(matches) != 1:
        return None
    return matches[0].relative_to(root).as_posix()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", default="origin/main")
    parser.add_argument("--head", default="develop")
    args = parser.parse_args()

    root = pathlib.Path(command("git", "rev-parse", "--show-toplevel"))
    policy = load_policy(root)
    base_sha = command("git", "rev-parse", args.base)
    head_sha = command("git", "rev-parse", args.head)
    paths = policy.changed_paths(base_sha, head_sha)
    commits = command("git", "rev-list", "--count", f"{base_sha}..{head_sha}")

    owners = {
        owner
        for path in paths
        if (owner := policy.metadata_path_for_source(path)) is not None
    }
    transitions = []
    for owner in sorted(owners):
        before = policy.version_for_owner(
            owner, lambda path: git_text(base_sha, path)
        )
        after = policy.version_for_owner(
            owner, lambda path: git_text(head_sha, path)
        )
        if before and after and before != after:
            transitions.append((after[0], owner, before[1], after[1]))

    histories = []
    for path in paths:
        if not path.startswith("docs/history/records/") or not path.endswith(".md"):
            continue
        base_source = git_text(base_sha, path)
        source = git_text(head_sha, path)
        if (
            base_source is not None
            and source is not None
            and policy.parse_history_components(base_source)
            == policy.parse_history_components(source)
        ):
            continue
        histories.append(
            (
                metadata(source, "sequence"),
                metadata(source, "id"),
                path,
                policy.parse_history_components(source),
            )
        )
    histories.sort(key=lambda item: int(item[0]) if item[0].isdigit() else 10**9)

    print("# PR boundary")
    print(f"- Base: `{base_sha}` ({args.base})")
    print(f"- Head: `{head_sha}` ({args.head})")
    print(f"- Commits: {commits}")
    print(f"- Changed paths: {len(paths)}")
    print("\n# Version transitions")
    if not transitions:
        print("- None")
    for component, owner, before, after in transitions:
        records = sorted(
            path
            for _, _, path, entries in histories
            if any(
                entry == (component, before, after)
                for entry in entries
            )
        )
        record = ", ".join(f"`{path}`" for path in records) or "missing"
        manual = owning_manual(root, component, owner)
        manual_status = (
            f"`{manual}` ({'changed' if manual in paths else 'UNCHANGED'})"
            if manual else "not resolved"
        )
        print(
            f"- `{component}`: `{before} -> {after}` via `{owner}`; "
            f"history: {record}; manual: {manual_status}"
        )

    print("\n# Changed history records")
    if not histories:
        print("- None")
    for sequence, change_id, path, entries in histories:
        components = ", ".join(
            f"{component} ({before} -> {after})"
            if before else component
            for component, before, after in entries
        ) or "no components"
        print(
            f"- sequence {sequence or '?'} `{change_id or '?'}`: `{path}`; "
            f"{components}"
        )

    errors = policy.validate_versions(
        paths,
        lambda path: git_text(base_sha, path),
        lambda path: git_text(head_sha, path),
    )
    print("\n# Integration policy")
    if errors:
        for error in errors:
            print(f"- ERROR: {error}")
        return 1
    print("- Passed")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except subprocess.CalledProcessError as cause:
        print(f"audit_pr.py: command failed: {cause}", file=sys.stderr)
        raise SystemExit(2) from cause

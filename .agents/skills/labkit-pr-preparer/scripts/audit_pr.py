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
        return "docs/develop/framework/README.md"
    if component == "labkit_launcher":
        return "docs/use/apps/labkit-core/launcher/README.md"
    if component.startswith("labkit."):
        area = component.removeprefix("labkit.")
        manual = root / "docs" / "develop" / "libraries" / area / "README.md"
        if manual.is_file():
            return manual.relative_to(root).as_posix()
        return None
    parts = pathlib.PurePosixPath(owner).parts
    if len(parts) < 3 or parts[0] != "apps":
        return None
    slug = parts[2].replace("_", "-")
    matches = sorted(
        (root / "docs" / "use" / "apps").glob(f"*/{slug}/README.md")
    )
    if len(matches) != 1:
        return None
    return matches[0].relative_to(root).as_posix()


def report_integration_update(policy, base: str, head: str, previous: str) -> None:
    """Compare task deltas across accepted main changes; never approve a push."""
    previous_base = command("git", "merge-base", base, previous)
    old_paths = set(policy.changed_paths(previous_base, previous))
    new_paths = set(policy.changed_paths(base, head))
    upstream_paths = set(policy.changed_paths(previous_base, base))

    def patch(start, end):
        return subprocess.run(
            ["git", "diff", "--binary", "--no-ext-diff", "--no-textconv", start, end],
            check=True, stdout=subprocess.PIPE,
        ).stdout

    unchanged = patch(previous_base, previous) == patch(base, head)
    print("\n# Integration update")
    print(f"- Previous head: `{previous}`; previous base: `{previous_base}`")
    print(f"- Task patch: {'unchanged' if unchanged else 'changed (review required)'}")
    for label, paths in (
        ("Shared changed paths", (old_paths | new_paths) & upstream_paths),
        ("Prior paths absent from task delta", old_paths - new_paths),
        ("New task paths", new_paths - old_paths),
    ):
        listing = ", ".join(f"`{path}`" for path in sorted(paths)) or "none"
        print(f"- {label}: {listing}")
    print("- Review contract interactions and range-diff before publishing; "
          "this inventory does not authorize an update.")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", default="origin/main")
    parser.add_argument("--head", default="HEAD")
    parser.add_argument("--previous-head", help="Prior PR head for a replay comparison")
    args = parser.parse_args()

    root = pathlib.Path(command("git", "rev-parse", "--show-toplevel"))
    policy = load_policy(root)
    base_sha = command("git", "rev-parse", args.base)
    head_sha = command("git", "rev-parse", args.head)
    previous_sha = None
    if args.previous_head:
        previous_sha = command("git", "rev-parse", args.previous_head)
        if command("git", "merge-base", base_sha, head_sha) != base_sha:
            parser.error("--head must descend from --base for an integration update")
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
        if after and before != after:
            transitions.append((
                after[0], owner, before[1] if before else "new", after[1]
            ))

    changes = []
    for path in paths:
        if not policy.is_change_record_path(path):
            continue
        base_source = git_text(base_sha, path)
        source = git_text(head_sha, path)
        if (
            base_source is not None
            and source is not None
            and policy.parse_change_components(base_source)
            == policy.parse_change_components(source)
        ):
            continue
        changes.append(
            (
                metadata(source, "date"),
                metadata(source, "id"),
                path,
                policy.parse_change_components(source),
            )
        )
    changes.sort(key=lambda item: (item[0], item[1], item[2]))

    print("# PR boundary")
    print(f"- Base: `{base_sha}` ({args.base})")
    print(f"- Head: `{head_sha}` ({args.head})")
    print(f"- Commits: {commits}")
    print(f"- Changed paths: {len(paths)}")
    if previous_sha:
        report_integration_update(policy, base_sha, head_sha, previous_sha)
    print("\n# Version transitions")
    if not transitions:
        print("- None")
    for component, owner, before, after in transitions:
        records = sorted(
            path
            for _, _, path, entries in changes
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
            f"Change: {record}; manual: {manual_status}"
        )

    print("\n# Changed Change records")
    if not changes:
        print("- None")
    for date, change_id, path, entries in changes:
        components = ", ".join(
            f"{component} ({before} -> {after})"
            if before else component
            for component, before, after in entries
        ) or "no components"
        print(
            f"- {date or '?'} `{change_id or '?'}`: `{path}`; "
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

#!/usr/bin/env python3
"""Remove column-width wrapping from GitHub-authored Markdown prose."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


FENCE = re.compile(r"^\s*(```+|~~~+)")
LIST_ITEM = re.compile(r"^\s*(?:[-+*]|\d+[.)])(?:\s+|$)")
STRUCTURAL = re.compile(
    r"^\s*(?:#{1,6}\s|>|\||<!--|-->|<[/A-Za-z]|\[[^]]+\]:)"
)
STANDALONE_LINK = re.compile(r"^\s*!?\[[^]]+\]\([^)]+\)\s*$")
HORIZONTAL_RULE = re.compile(r"^\s*(?:(?:-\s*){3,}|(?:\*\s*){3,}|(?:_\s*){3,})$")


def normalize_markdown(text: str) -> str:
    """Join soft-wrapped prose while preserving Markdown-owned line breaks."""
    normalized = text.replace("\r\n", "\n").replace("\r", "\n")
    had_final_newline = normalized.endswith("\n")
    lines = normalized.split("\n")
    if had_final_newline:
        lines.pop()

    output: list[str] = []
    pending: str | None = None
    fence_marker: str | None = None
    in_comment = False
    in_frontmatter = bool(lines and lines[0].strip() == "---")

    def flush() -> None:
        nonlocal pending
        if pending is not None:
            output.append(pending)
            pending = None

    for index, line in enumerate(lines):
        stripped = line.strip()
        if in_frontmatter:
            output.append(line)
            if index > 0 and stripped == "---":
                in_frontmatter = False
            continue
        fence = FENCE.match(line)
        if fence_marker is not None:
            output.append(line)
            if stripped.startswith(fence_marker):
                fence_marker = None
            continue
        if in_comment:
            output.append(line)
            if "-->" in line:
                in_comment = False
            continue
        if fence:
            flush()
            fence_marker = fence.group(1)[:3]
            output.append(line)
            continue
        if stripped.startswith("<!--"):
            flush()
            output.append(line)
            in_comment = "-->" not in line
            continue
        if not stripped:
            flush()
            output.append("")
            continue

        preserve = (
            STRUCTURAL.match(line)
            or STANDALONE_LINK.match(line)
            or HORIZONTAL_RULE.match(line)
            or line.startswith("    ")
            or line.startswith("\t")
        )
        if preserve:
            flush()
            output.append(line)
            continue
        if LIST_ITEM.match(line):
            flush()
            pending = line
            continue
        if pending is None:
            pending = line
            continue
        if pending.endswith("  ") or pending.endswith("\\"):
            flush()
            pending = line
            continue
        pending = pending.rstrip() + " " + stripped

    flush()
    result = "\n".join(output)
    if had_final_newline:
        result += "\n"
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("paths", nargs="*", type=Path)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    if args.check and args.write:
        parser.error("--check and --write are mutually exclusive")
    if not args.paths:
        if args.check or args.write:
            parser.error("--check and --write require at least one path")
        sys.stdout.write(normalize_markdown(sys.stdin.read()))
        return 0

    changed: list[Path] = []
    for path in args.paths:
        original = path.read_text(encoding="utf-8")
        normalized = normalize_markdown(original)
        if normalized == original:
            continue
        changed.append(path)
        if args.write:
            path.write_text(normalized, encoding="utf-8", newline="\n")
    if args.check and changed:
        for path in changed:
            print(f"GitHub Markdown contains column-width wrapping: {path}")
        return 1
    if not args.check and not args.write:
        if len(args.paths) != 1:
            parser.error("plain output mode accepts exactly one path")
        sys.stdout.write(normalize_markdown(args.paths[0].read_text(encoding="utf-8")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

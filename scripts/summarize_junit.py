#!/usr/bin/env python3
"""Summarize a MATLAB JUnit XML report for GitHub Actions.

The script is intentionally dependency-free so CI failure summaries keep working
before Python packages are installed. It never fails the job; MATLAB test steps
own pass/fail status. This helper only surfaces failed testcase names, messages,
and a short MATLAB log tail in the GitHub job summary and annotations.
"""

from __future__ import annotations

import argparse
import os
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Iterable


def main() -> int:
    args = parse_args()
    summary_path = Path(os.environ.get("GITHUB_STEP_SUMMARY", ""))
    junit_path = Path(args.junit_xml)
    run_name = args.run_name

    if not junit_path.is_file():
        message = f"JUnit report not found: {junit_path}"
        write_summary(
            summary_path,
            [
                f"### {run_name}",
                "",
                f"> ⚠️ {message}",
                "",
                artifact_lines(args),
                "",
            ],
        )
        print_annotation("warning", f"{run_name} report missing", message)
        print_log_tail(args.log, args.log_tail_lines, "MATLAB log tail")
        return 0

    try:
        suites, failed_cases = parse_junit(junit_path)
    except Exception as exc:  # pragma: no cover - defensive CI reporting path.
        message = f"Could not parse {junit_path}: {exc}"
        write_summary(summary_path, [f"### {run_name}", "", f"> ⚠️ {message}", ""])
        print_annotation("warning", f"{run_name} report parse failed", message)
        print_log_tail(args.log, args.log_tail_lines, "MATLAB log tail")
        return 0

    totals = {
        "tests": sum(to_int(s.get("tests")) for s in suites),
        "failures": sum(to_int(s.get("failures")) for s in suites),
        "errors": sum(to_int(s.get("errors")) for s in suites),
        "skipped": sum(to_int(s.get("skipped")) for s in suites),
        "time": sum(to_float(s.get("time")) for s in suites),
    }

    lines = [
        f"### {run_name}",
        "",
        "| tests | failures | errors | skipped | time (s) |",
        "|---:|---:|---:|---:|---:|",
        (
            f"| {totals['tests']} | {totals['failures']} | {totals['errors']} | "
            f"{totals['skipped']} | {totals['time']:.2f} |"
        ),
        "",
        artifact_lines(args),
        "",
    ]

    if failed_cases:
        lines += [
            f"#### Failed tests ({len(failed_cases)})",
            "",
            "| Class | Test | Message |",
            "|---|---|---|",
        ]
        for case in failed_cases[: args.max_failures]:
            lines.append(
                f"| `{case['classname']}` | `{case['name']}` | {markdown_escape(case['message'])} |"
            )
        if len(failed_cases) > args.max_failures:
            lines.append("")
            lines.append(
                f"Showing first {args.max_failures} failures; inspect artifacts for the full report."
            )
        lines.append("")

        for case in failed_cases[: args.max_annotations]:
            print_annotation(
                case["kind"],
                f"{run_name}: {case['classname']}.{case['name']}",
                case["message"],
            )
        print_log_tail(args.log, args.log_tail_lines, "MATLAB log tail after test failure")
    else:
        lines += ["No failed tests reported in JUnit.", ""]

    write_summary(summary_path, lines)
    print(
        (
            f"{run_name}: {totals['tests']} tests, {totals['failures']} failures, "
            f"{totals['errors']} errors, {totals['skipped']} skipped."
        )
    )
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("junit_xml", help="Path to the JUnit XML report.")
    parser.add_argument("--run-name", required=True, help="Display name in GitHub summaries.")
    parser.add_argument("--html", default="", help="Path to the MATLAB HTML test report.")
    parser.add_argument("--log", default="", help="Path to the MATLAB log file.")
    parser.add_argument("--max-failures", type=int, default=20)
    parser.add_argument("--max-annotations", type=int, default=20)
    parser.add_argument("--log-tail-lines", type=int, default=180)
    return parser.parse_args()


def parse_junit(junit_path: Path) -> tuple[list[ET.Element], list[dict[str, str]]]:
    root = ET.parse(junit_path).getroot()
    suites = [root] if strip_namespace(root.tag) == "testsuite" else root.findall(".//testsuite")
    failed_cases: list[dict[str, str]] = []
    for testcase in root.findall(".//testcase"):
        for tag in ("failure", "error"):
            node = testcase.find(tag)
            if node is None:
                continue
            failed_cases.append(
                {
                    "classname": testcase.get("classname", ""),
                    "name": testcase.get("name", ""),
                    "message": compact_message(node.get("message") or node.text or ""),
                    "kind": tag,
                }
            )
            break
    return suites, failed_cases


def artifact_lines(args: argparse.Namespace) -> str:
    rows = []
    if args.html:
        rows.append(f"- HTML report: `{args.html}`")
    if args.log:
        rows.append(f"- MATLAB log: `{args.log}`")
    rows.append(f"- JUnit XML: `{args.junit_xml}`")
    return "\n".join(rows)


def print_log_tail(log_path: str, line_count: int, title: str) -> None:
    if not log_path:
        return
    path = Path(log_path)
    if not path.is_file():
        print(f"MATLAB log not found: {path}")
        return

    print(f"::group::{title}")
    try:
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
        for line in lines[-line_count:]:
            print(line)
    finally:
        print("::endgroup::")


def print_annotation(level: str, title: str, message: str) -> None:
    level = "error" if level == "failure" else level
    print(f"::{level} title={escape_command(title)}::{escape_command(message)}")


def write_summary(path: Path, lines: Iterable[str]) -> None:
    if not str(path):
        return
    with path.open("a", encoding="utf-8") as handle:
        handle.write("\n".join(lines))
        handle.write("\n")


def compact_message(message: str) -> str:
    message = re.sub(r"\s+", " ", message).strip()
    return message[:500] if message else "(no message)"


def markdown_escape(message: str) -> str:
    return message.replace("|", "\\|")


def escape_command(value: str) -> str:
    return (
        value.replace("%", "%25")
        .replace("\r", "%0D")
        .replace("\n", "%0A")
    )


def strip_namespace(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def to_int(value: str | None) -> int:
    try:
        return int(value or 0)
    except ValueError:
        return 0


def to_float(value: str | None) -> float:
    try:
        return float(value or 0)
    except ValueError:
        return 0.0


if __name__ == "__main__":
    sys.exit(main())

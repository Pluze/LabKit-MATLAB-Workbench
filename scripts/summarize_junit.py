#!/usr/bin/env python3
"""Summarize a MATLAB JUnit XML report for GitHub Actions.

The script is intentionally dependency-free so CI failure summaries keep working
before Python packages are installed. It never fails the job; MATLAB test steps
own pass/fail status. This helper only surfaces failed testcase names, messages,
slow testcase hints, artifact locations, and a short MATLAB log tail in the
GitHub job summary and annotations.
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
        lines = [
            f"### {run_name}",
            "",
            f"> Warning: {message}",
            "",
            artifact_lines(args),
            "",
        ]
        lines += log_tail_summary(args.log, args.summary_log_tail_lines)
        write_summary(summary_path, lines)
        print_annotation("warning", f"{run_name} report missing", message)
        print_log_tail(args.log, args.log_tail_lines, "MATLAB log tail")
        return 0

    try:
        suites, failed_cases = parse_junit(junit_path)
    except Exception as exc:  # pragma: no cover - defensive CI reporting path.
        message = f"Could not parse {junit_path}: {exc}"
        lines = [f"### {run_name}", "", f"> Warning: {message}", ""]
        lines += log_tail_summary(args.log, args.summary_log_tail_lines)
        write_summary(summary_path, lines)
        print_annotation("warning", f"{run_name} report parse failed", message)
        print_log_tail(args.log, args.log_tail_lines, "MATLAB log tail")
        return 0

    test_cases = parse_test_cases(suites)
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
        lines += failure_detail_lines(failed_cases, args.max_failure_details)
        lines += log_tail_summary(args.log, args.summary_log_tail_lines)

        for case in failed_cases[: args.max_annotations]:
            print_annotation(
                case["kind"],
                f"{run_name}: {case['classname']}.{case['name']}",
                case["message"],
            )
        print_log_tail(args.log, args.log_tail_lines, "MATLAB log tail after test failure")
    else:
        lines += ["No failed tests reported in JUnit.", ""]

    lines += slow_test_lines(test_cases, args.max_slow_tests)
    lines += shard_estimate_lines(test_cases, args.shard_estimates)
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
    parser.add_argument("--max-failure-details", type=int, default=5)
    parser.add_argument("--max-slow-tests", type=int, default=5)
    parser.add_argument(
        "--shard-estimates",
        default="2,3,5",
        help=(
            "Comma-separated shard counts for deterministic and duration-aware "
            "timing estimates; use an empty value to disable."
        ),
    )
    parser.add_argument("--log-tail-lines", type=int, default=180)
    parser.add_argument("--summary-log-tail-lines", type=int, default=80)
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
                    "detail": compact_detail(node.text or node.get("message") or ""),
                    "kind": tag,
                }
            )
            break
    return suites, failed_cases


def parse_test_cases(suites: list[ET.Element]) -> list[dict[str, str | float]]:
    test_cases: list[dict[str, str | float]] = []
    for suite in suites:
        suite_name = suite.get("name", "")
        for testcase in suite.findall("testcase"):
            test_cases.append(
                {
                    "suite": suite_name,
                    "classname": testcase.get("classname", ""),
                    "name": testcase.get("name", ""),
                    "time": to_float(testcase.get("time")),
                }
            )
    return test_cases


def artifact_lines(args: argparse.Namespace) -> str:
    rows = []
    url = github_artifacts_url()
    if url:
        rows.append(f"- Run artifacts page: [open artifacts for this run]({url})")
    if args.html:
        rows.append(
            "- HTML report in artifact: "
            f"`{args.html}` (download the artifact; Actions does not render artifact HTML inline)"
        )
    if args.log:
        rows.append(f"- MATLAB log: `{args.log}`")
    rows.append(f"- JUnit XML: `{args.junit_xml}`")
    return "\n".join(rows)


def github_artifacts_url() -> str:
    server = os.environ.get("GITHUB_SERVER_URL", "")
    repo = os.environ.get("GITHUB_REPOSITORY", "")
    run_id = os.environ.get("GITHUB_RUN_ID", "")
    if not server or not repo or not run_id:
        return ""
    return f"{server.rstrip('/')}/{repo}/actions/runs/{run_id}#artifacts"


def failure_detail_lines(
    failed_cases: list[dict[str, str]], max_failure_details: int
) -> list[str]:
    if max_failure_details <= 0:
        return []
    lines = [
        f"#### Failure details (first {min(len(failed_cases), max_failure_details)})",
        "",
    ]
    for case in failed_cases[:max_failure_details]:
        title = f"{case['classname']}.{case['name']}"
        lines += [
            "<details>",
            f"<summary><code>{markdown_escape(title)}</code></summary>",
            "",
            "```text",
            fence_escape(case["detail"]),
            "```",
            "",
            "</details>",
            "",
        ]
    return lines


def slow_test_lines(
    test_cases: list[dict[str, str | float]], max_slow_tests: int
) -> list[str]:
    if max_slow_tests <= 0 or not test_cases:
        return []
    slow_cases = sorted(test_cases, key=lambda case: float(case["time"]), reverse=True)
    slow_cases = slow_cases[:max_slow_tests]
    lines = [
        f"#### Slowest tests (top {len(slow_cases)})",
        "",
        "| Class | Test | time (s) |",
        "|---|---|---:|",
    ]
    for case in slow_cases:
        lines.append(
            f"| `{case['classname']}` | `{case['name']}` | {float(case['time']):.2f} |"
        )
    lines.append("")
    return lines


def shard_estimate_lines(
    test_cases: list[dict[str, str | float]], shard_estimates: str
) -> list[str]:
    counts = parse_shard_counts(shard_estimates)
    timed_cases = [case for case in test_cases if float(case["time"]) > 0]
    if not counts or len(timed_cases) < 2:
        return []

    lines = [
        "#### Shard timing estimates",
        "",
        (
            "Estimates use testcase durations from this JUnit report. "
            "Deterministic matches LabKit's current name-sorted modulo sharding; "
            "duration-aware is a greedy balance estimate for planning only."
        ),
        "",
        "| shards | deterministic max (s) | duration-aware max (s) | total test time (s) |",
        "|---:|---:|---:|---:|",
    ]
    total = sum(float(case["time"]) for case in timed_cases)
    for count in counts:
        deterministic = estimate_deterministic_shards(timed_cases, count)
        duration_aware = estimate_duration_aware_shards(timed_cases, count)
        lines.append(
            f"| {count} | {max(deterministic):.2f} | "
            f"{max(duration_aware):.2f} | {total:.2f} |"
        )
    lines.append("")
    return lines


def parse_shard_counts(value: str) -> list[int]:
    counts: list[int] = []
    for part in value.split(","):
        part = part.strip()
        if not part:
            continue
        try:
            count = int(part)
        except ValueError:
            continue
        if count > 1 and count not in counts:
            counts.append(count)
    return counts


def estimate_deterministic_shards(
    test_cases: list[dict[str, str | float]], shard_count: int
) -> list[float]:
    totals = [0.0] * shard_count
    ordered = sorted(test_cases, key=test_identity_key)
    for index, case in enumerate(ordered):
        totals[index % shard_count] += float(case["time"])
    return totals


def estimate_duration_aware_shards(
    test_cases: list[dict[str, str | float]], shard_count: int
) -> list[float]:
    totals = [0.0] * shard_count
    ordered = sorted(test_cases, key=lambda case: float(case["time"]), reverse=True)
    for case in ordered:
        shard_index = min(range(shard_count), key=lambda index: totals[index])
        totals[shard_index] += float(case["time"])
    return totals


def test_identity_key(case: dict[str, str | float]) -> str:
    return (
        f"{str(case['classname']).lower()}"
        f".{str(case['name']).lower()}"
    )


def log_tail_summary(log_path: str, line_count: int) -> list[str]:
    if not log_path or line_count <= 0:
        return []
    path = Path(log_path)
    if not path.is_file():
        return [
            "#### MATLAB log tail",
            "",
            f"> MATLAB log not found: `{path}`",
            "",
        ]
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    tail = lines[-line_count:]
    return [
        f"#### MATLAB log tail (last {len(tail)} lines)",
        "",
        "<details>",
        "<summary>Show MATLAB log tail</summary>",
        "",
        "```text",
        fence_escape("\n".join(tail)),
        "```",
        "",
        "</details>",
        "",
    ]


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


def compact_detail(message: str) -> str:
    message = message.strip()
    if not message:
        return "(no detail)"
    max_chars = 6000
    if len(message) <= max_chars:
        return message
    return message[:max_chars] + "\n... truncated ..."


def markdown_escape(message: str) -> str:
    return message.replace("|", "\\|")


def fence_escape(message: str) -> str:
    return message.replace("```", "` ` `")


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

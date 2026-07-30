#!/usr/bin/env python3
"""Publish one evidence-oriented summary for a MATLAB validation shard.

The helper is dependency-free and deliberately does not own the job result.
The workflow's final outcome gate remains authoritative. This script combines
the independent MATLAB sessions scheduled in one job, explains what each
proves, distinguishes runner failures from test failures, and keeps bulky
diagnostics collapsed.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import xml.etree.ElementTree as ET
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable


PROFILE_METADATA = {
    "headless": (
        "Non-GUI",
        "Product, SDK, persistence, calculation, policy, and export specifications",
    ),
    "gui": (
        "Hidden GUI",
        "Native App construction, callback wiring, graphics, and export workflows",
    ),
    "isolated": (
        "Path isolation",
        "Every public App starts from a reset path without undeclared sibling dependencies",
    ),
}


@dataclass
class ProfileResult:
    key: str
    outcome: str
    report_path: Path
    log_path: Path
    active_test_path: Path
    tests: int = 0
    failures: int = 0
    errors: int = 0
    skipped: int = 0
    duration: float = 0.0
    cases: list[dict[str, str | float]] = field(default_factory=list)
    failed_cases: list[dict[str, str]] = field(default_factory=list)
    report_problem: str = ""

    @property
    def passed(self) -> bool:
        return (
            self.outcome == "success"
            and not self.report_problem
            and self.failures == 0
            and self.errors == 0
        )

    @property
    def failed(self) -> bool:
        if self.failures > 0 or self.errors > 0 or self.failed_cases:
            return True
        if self.outcome == "failure":
            return True
        return self.outcome == "success" and bool(self.report_problem)

    @property
    def status(self) -> str:
        if self.passed:
            return "✅ Passed"
        if self.outcome in {"cancelled", "skipped"}:
            return "⏭️ " + self.outcome.capitalize()
        return "❌ Failed"


def main() -> int:
    args = parse_args()
    profile_keys = parse_profiles(args.profiles)
    outcomes = {
        "headless": args.headless_outcome,
        "gui": args.gui_outcome,
        "isolated": args.isolated_outcome,
    }
    profiles = [
        load_profile(key, outcomes[key], args.artifacts_root)
        for key in profile_keys
    ]
    summary_value = os.environ.get("GITHUB_STEP_SUMMARY", "")
    summary_path = Path(summary_value) if summary_value else None
    verdict = overall_verdict(profiles)

    lines = summary_header(args, profiles, verdict)
    lines += profile_table(profiles)
    lines += interpretation(args, profiles, verdict)
    if verdict != "passed":
        lines += failure_sections(profiles, args)
    lines += slow_test_lines(profiles, args.max_slow_tests)
    lines += evidence_lines(args)
    write_summary(summary_path, lines)
    publish_annotations(profiles, args.max_annotations)
    print_failure_logs(profiles, args.log_tail_lines)
    print(
        f"{args.platform} {args.release} {args.shard}: validation {verdict}."
    )
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--platform", required=True)
    parser.add_argument("--release", required=True)
    parser.add_argument("--runner", required=True)
    parser.add_argument("--shard", default="All profiles")
    parser.add_argument(
        "--profiles",
        default="headless,gui,isolated",
        help="Comma-separated profiles scheduled in this job",
    )
    parser.add_argument("--claim", required=True)
    parser.add_argument("--artifact-name", required=True)
    parser.add_argument("--artifacts-root", default="artifacts")
    parser.add_argument("--headless-outcome", required=True)
    parser.add_argument("--gui-outcome", required=True)
    parser.add_argument("--isolated-outcome", required=True)
    parser.add_argument("--max-failures", type=int, default=20)
    parser.add_argument("--max-annotations", type=int, default=20)
    parser.add_argument("--max-failure-details", type=int, default=5)
    parser.add_argument("--max-slow-tests", type=int, default=5)
    parser.add_argument("--log-tail-lines", type=int, default=180)
    parser.add_argument("--summary-log-tail-lines", type=int, default=80)
    return parser.parse_args()


def parse_profiles(value: str) -> list[str]:
    profiles = [item.strip().lower() for item in value.split(",") if item.strip()]
    invalid = [item for item in profiles if item not in PROFILE_METADATA]
    if not profiles:
        raise ValueError("At least one validation profile is required")
    if invalid:
        raise ValueError("Unknown validation profile(s): " + ", ".join(invalid))
    if len(set(profiles)) != len(profiles):
        raise ValueError("Validation profiles must be unique")
    return profiles


def load_profile(key: str, outcome: str, artifacts_root: str) -> ProfileResult:
    root = Path(artifacts_root)
    report = root / "test-results" / key / "junit.xml"
    profile = ProfileResult(
        key=key,
        outcome=outcome.lower(),
        report_path=report,
        log_path=root / "logs" / key / "matlab.log",
        active_test_path=root / "test-results" / key / "active-test.json",
    )
    if not report.is_file():
        profile.report_problem = "JUnit report was not produced"
        return profile
    try:
        suites, profile.failed_cases = parse_junit(report)
    except (OSError, ET.ParseError) as exc:
        profile.report_problem = f"JUnit report could not be parsed: {exc}"
        return profile
    profile.cases = parse_test_cases(suites)
    profile.tests = sum(to_int(suite.get("tests")) for suite in suites)
    profile.failures = sum(to_int(suite.get("failures")) for suite in suites)
    profile.errors = sum(to_int(suite.get("errors")) for suite in suites)
    profile.skipped = sum(to_int(suite.get("skipped")) for suite in suites)
    profile.duration = sum(to_float(suite.get("time")) for suite in suites)
    return profile


def summary_header(
    args: argparse.Namespace, profiles: list[ProfileResult], verdict: str
) -> list[str]:
    icon = {"passed": "✅", "failed": "❌", "incomplete": "⏸️"}[verdict]
    verdict_text = {
        "passed": "passed",
        "failed": "failed",
        "incomplete": "incomplete",
    }[verdict]
    full_platform = {profile.key for profile in profiles} == set(PROFILE_METADATA)
    subject = (
        "LabKit MATLAB compatibility"
        if full_platform
        else f"LabKit MATLAB {args.shard} validation"
    )
    passed_count = sum(profile.passed for profile in profiles)
    completed_count = sum(profile.passed or profile.failed for profile in profiles)
    profile_count = len(profiles)
    return [
        f"# {icon} {subject} {verdict_text}",
        "",
        f"**{args.platform} · {args.release} · {args.shard} · `{args.runner}`**",
        "",
        f"> Compatibility claim: {args.claim}.",
        "",
        (
            f"**Result:** {passed_count}/{profile_count} scheduled independent "
            f"MATLAB sessions passed; {completed_count}/{profile_count} produced "
            "a conclusive result. "
            "A profile counts as passed only when its build step succeeds and its "
            "JUnit report is present, parseable, and failure-free."
        ),
        "",
    ]


def profile_table(profiles: list[ProfileResult]) -> list[str]:
    lines = [
        "## Validation evidence",
        "",
        "| Profile | Status | What it proves | Tests | Failed | Skipped | Time |",
        "|---|---|---|---:|---:|---:|---:|",
    ]
    for profile in profiles:
        label, purpose = PROFILE_METADATA[profile.key]
        failed = profile.failures + profile.errors
        lines.append(
            f"| **{label}** | {profile.status} | {purpose} | "
            f"{profile.tests} | {failed} | {profile.skipped} | "
            f"{format_duration(profile.duration)} |"
        )
    lines.append("")
    return lines


def interpretation(
    args: argparse.Namespace, profiles: list[ProfileResult], verdict: str
) -> list[str]:
    lines = ["## What to note", ""]
    if verdict == "passed":
        lines += [
            "- MATLAB was installed once for this validation shard, while each "
            "scheduled profile ran in a separate batch session so setup was reused "
            "without sharing MATLAB state.",
            "- The run used a clean MATLAB installation without optional Toolboxes.",
        ]
        if args.platform == "Linux":
            lines.append(
                "- GUI evidence used an X virtual framebuffer at 1920×1080; it "
                "therefore exercises graphics with a display service."
            )
    elif verdict == "failed":
        failed = [PROFILE_METADATA[p.key][0] for p in profiles if p.failed]
        passed = [PROFILE_METADATA[p.key][0] for p in profiles if p.passed]
        lines.append(f"- **Requires action:** {', '.join(failed)}.")
        if passed:
            lines.append(
                "- **Still proven by this run:** " + ", ".join(passed) + " passed."
            )
        lines.append(
            "- A failed build step with no JUnit report indicates setup, MATLAB "
            "startup, timeout, or runner failure rather than a reported test failure."
        )
    else:
        incomplete = [
            PROFILE_METADATA[p.key][0]
            for p in profiles
            if not p.passed and not p.failed
        ]
        passed = [PROFILE_METADATA[p.key][0] for p in profiles if p.passed]
        lines.append(
            "- **No test failure was reported.** A compatibility conclusion was "
            "not reached because this job did not finish: "
            + ", ".join(incomplete)
            + "."
        )
        if passed:
            lines.append(
                "- **Still proven by this run:** " + ", ".join(passed) + " passed."
            )
    lines += [
        "- Automated hidden-GUI checks do **not** prove native dialog interaction, "
        "pointer feel, visual quality, real-data suitability, or scientific validity.",
        "",
    ]
    return lines


def failure_sections(
    profiles: list[ProfileResult], args: argparse.Namespace
) -> list[str]:
    failed_profiles = [profile for profile in profiles if profile.failed]
    incomplete_profiles = [
        profile for profile in profiles if not profile.passed and not profile.failed
    ]
    lines: list[str] = []
    if failed_profiles:
        lines += ["## Failures requiring action", ""]
        lines += profile_problem_sections(failed_profiles, args, incomplete=False)
    if incomplete_profiles:
        lines += ["## Validation not completed", ""]
        lines += profile_problem_sections(incomplete_profiles, args, incomplete=True)
    return lines


def profile_problem_sections(
    profiles: list[ProfileResult], args: argparse.Namespace, incomplete: bool
) -> list[str]:
    lines: list[str] = []
    for profile in profiles:
        label = PROFILE_METADATA[profile.key][0]
        lines += [f"### {label}", ""]
        if incomplete:
            lines += [
                f"> Profile `{profile.outcome}` before it produced a conclusive "
                "JUnit result. This is missing evidence, not a compatibility failure.",
                "",
            ]
        elif profile.report_problem:
            lines += [
                f"> **Runner/report failure:** {profile.report_problem}. "
                f"Build-step outcome: `{profile.outcome}`.",
                "",
            ]
        if profile.failed_cases:
            lines += [
                "| Class | Test | Diagnostic |",
                "|---|---|---|",
            ]
            for case in profile.failed_cases[: args.max_failures]:
                lines.append(
                    f"| `{case['classname']}` | `{case['name']}` | "
                    f"{markdown_escape(case['message'])} |"
                )
            if len(profile.failed_cases) > args.max_failures:
                lines += [
                    "",
                    f"Showing the first {args.max_failures} failures; use the JUnit "
                    "artifact for the complete set.",
                ]
            lines.append("")
            lines += failure_detail_lines(
                profile.failed_cases, args.max_failure_details
            )
        lines += active_test_lines(profile.active_test_path)
        lines += log_tail_summary(
            profile.log_path, args.summary_log_tail_lines
        )
    return lines


def overall_verdict(profiles: list[ProfileResult]) -> str:
    if all(profile.passed for profile in profiles):
        return "passed"
    if any(profile.failed for profile in profiles):
        return "failed"
    return "incomplete"


def parse_junit(junit_path: Path) -> tuple[list[ET.Element], list[dict[str, str]]]:
    root = ET.parse(junit_path).getroot()
    suites = (
        [root]
        if strip_namespace(root.tag) == "testsuite"
        else root.findall(".//testsuite")
    )
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
    cases: list[dict[str, str | float]] = []
    for suite in suites:
        for testcase in suite.findall("testcase"):
            cases.append(
                {
                    "classname": testcase.get("classname", ""),
                    "name": testcase.get("name", ""),
                    "time": to_float(testcase.get("time")),
                }
            )
    return cases


def failure_detail_lines(
    failed_cases: list[dict[str, str]], max_details: int
) -> list[str]:
    lines: list[str] = []
    for case in failed_cases[:max_details]:
        identity = f"{case['classname']}.{case['name']}"
        lines += [
            "<details>",
            f"<summary>Diagnostic for <code>{markdown_escape(identity)}</code></summary>",
            "",
            "```text",
            fence_escape(case["detail"]),
            "```",
            "",
            "</details>",
            "",
        ]
    return lines


def active_test_lines(path: Path) -> list[str]:
    if not path.is_file():
        return []
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return []
    test_name = str(payload.get("test", "unknown"))
    state = str(payload.get("event", "unknown"))
    elapsed = to_float(payload.get("testElapsedSeconds"))
    return [
        f"Last recorded test: `{markdown_escape(test_name)}` "
        f"(`{markdown_escape(state)}`, {elapsed:.2f}s at last update).",
        "",
    ]


def log_tail_summary(path: Path, line_count: int) -> list[str]:
    if not path.is_file() or line_count <= 0:
        return []
    tail = path.read_text(encoding="utf-8", errors="replace").splitlines()[-line_count:]
    return [
        "<details>",
        f"<summary>MATLAB log tail ({len(tail)} lines)</summary>",
        "",
        "```text",
        fence_escape("\n".join(tail)),
        "```",
        "",
        "</details>",
        "",
    ]


def slow_test_lines(
    profiles: list[ProfileResult], max_tests: int
) -> list[str]:
    cases = [
        {**case, "profile": PROFILE_METADATA[profile.key][0]}
        for profile in profiles
        for case in profile.cases
    ]
    if max_tests <= 0 or not cases:
        return []
    slow = sorted(cases, key=lambda case: float(case["time"]), reverse=True)[:max_tests]
    lines = [
        "## Performance signals",
        "",
        f"Slowest {len(slow)} tests across {len(profiles)} independent session(s):",
        "",
        "| Profile | Test | Time |",
        "|---|---|---:|",
    ]
    for case in slow:
        identity = f"{case['classname']}.{case['name']}"
        lines.append(
            f"| {case['profile']} | `{markdown_escape(identity)}` | "
            f"{float(case['time']):.2f}s |"
        )
    lines.append("")
    return lines


def evidence_lines(args: argparse.Namespace) -> list[str]:
    profiles = parse_profiles(args.profiles)
    commands = ", ".join(f"`buildtool {profile}`" for profile in profiles)
    lines = [
        "## Evidence and reproduction",
        "",
        f"- Artifact: `{args.artifact_name}` (retained for 14 days)",
    ]
    url = github_artifacts_url()
    if url:
        lines.append(f"- [Open this run's artifacts]({url})")
    lines += [
        "- JUnit: `artifacts/test-results/<profile>/junit.xml`",
        "- Active-test state: `artifacts/test-results/<profile>/active-test.json`",
        "- Reviewable images: "
        "`artifacts/test-results/<profile>/visual-evidence/` (when produced)",
        "- MATLAB log: `artifacts/logs/<profile>/matlab.log`",
        f"- Local equivalent: {commands} in separate MATLAB sessions",
        "",
    ]
    return lines


def publish_annotations(profiles: list[ProfileResult], max_annotations: int) -> None:
    count = 0
    for profile in profiles:
        label = PROFILE_METADATA[profile.key][0]
        if profile.report_problem and profile.failed and count < max_annotations:
            print_annotation(
                "error",
                f"{label} report unavailable",
                f"{profile.report_problem}; build outcome: {profile.outcome}",
            )
            count += 1
        for case in profile.failed_cases:
            if count >= max_annotations:
                return
            print_annotation(
                case["kind"],
                f"{label}: {case['classname']}.{case['name']}",
                case["message"],
            )
            count += 1


def print_failure_logs(profiles: list[ProfileResult], line_count: int) -> None:
    for profile in profiles:
        if not profile.failed or not profile.log_path.is_file():
            continue
        label = PROFILE_METADATA[profile.key][0]
        print(f"::group::{label} MATLAB log tail")
        try:
            lines = profile.log_path.read_text(
                encoding="utf-8", errors="replace"
            ).splitlines()
            for line in lines[-line_count:]:
                print(line)
        finally:
            print("::endgroup::")


def github_artifacts_url() -> str:
    server = os.environ.get("GITHUB_SERVER_URL", "")
    repo = os.environ.get("GITHUB_REPOSITORY", "")
    run_id = os.environ.get("GITHUB_RUN_ID", "")
    if not server or not repo or not run_id:
        return ""
    return f"{server.rstrip('/')}/{repo}/actions/runs/{run_id}#artifacts"


def write_summary(path: Path | None, lines: Iterable[str]) -> None:
    if path is None:
        return
    with path.open("a", encoding="utf-8") as handle:
        handle.write("\n".join(lines))
        handle.write("\n")


def print_annotation(level: str, title: str, message: str) -> None:
    level = "error" if level == "failure" else level
    print(f"::{level} title={escape_command(title)}::{escape_command(message)}")


def compact_message(message: str) -> str:
    message = re.sub(r"\s+", " ", message).strip()
    return message[:500] if message else "(no diagnostic supplied)"


def compact_detail(message: str) -> str:
    message = message.strip()
    if not message:
        return "(no diagnostic supplied)"
    return message if len(message) <= 6000 else message[:6000] + "\n... truncated ..."


def format_duration(seconds: float) -> str:
    minutes, remaining = divmod(seconds, 60)
    if minutes:
        return f"{int(minutes)}m {remaining:.0f}s"
    return f"{remaining:.1f}s"


def markdown_escape(message: object) -> str:
    return str(message).replace("|", "\\|")


def fence_escape(message: object) -> str:
    return str(message).replace("```", "` ` `")


def escape_command(value: object) -> str:
    return (
        str(value)
        .replace("%", "%25")
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

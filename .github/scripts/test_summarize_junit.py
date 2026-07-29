#!/usr/bin/env python3
"""Regression tests for the platform-level MATLAB CI summary."""

import contextlib
import importlib.util
import io
import os
import pathlib
import sys
import tempfile
import unittest
from unittest import mock


SCRIPT = pathlib.Path(__file__).with_name("summarize_junit.py")
SPEC = importlib.util.spec_from_file_location("summarize_junit", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


class SummarizeJunitTest(unittest.TestCase):
    def test_success_explains_claim_profiles_and_limitations(self):
        with tempfile.TemporaryDirectory() as folder:
            root = pathlib.Path(folder)
            for profile in ("headless", "gui", "isolated"):
                self.write_report(root, profile, failed=False)
            summary = root / "summary.md"

            result = self.run_summary(root, summary, ["success"] * 3)

            self.assertEqual(result, 0)
            content = summary.read_text(encoding="utf-8")
            self.assertIn("# ✅ LabKit MATLAB compatibility passed", content)
            self.assertIn("Compatibility claim: supported release floor", content)
            self.assertIn("Product, SDK, persistence", content)
            self.assertIn("Every public App starts from a reset path", content)
            self.assertIn("do **not** prove native dialog interaction", content)
            self.assertIn("3/3 independent MATLAB sessions passed", content)

    def test_failure_names_test_and_preserves_passing_profiles(self):
        with tempfile.TemporaryDirectory() as folder:
            root = pathlib.Path(folder)
            self.write_report(root, "headless", failed=True)
            self.write_report(root, "gui", failed=False)
            self.write_report(root, "isolated", failed=False)
            summary = root / "summary.md"

            result = self.run_summary(
                root, summary, ["failure", "success", "success"]
            )

            self.assertEqual(result, 0)
            content = summary.read_text(encoding="utf-8")
            self.assertIn("# ❌ LabKit MATLAB compatibility failed", content)
            self.assertIn("FigureStudioResultSpec", content)
            self.assertIn("exported title exceeded canvas", content)
            self.assertIn("Still proven by this run", content)
            self.assertIn("Hidden GUI, Path isolation passed", content)

    def test_failed_step_without_junit_is_reported_as_runner_failure(self):
        with tempfile.TemporaryDirectory() as folder:
            root = pathlib.Path(folder)
            self.write_report(root, "gui", failed=False)
            self.write_report(root, "isolated", failed=False)
            summary = root / "summary.md"

            result = self.run_summary(
                root, summary, ["failure", "success", "success"]
            )

            self.assertEqual(result, 0)
            content = summary.read_text(encoding="utf-8")
            self.assertIn("Runner/report failure", content)
            self.assertIn("JUnit report was not produced", content)

    def run_summary(self, root, summary, outcomes):
        arguments = [
            "summarize_junit.py",
            "--platform",
            "Windows",
            "--release",
            "R2022b",
            "--runner",
            "windows-2022",
            "--claim",
            "supported release floor",
            "--artifact-name",
            "matlab-windows-R2022b",
            "--artifacts-root",
            str(root),
            "--headless-outcome",
            outcomes[0],
            "--gui-outcome",
            outcomes[1],
            "--isolated-outcome",
            outcomes[2],
        ]
        with mock.patch.dict(os.environ, {"GITHUB_STEP_SUMMARY": str(summary)}):
            with mock.patch.object(MODULE.sys, "argv", arguments):
                with contextlib.redirect_stdout(io.StringIO()):
                    return MODULE.main()

    @staticmethod
    def write_report(root, profile, failed):
        report = root / "test-results" / profile / "junit.xml"
        report.parent.mkdir(parents=True, exist_ok=True)
        failure = (
            '<failure message="exported title exceeded canvas">'
            "expected y &lt;= height</failure>"
            if failed
            else ""
        )
        failures = 1 if failed else 0
        report.write_text(
            '<?xml version="1.0" encoding="UTF-8"?>\n'
            "<testsuites>"
            f'<testsuite name="FigureStudioResultSpec" tests="1" '
            f'failures="{failures}" errors="0" skipped="0" time="1.25">'
            '<testcase classname="FigureStudioResultSpec" '
            'name="exportedLongTitleStaysWithinTheCanvas" time="1.25">'
            f"{failure}</testcase></testsuite></testsuites>",
            encoding="utf-8",
        )


if __name__ == "__main__":
    unittest.main()

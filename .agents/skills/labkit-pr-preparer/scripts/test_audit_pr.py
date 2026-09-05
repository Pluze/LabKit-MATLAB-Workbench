#!/usr/bin/env python3
"""Regression tests for the LabKit PR boundary inventory."""

import importlib.util
import pathlib
import shutil
import subprocess
import sys
import tempfile
import unittest


SCRIPT = pathlib.Path(__file__).with_name("audit_pr.py")
SPEC = importlib.util.spec_from_file_location("audit_pr", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class AuditPrTest(unittest.TestCase):
    def test_reports_new_component_transition_change_and_manual(self):
        report = self.run_boundary(None)
        self.assertIn("`labkit.sample`: `new -> 1.0.0`", report)
        self.assertIn("Change: `docs/changes/2026/CHG-20260905-sample.md`", report)
        self.assertIn("manual: `docs/develop/libraries/sample/README.md` (changed)", report)

    def test_reports_existing_component_transition(self):
        report = self.run_boundary("1.0.0")
        self.assertIn("`labkit.sample`: `1.0.0 -> 1.0.1`", report)
        self.assertIn("# Integration policy\n- Passed", report)

    def run_boundary(self, before):
        # Real Git refs and the production policy supply the independent input;
        # omitting a new component must fail the report's review contract.
        with tempfile.TemporaryDirectory() as raw:
            root = pathlib.Path(raw)

            def git(*args):
                return subprocess.run(
                    ["git", *args], cwd=root, check=True, text=True,
                    stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                ).stdout.strip()

            def write(path, contents):
                target = root / path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(contents, encoding="utf-8")

            policy_path = ".github/scripts/check_integration_policy.py"
            (root / policy_path).parent.mkdir(parents=True)
            shutil.copyfile(SCRIPT.resolve().parents[4] / policy_path, root / policy_path)
            git("init")
            git("config", "user.name", "Fixture")
            git("config", "user.email", "fixture@example.invalid")
            git("config", "commit.gpgsign", "false")
            version_path = "+labkit/+sample/version.m"
            if before:
                write(version_path, f'labkit.contract.versionInfo("sample", "{before}", ">=1 <2")')
            git("add", ".")
            git("commit", "-m", "chore: fixture baseline")
            base = git("rev-parse", "HEAD")
            after = "1.0.1" if before else "1.0.0"
            write(version_path, f'labkit.contract.versionInfo("sample", "{after}", ">=1 <2")')
            write("docs/develop/libraries/sample/README.md", "# Sample\n")
            write("docs/changes/2026/CHG-20260905-sample.md", (
                "id: CHG-20260905-sample\ndate: 2026-09-05\n"
                f"component: labkit.sample | {before or 'new'} -> {after}\n"
            ))
            git("add", ".")
            git("commit", "-m", "feat: sample component")
            result = subprocess.run(
                [sys.executable, str(SCRIPT.resolve()), "--base", base, "--head", "HEAD"],
                cwd=root, check=True, text=True, stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            return result.stdout

    def test_resolves_existing_facade_manual(self):
        with tempfile.TemporaryDirectory() as raw:
            root = pathlib.Path(raw)
            manual = (
                root / "docs" / "develop" / "libraries" / "mark10" / "README.md"
            )
            manual.parent.mkdir(parents=True)
            manual.write_text("# Mark-10\n", encoding="utf-8")

            self.assertEqual(
                MODULE.owning_manual(root, "labkit.mark10", "+labkit/+mark10"),
                "docs/develop/libraries/mark10/README.md",
            )

    def test_does_not_invent_missing_facade_manual(self):
        with tempfile.TemporaryDirectory() as raw:
            root = pathlib.Path(raw)

            self.assertIsNone(
                MODULE.owning_manual(root, "labkit.unknown", "+labkit/+unknown")
            )

    def test_resolves_app_manual_under_use_path(self):
        with tempfile.TemporaryDirectory() as raw:
            root = pathlib.Path(raw)
            manual = root / "docs" / "use" / "apps" / "force-gauges" / "mark10-monitor" / "README.md"
            manual.parent.mkdir(parents=True)
            manual.write_text("# Mark-10 Monitor\n", encoding="utf-8")

            self.assertEqual(
                MODULE.owning_manual(
                    root,
                    "labkit_Mark10Monitor_app",
                    "apps/force_gauges/mark10_monitor",
                ),
                "docs/use/apps/force-gauges/mark10-monitor/README.md",
            )


if __name__ == "__main__":
    unittest.main()

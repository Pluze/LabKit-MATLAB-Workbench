#!/usr/bin/env python3
"""Regression tests for the LabKit PR boundary inventory."""

import importlib.util
import pathlib
import tempfile
import unittest


SCRIPT = pathlib.Path(__file__).with_name("audit_pr.py")
SPEC = importlib.util.spec_from_file_location("audit_pr", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class AuditPrTest(unittest.TestCase):
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

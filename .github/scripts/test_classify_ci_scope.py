#!/usr/bin/env python3
"""Regression tests for documentation-aware CI scope classification."""

import importlib.util
import pathlib
import unittest


SCRIPT = pathlib.Path(__file__).with_name("classify_ci_scope.py")
SPEC = importlib.util.spec_from_file_location("classify_ci_scope", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class ClassifyCiScopeTest(unittest.TestCase):
    def test_normalization_preserves_dot_directories_on_every_platform(self):
        self.assertEqual(
            MODULE.normalize(".agents/dos-and-donts.md"),
            ".agents/dos-and-donts.md",
        )
        self.assertEqual(
            MODULE.classify([r".agents\dos-and-donts.md"]),
            {"full": False, "focused": False, "docs": False, "governance": True},
        )

    def test_agent_guidance_uses_only_governance_check(self):
        self.assertEqual(
            MODULE.classify(["AGENTS.md", ".agents/dos-and-donts.md"]),
            {"full": False, "focused": False, "docs": False, "governance": True},
        )

    def test_human_docs_request_docs_check_without_full_matrix(self):
        self.assertEqual(
            MODULE.classify(["docs/framework/README.md", "site/index.html"]),
            {"full": False, "focused": False, "docs": True, "governance": False},
        )

    def test_source_or_ci_configuration_requires_full_matrix(self):
        for path in [
            "+labkit/+app/Definition.m",
            "tests/specs/system/launcher/LauncherDispatchSpec.m",
            ".github/workflows/ci.yml",
        ]:
            with self.subTest(path=path):
                self.assertEqual(
                    MODULE.classify([path]),
                    {"full": True, "focused": False, "docs": False, "governance": False},
                )

    def test_mixed_docs_and_source_run_both_relevant_profiles(self):
        self.assertEqual(
            MODULE.classify(["docs/apps/README.md", "labkit_launcher.m"]),
            {"full": True, "focused": False, "docs": True, "governance": False},
        )

    def test_focused_hotfix_uses_bounded_product_evidence(self):
        self.assertEqual(
            MODULE.classify(
                [
                    "+labkit/+app/+internal/+launcher/dispatch.m",
                    "tests/specs/system/launcher/LauncherDispatchSpec.m",
                    "docs/apps/labkit-core/launcher/README.md",
                ],
                "hotfix/focused/local-docs-generation",
            ),
            {"full": False, "focused": True, "docs": True, "governance": False},
        )

    def test_ordinary_hotfix_keeps_full_matrix(self):
        scope = MODULE.classify(
            ["apps/image/crop/run.m"],
            "hotfix/crop-repair",
        )
        self.assertTrue(scope["full"])
        self.assertFalse(scope["focused"])

    def test_focused_name_cannot_downgrade_infrastructure_changes(self):
        for path in [
            ".github/workflows/ci.yml",
            ".github/scripts/classify_ci_scope.py",
            "buildfile.m",
            "tests/+labkittest/run.m",
            "tools/docs/renderLabKitDocs.m",
        ]:
            with self.subTest(path=path):
                scope = MODULE.classify(
                    [path],
                    "hotfix/focused/unsafe-change",
                )
                self.assertTrue(scope["full"])
                self.assertFalse(scope["focused"])


if __name__ == "__main__":
    unittest.main()

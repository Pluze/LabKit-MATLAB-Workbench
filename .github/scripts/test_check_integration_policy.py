#!/usr/bin/env python3
"""Regression tests for the permanent integration-branch policy."""

import importlib.util
import pathlib
import unittest


SCRIPT = pathlib.Path(__file__).with_name("check_integration_policy.py")
SPEC = importlib.util.spec_from_file_location("check_integration_policy", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class IntegrationPolicyTest(unittest.TestCase):
    def test_main_pull_request_requires_integration_or_hotfix_branch(self):
        self.assertEqual(
            MODULE.validate_branch(
                "pull_request", "main", "feature", "owner/repo", "owner/repo"
            ),
            [
                "Pull requests to main must come from develop or hotfix/*, "
                'not "feature".'
            ],
        )
        self.assertEqual(
            MODULE.validate_branch(
                "pull_request", "main", "develop", "fork/repo", "owner/repo"
            ),
            [
                "Pull requests to main must use the repository-owned develop branch."
            ],
        )
        self.assertEqual(
            MODULE.validate_branch(
                "pull_request", "main", "develop", "owner/repo", "owner/repo"
            ),
            [],
        )
        self.assertEqual(
            MODULE.validate_branch(
                "pull_request", "main", "hotfix/export", "owner/repo", "owner/repo"
            ),
            [],
        )

    def test_direct_semantic_steps_accept_only_one_public_transition(self):
        for before, after in [
            ("2.0.1", "2.0.2"),
            ("2.0.1", "2.1.0"),
            ("2.0.1", "3.0.0"),
        ]:
            with self.subTest(before=before, after=after):
                self.assertTrue(MODULE.is_direct_step(before, after))
        for before, after in [
            ("2.0.1", "2.0.3"),
            ("2.0.1", "2.1.1"),
            ("2.0.1", "4.0.0"),
            ("2.0.1", "2.0.0"),
        ]:
            with self.subTest(before=before, after=after):
                self.assertFalse(MODULE.is_direct_step(before, after))

    def test_app_source_requires_version_bump_and_exact_history(self):
        definition = (
            'labkit.app.Definition(Entrypoint="sample_app", '
            'AppVersion="1.2.3")'
        )
        paths = [
            "apps/examples/sample/+sample/definition.m",
            "apps/examples/sample/+sample/workbench.m",
        ]
        sources = {
            paths[0]: definition,
            paths[1]: "function workbench; end",
        }
        errors = MODULE.validate_versions(
            paths, sources.get, sources.get
        )
        self.assertEqual(
            errors,
            ["sample_app: source changed without a version bump from 1.2.3."],
        )

        updated = dict(sources)
        updated[paths[0]] = definition.replace("1.2.3", "1.2.4")
        history_path = "docs/history/records/2026/07/LK-example.md"
        paths.append(history_path)
        updated[history_path] = (
            "component: `sample_app` | `1.2.3 -> 1.2.4`"
        )
        self.assertEqual(
            MODULE.validate_versions(paths, sources.get, updated.get),
            [],
        )

    def test_facade_double_jump_is_rejected(self):
        path = "+labkit/+app/version.m"
        before = 'labkit.contract.versionInfo("app", "2.0.1", ">=2 <3")'
        after = before.replace("2.0.1", "2.0.3")
        errors = MODULE.validate_versions(
            [path], lambda _: before, lambda _: after
        )
        self.assertEqual(
            errors,
            [
                "labkit.app: 2.0.1 -> 2.0.3 is not one direct patch, "
                "minor, or major step.",
                "labkit.app: history must record `2.0.1 -> 2.0.3` "
                "in this change.",
            ],
        )

    def test_launcher_source_uses_launcher_metadata(self):
        metadata = MODULE.LAUNCHER_METADATA
        before = (
            'info = struct("name", "labkit_launcher", '
            '"version", "1.7.1");'
        )
        after = before.replace("1.7.1", "1.7.2")
        history = "docs/history/records/2026/07/LK-launcher.md"
        paths = ["labkit_launcher.m", metadata, history]
        base = {metadata: before}
        head = {
            metadata: after,
            history: "component: `labkit_launcher` | `1.7.1 -> 1.7.2`",
        }
        self.assertEqual(
            MODULE.validate_versions(paths, base.get, head.get),
            [],
        )


if __name__ == "__main__":
    unittest.main()

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
    def test_main_pull_request_requires_repository_develop_branch(self):
        self.assertEqual(
            MODULE.validate_branch(
                "pull_request", "main", "feature", "owner/repo", "owner/repo"
            ),
            ['Pull requests to main must come from develop, not "feature".'],
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
            ['Pull requests to main must come from develop, not "hotfix/export".'],
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

    def test_history_rejects_intermediate_and_split_component_records(self):
        version_path = "+labkit/+app/version.m"
        first_history = "docs/history/records/2026/08/LK-first.md"
        second_history = "docs/history/records/2026/08/LK-second.md"
        before = 'labkit.contract.versionInfo("app", "2.1.0", ">=2 <3")'
        after = before.replace("2.1.0", "2.2.0")
        base = {version_path: before}
        head = {
            version_path: after,
            first_history: "component: `labkit.app` | `2.1.0 -> 2.2.0`",
            second_history: "\n".join([
                "component: `labkit.app` | `2.2.0 -> 2.3.0`",
                "component: `sample_app` | `1.0.0 -> 1.0.1`",
            ]),
        }

        errors = MODULE.validate_versions(
            [version_path, first_history, second_history],
            base.get,
            head.get,
        )

        self.assertIn(
            "labkit.app: changed history is split across "
            f"{first_history}, {second_history}; consolidate the component's "
            "net PR history into one record.",
            errors,
        )
        self.assertIn(
            f"{second_history}: history records `labkit.app` as "
            "`2.2.0 -> 2.3.0`, but the net PR transition is "
            "`2.1.0 -> 2.2.0`.",
            errors,
        )
        self.assertIn(
            f"{second_history}: history records `sample_app` as "
            "`1.0.0 -> 1.0.1`, but the component has no net version change "
            "from the PR base.",
            errors,
        )

    def test_published_history_link_maintenance_keeps_version_inventory_stable(self):
        history_path = "docs/history/records/2026/07/LK-existing.md"
        component = "component: `sample_app` | `1.0.0 -> 1.1.0`"
        base = {
            history_path: component + "\n[Retired design](old-design.md)\n",
        }
        head = {
            history_path: component + "\nCurrent manual owns the behavior.\n",
        }

        self.assertEqual(
            MODULE.validate_versions([history_path], base.get, head.get),
            [],
        )

    def test_published_history_record_cannot_be_deleted(self):
        history_path = "docs/history/records/2026/07/LK-existing.md"
        base = {
            history_path: "component: `sample_app` | `1.0.0 -> 1.1.0`",
        }

        self.assertEqual(
            MODULE.validate_versions([history_path], base.get, {}.get),
            [f"{history_path}: published history records cannot be deleted."],
        )

    def test_one_consolidated_history_record_accepts_the_net_transition(self):
        version_path = "+labkit/+app/version.m"
        history_path = "docs/history/records/2026/08/LK-sdk.md"
        before = 'labkit.contract.versionInfo("app", "2.1.0", ">=2 <3")'
        after = before.replace("2.1.0", "2.2.0")
        base = {version_path: before}
        head = {
            version_path: after,
            history_path: "\n".join([
                "component: `labkit.app` | `2.1.0 -> 2.2.0`",
                "component: `sample_app` | `1.0.0 -> 1.0.1`",
            ]),
        }

        errors = MODULE.validate_versions(
            [version_path, history_path], base.get, head.get
        )

        self.assertEqual(
            errors,
            [
                f"{history_path}: history records `sample_app` as "
                "`1.0.0 -> 1.0.1`, but the component has no net version "
                "change from the PR base."
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

    def test_launcher_metadata_can_move_without_losing_the_transition(self):
        current = MODULE.LAUNCHER_METADATA
        legacy = MODULE.LEGACY_LAUNCHER_METADATA
        before = (
            'info = struct("name", "labkit_launcher", '
            '"version", "1.8.2");'
        )
        after = before.replace("1.8.2", "1.8.3")
        history = "docs/history/records/2026/08/LK-launcher.md"
        paths = [legacy, current, history]
        base = {legacy: before}
        head = {
            current: after,
            history: "component: `labkit_launcher` | `1.8.2 -> 1.8.3`",
        }

        self.assertEqual(
            MODULE.validate_versions(paths, base.get, head.get),
            [],
        )


if __name__ == "__main__":
    unittest.main()

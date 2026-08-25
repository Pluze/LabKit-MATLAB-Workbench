#!/usr/bin/env python3
"""Regression tests for task-branch integration and change metadata."""

import importlib.util
import pathlib
import unittest


SCRIPT = pathlib.Path(__file__).with_name("check_integration_policy.py")
SPEC = importlib.util.spec_from_file_location("check_integration_policy", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class IntegrationPolicyTest(unittest.TestCase):
    def test_main_pull_request_requires_same_repository_task_branch(self):
        self.assertEqual(
            MODULE.validate_branch(
                "pull_request", "main", "feature", "owner/repo", "owner/repo"
            ),
            [],
        )
        self.assertEqual(
            MODULE.validate_branch(
                "pull_request", "main", "fix", "fork/repo", "owner/repo"
            ),
            ["Pull requests to main must use a same-repository task branch."],
        )
        self.assertEqual(
            MODULE.validate_branch(
                "pull_request", "main", "main", "owner/repo", "owner/repo"
            ),
            ["Pull requests to main must come from a distinct task branch."],
        )

    def test_direct_semantic_steps_accept_one_public_transition(self):
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

    def test_app_source_requires_version_bump_and_matching_change(self):
        definition_path = "apps/examples/sample/+sample/definition.m"
        source_path = "apps/examples/sample/+sample/workbench.m"
        change_path = "docs/changes/2026/CHG-20260825-sample.md"
        definition = (
            'labkit.app.Definition(Entrypoint="sample_app", '
            'AppVersion="1.2.3")'
        )
        base = {definition_path: definition, source_path: "function workbench; end"}
        unchanged_version_head = dict(base)
        unchanged_version_head[source_path] = "function workbench; disp(1); end"

        errors = MODULE.validate_versions(
            [definition_path, source_path], base.get, unchanged_version_head.get
        )
        self.assertEqual(
            errors,
            ["sample_app: source changed without a version bump from 1.2.3."],
        )

        head = dict(unchanged_version_head)
        head[definition_path] = definition.replace("1.2.3", "1.2.4")
        head[change_path] = "component: sample_app | 1.2.3 -> 1.2.4"
        self.assertEqual(
            MODULE.validate_versions(
                [definition_path, source_path, change_path], base.get, head.get
            ),
            [],
        )

    def test_new_components_use_new_transition_in_one_change(self):
        facade = "+labkit/+sample/version.m"
        app = "apps/examples/sample/+sample/definition.m"
        change = "docs/changes/2026/CHG-20260825-new-components.md"
        head = {
            facade: 'labkit.contract.versionInfo("sample", "1.0.0", ">=1 <2")',
            app: (
                'labkit.app.Definition(Entrypoint="labkit_Sample_app", '
                'AppVersion="1.0.0")'
            ),
            change: "\n".join([
                "component: labkit.sample | new -> 1.0.0",
                "component: labkit_Sample_app | new -> 1.0.0",
            ]),
        }
        self.assertEqual(
            MODULE.validate_versions([facade, app, change], {}.get, head.get),
            [],
        )

    def test_double_jump_and_missing_change_are_both_reported(self):
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
                "labkit.app: one change record must contain `2.0.1 -> 2.0.3` "
                "in this change.",
            ],
        )

    def test_change_metadata_rejects_duplicate_current_transitions(self):
        version_path = "+labkit/+app/version.m"
        first = "docs/changes/2026/CHG-20260825-first.md"
        second = "docs/changes/2026/CHG-20260825-second.md"
        before = 'labkit.contract.versionInfo("app", "2.1.0", ">=2 <3")'
        after = before.replace("2.1.0", "2.2.0")
        base = {version_path: before}
        head = {
            version_path: after,
            first: "component: labkit.app | 2.1.0 -> 2.2.0",
            second: "\n".join([
                "component: labkit.app | 2.1.0 -> 2.2.0",
                "component: sample_app | 1.0.0 -> 1.0.1",
            ]),
        }
        errors = MODULE.validate_versions(
            [version_path, first, second], base.get, head.get
        )
        self.assertIn(
            "labkit.app: change records contain `2.1.0 -> 2.2.0` more "
            "than once; keep one net transition.", errors
        )
        self.assertFalse(any("sample_app" in error for error in errors))

    def test_historical_transition_backfill_needs_no_source_change(self):
        change = "docs/changes/2026/CHG-20260601-backfill.md"
        head = {change: "component: labkit.app | 1.0.0 -> 1.1.0"}
        self.assertEqual(
            MODULE.validate_versions([change], {}.get, head.get),
            [],
        )

    def test_historical_backfill_can_accompany_one_current_transition(self):
        version = "+labkit/+app/version.m"
        historical = "docs/changes/2026/CHG-20260601-backfill.md"
        current = "docs/changes/2026/CHG-20260825-current.md"
        before = 'labkit.contract.versionInfo("app", "2.1.0", ">=2 <3")'
        head = {
            version: before.replace("2.1.0", "2.1.1"),
            historical: "component: labkit.app | 1.0.0 -> 1.1.0",
            current: "component: labkit.app | 2.1.0 -> 2.1.1",
        }
        self.assertEqual(
            MODULE.validate_versions(
                [version, historical, current], {version: before}.get, head.get
            ),
            [],
        )

    def test_matlab_comment_only_change_needs_no_version_bump(self):
        version = "+labkit/+biosignal/version.m"
        source = "+labkit/+biosignal/private/helper.m"
        metadata = 'labkit.contract.versionInfo("biosignal", "3.0.0", ">=3 <4")'
        base = {version: metadata, source: "% Old owner\nvalue = 1;"}
        head = {version: metadata, source: "% Current owner\nvalue = 1;"}
        self.assertEqual(
            MODULE.validate_versions([source], base.get, head.get),
            [],
        )

    def test_old_history_paths_have_no_integration_compatibility_policy(self):
        path = "docs/history/records/2026/07/LK-existing.md"
        base = {path: "component: `sample_app` | `1.0.0 -> 1.1.0`"}
        self.assertEqual(
            MODULE.validate_versions([path], base.get, {}.get),
            [],
        )

    def test_accepted_change_record_cannot_be_deleted(self):
        path = "docs/changes/2026/CHG-20260825-existing.md"
        base = {path: "component: sample_app | 1.0.0 -> 1.1.0"}
        self.assertEqual(
            MODULE.validate_versions([path], base.get, {}.get),
            [f"{path}: accepted Change records cannot be deleted."],
        )

    def test_launcher_source_uses_launcher_metadata_and_change(self):
        metadata = MODULE.LAUNCHER_METADATA
        change = "docs/changes/2026/CHG-20260825-launcher.md"
        before = 'info = struct("name", "labkit_launcher", "version", "1.7.1");'
        after = before.replace("1.7.1", "1.7.2")
        base = {metadata: before}
        head = {
            metadata: after,
            change: "component: labkit_launcher | 1.7.1 -> 1.7.2",
        }
        self.assertEqual(
            MODULE.validate_versions(
                ["labkit_launcher.m", metadata, change], base.get, head.get
            ),
            [],
        )

    def test_launcher_metadata_can_move_with_one_change_transition(self):
        current = MODULE.LAUNCHER_METADATA
        legacy = MODULE.LEGACY_LAUNCHER_METADATA
        change = "docs/changes/2026/CHG-20260825-launcher-owner.md"
        before = 'info = struct("name", "labkit_launcher", "version", "1.8.2");'
        after = before.replace("1.8.2", "1.8.3")
        base = {legacy: before}
        head = {
            current: after,
            change: "component: labkit_launcher | 1.8.2 -> 1.8.3",
        }
        self.assertEqual(
            MODULE.validate_versions([legacy, current, change], base.get, head.get),
            [],
        )


if __name__ == "__main__":
    unittest.main()

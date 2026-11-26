"""Protect executable CI obligations without copying workflow prose or layout."""
from pathlib import Path
import os
import subprocess
import sys
import tempfile
import unittest

import yaml

ROOT = Path(__file__).resolve().parents[2]


def workflow(name):
    return yaml.safe_load((ROOT / ".github/workflows" / f"{name}.yml").read_text())


def action_steps(job, action):
    return [s for s in job["steps"] if s.get("uses", "").split("@")[0] == action]


class WorkflowContracts(unittest.TestCase):
    def test_ci_gate_requires_scheduled_jobs_to_succeed(self):
        # Execute the actual gate over controlled GitHub outcomes. Removing a
        # failure check must fail this test, independent of names/formatting.
        jobs = workflow("ci")["jobs"]
        gate = jobs["ci-gate"]
        self.assertEqual(gate["name"], "CI Gate")
        self.assertEqual(gate["if"], "always()")
        self.assertEqual(set(gate["needs"]), {"policy", "platform-matrix", "docs-check", "affected-apps"})
        for event, scope, required in (
            ("push", "", []),
            ("pull_request", "policy", []),
            ("pull_request", "docs", ["docs-check"]),
            ("pull_request", "apps", ["docs-check", "affected-apps"]),
            ("pull_request", "full", ["docs-check", "platform-matrix"]),
            ("pull_request", "", []),
        ):
            required = {"policy", *required}
            cases = [(None, "success")] + [(job, outcome) for job in required
                                           for outcome in ("failure", "skipped", "cancelled")]
            for failed_job, outcome in cases:
                with self.subTest(event=event, scope=scope, job=failed_job, outcome=outcome):
                    script = gate["steps"][0]["run"].replace("${{ github.event_name }}", event)
                    script = script.replace("${{ needs.policy.outputs.scope }}", scope)
                    for job in gate["needs"]:
                        value = "success" if job in required else "skipped"
                        if job == failed_job:
                            value = outcome
                        script = script.replace("${{ needs." + job + ".result }}", value)
                    result = subprocess.run(["bash", "-e", "-c", script], capture_output=True)
                    valid_scope = event == "push" or bool(scope)
                    self.assertEqual(result.returncode == 0, failed_job is None and valid_scope)

    def test_pr_scope_combines_all_changed_paths(self):
        from pr_scope import validation_scope

        source = "apps/electrochem/csc/+csc/definition.m"
        guide = "docs/use/apps/electrochemistry/csc/README.md"
        for paths, expected in (
            ([], "full"), (["AGENTS.md"], "policy"), ([guide, "AGENTS.md"], "docs"),
            (["README.md"], "docs"), (["docs/AGENTS.md"], "docs"),
            ([guide, source], "apps"), ([source, guide], "apps"),
            ([source, "+labkit/shared.m"], "full"),
            (["apps/electrochem/csc/deleted.m", source], "full"),
            ([".github/workflows/ci.yml"], "full"),
        ):
            with self.subTest(paths=paths):
                self.assertEqual(validation_scope(paths), expected)

    def test_scope_includes_earlier_pr_commits_and_excludes_base_only_changes(self):
        selector = ROOT / ".github/scripts/pr_scope.py"
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)

            def git(*args):
                subprocess.run(["git", *args], cwd=root, check=True, capture_output=True)

            def commit(path):
                file = root / path
                file.parent.mkdir(parents=True, exist_ok=True)
                file.write_text("fixture", encoding="utf-8")
                git("add", path)
                git("commit", "-m", "fixture")

            git("init", "-b", "main")
            git("config", "user.name", "Fixture")
            git("config", "user.email", "fixture@example.invalid")
            commit("README.md")
            git("switch", "-c", "topic")
            app = "apps/example/sample/+sample/definition.m"
            commit(app)
            commit("docs/guide.md")
            git("switch", "main")
            commit("+labkit/shared.m")
            git("merge", "--no-ff", "topic", "-m", "merge fixture")
            for options, expected in (([], "apps"), (["--app-paths"], app)):
                actual = subprocess.check_output([sys.executable, selector, *options], cwd=root, text=True)
                self.assertEqual(actual.strip(), expected)

    def test_platform_coverage_and_profile_dispatch_agree(self):
        jobs = workflow("ci")["jobs"]
        platform = jobs["platform-matrix"]
        self.assertEqual(platform["needs"], "policy")
        self.assertEqual(jobs["docs-check"]["needs"], "policy")
        matrix = platform["strategy"]["matrix"]["include"]
        self.assertTrue({("linux", "R2022b"), ("windows", "R2022b"),
                         ("linux", "latest"), ("windows", "latest"),
                         ("macos", "latest")} <= {(r["id"], r["release"]) for r in matrix})
        for row in matrix:
            profiles = {p for p in ("headless", "apps") if row[f"run_{p}"]}
            self.assertEqual(profiles, set(row["profiles"].split(",")))
            self.assertIn("apps", profiles)
            if row["release"] == "R2022b" or row["id"] == "linux":
                self.assertIn("headless", profiles)
        builds = action_steps(platform, "matlab-actions/run-build")
        self.assertTrue({"headless", "apps"} <= {s["with"]["tasks"] for s in builds})
        for step in builds:
            self.assertEqual(step["if"], "matrix.run_" + step["with"]["tasks"])
        self.assertEqual(action_steps(jobs["docs-check"], "matlab-actions/run-build")[0]["with"]["tasks"], "docsCheck")

    def test_matlab_runtimes_do_not_request_optional_toolboxes(self):
        for name in ("ci", "development-feedback", "docs-pages"):
            for job in workflow(name)["jobs"].values():
                for step in action_steps(job, "matlab-actions/setup-matlab"):
                    self.assertNotIn("products", step.get("with", {}))

    def test_mac_app_partitions_are_complete_and_dispatch_their_indices(self):
        platform = workflow("ci")["jobs"]["platform-matrix"]
        rows = [r for r in platform["strategy"]["matrix"]["include"] if r["id"] == "macos"]
        counts = {r.get("apps_shard_count", 1) for r in rows}
        self.assertEqual(len(counts), 1)
        count = counts.pop()
        self.assertGreater(count, 1)
        self.assertEqual(sorted(r["apps_shard_index"] for r in rows), list(range(1, count + 1)))
        self.assertEqual(len({r["shard_id"] for r in rows}), count)
        for row in rows:
            self.assertEqual(row["profiles"], "apps")
            self.assertFalse(row["run_headless"])
            self.assertTrue(row["run_apps"])
        apps = next(s for s in platform["steps"] if s.get("id") == "apps")
        self.assertEqual(apps["env"]["LABKIT_TEST_SHARD_INDEX"], "${{ matrix.apps_shard_index || 1 }}")
        self.assertEqual(apps["env"]["LABKIT_TEST_SHARD_COUNT"], "${{ matrix.apps_shard_count || 1 }}")
        self.assertEqual(apps["env"]["LABKIT_TEST_SHARD_TIMINGS"],
                         "${{ matrix.id == 'macos' && '.github/app-test-costs.json' || '' }}")

    def test_feedback_can_cancel_and_hands_off_before_matlab(self):
        spec = workflow("development-feedback")
        # PyYAML's YAML 1.1 resolver reads the GitHub key `on` as True.
        self.assertIn("main", spec[True]["push"]["branches-ignore"])
        self.assertTrue(spec["concurrency"]["cancel-in-progress"])
        for job in spec["jobs"].values():
            for step in job["steps"]:
                if step.get("uses", "").startswith("matlab-actions/"):
                    self.assertEqual(step["if"], "steps.handoff.outputs.should_run == 'true'")

    def test_feedback_skips_matlab_only_for_governance_text(self):
        steps = workflow("development-feedback")["jobs"]["focused-feedback"]["steps"]
        handoff = next(step["run"] for step in steps if step.get("id") == "handoff")
        guidance = ("AGENTS.md\n"
                    "+labkit/AGENTS.override.md\n"
                    ".agents/skills/labkit-pr-integrator/agents/openai.yaml\n"
                    ".agents/skills/behavior-evals.json\n")
        cases = [
            ("push", guidance, "false"),
            ("push", guidance + "+labkit/+biosignal/readRecording.m\n", "true"),
            ("push", ".agents/skills/example/scripts/test_example.py\n", "true"),
            ("push", ".agents/skills/example/scripts/fixture.json\n", "true"),
            ("push", "", "true"),
            ("workflow_dispatch", guidance, "true"),
        ]
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / ".github").mkdir()
            (root / ".github/scripts").symlink_to(ROOT / ".github/scripts")
            paths = root / "artifacts/development-feedback/changed-paths.txt"
            paths.parent.mkdir(parents=True)
            mock_gh = root / "gh"
            mock_gh.write_text("#!/bin/bash\necho 0\n", encoding="utf-8")
            mock_gh.chmod(0o755)
            output = root / "github-output"
            env = dict(os.environ, GITHUB_OUTPUT=str(output),
                       GITHUB_REPOSITORY="owner/repo", GITHUB_REPOSITORY_OWNER="owner",
                       HEAD_BRANCH="task",
                       PATH=os.pathsep.join([folder, str(Path(sys.executable).parent),
                                            os.environ["PATH"]]))
            for event, changed_paths, should_run in cases:
                with self.subTest(event=event, changed_paths=changed_paths):
                    paths.write_text(changed_paths, encoding="utf-8")
                    output.write_text("", encoding="utf-8")
                    subprocess.run(["bash", "-e", "-c", handoff], cwd=root,
                                   env=dict(env, EVENT_NAME=event), check=True,
                                   capture_output=True, text=True)
                    self.assertEqual(output.read_text(encoding="utf-8"),
                                     f"should_run={should_run}\n")

    def test_pages_deploys_generated_site(self):
        spec = workflow("docs-pages")
        self.assertEqual(spec[True]["push"]["branches"], ["main"])
        self.assertIn("site/", (ROOT / ".gitignore").read_text().splitlines())
        deploy = spec["jobs"]["deploy"]
        build = spec["jobs"][deploy["needs"]]
        self.assertIsNot(build, deploy)
        self.assertEqual(action_steps(build, "matlab-actions/run-build")[0]["with"]["tasks"], "docs")
        self.assertEqual(action_steps(build, "actions/upload-pages-artifact")[0]["with"]["path"], "site")
        self.assertFalse(action_steps(build, "actions/deploy-pages"))
        self.assertTrue(action_steps(deploy, "actions/deploy-pages"))
        for action in ("matlab-actions/setup-matlab", "matlab-actions/run-build",
                       "actions/upload-pages-artifact"):
            self.assertFalse(action_steps(deploy, action))


if __name__ == "__main__":
    unittest.main()

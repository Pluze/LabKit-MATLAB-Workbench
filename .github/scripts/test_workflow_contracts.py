"""Protect executable CI obligations without copying workflow prose or layout."""
from pathlib import Path
import subprocess
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
        self.assertEqual(set(gate["needs"]), {"policy", "platform-matrix", "docs-check"})
        for event in ("push", "pull_request"):
            required = ["policy"] if event == "push" else gate["needs"]
            cases = [(None, "success")] + [(job, outcome) for job in required
                                                       for outcome in ("failure", "skipped")]
            for failed_job, outcome in cases:
                with self.subTest(event=event, job=failed_job, outcome=outcome):
                    script = "\n".join(s.get("run", "") for s in gate["steps"])
                    script = script.replace("${{ github.event_name }}", event)
                    for job in gate["needs"]:
                        value = outcome if job == failed_job else "success"
                        script = script.replace("${{ needs." + job + ".result }}", value)
                    result = subprocess.run(["bash", "-e", "-c", script], capture_output=True)
                    self.assertEqual(result.returncode == 0, failed_job is None)

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

    def test_feedback_can_cancel_and_hands_off_before_matlab(self):
        spec = workflow("development-feedback")
        # PyYAML's YAML 1.1 resolver reads the GitHub key `on` as True.
        self.assertIn("main", spec[True]["push"]["branches-ignore"])
        self.assertTrue(spec["concurrency"]["cancel-in-progress"])
        for job in spec["jobs"].values():
            for step in job["steps"]:
                if step.get("uses", "").startswith("matlab-actions/"):
                    self.assertEqual(step["if"], "steps.handoff.outputs.should_run == 'true'")

    def test_pages_deploys_generated_site(self):
        spec = workflow("docs-pages")
        self.assertEqual(spec[True]["push"]["branches"], ["main"])
        self.assertIn("site/", (ROOT / ".gitignore").read_text().splitlines())
        steps = spec["jobs"]["deploy"]
        self.assertEqual(action_steps(steps, "matlab-actions/run-build")[0]["with"]["tasks"], "docs")
        self.assertEqual(action_steps(steps, "actions/upload-pages-artifact")[0]["with"]["path"], "site")
        self.assertTrue(action_steps(steps, "actions/deploy-pages"))


if __name__ == "__main__":
    unittest.main()

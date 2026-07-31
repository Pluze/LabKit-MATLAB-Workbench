#!/usr/bin/env python3
"""Regression tests for repository Skill validation."""

import importlib.util
import json
import pathlib
import tempfile
import unittest


SCRIPT = pathlib.Path(__file__).with_name("validate_agent_skills.py")
SPEC = importlib.util.spec_from_file_location("validate_agent_skills", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class ValidateAgentSkillsTest(unittest.TestCase):
    def make_skill(self, root, name="probe", dependencies=None, evals=False):
        folder = root / ".agents" / "skills" / name
        folder.mkdir(parents=True)
        (folder / "SKILL.md").write_text(
            "---\n"
            f"name: {name}\n"
            'description: "Use for a probe. Do not use outside the probe."\n'
            "---\n\n# Probe\n",
            encoding="utf-8",
        )
        (folder / "manifest.yaml").write_text(json.dumps({
            "schema_version": 1,
            "name": name,
            "scope": "labkit-repository",
            "dependencies": dependencies or [],
        }), encoding="utf-8")
        if evals:
            (folder / "evals.json").write_text(json.dumps({
                "schema_version": 1,
                "cases": [
                    {"prompt": "use it", "should_activate": True,
                     "rationale": "in scope"},
                    {"prompt": "skip it", "should_activate": False,
                     "rationale": "out of scope"},
                ],
            }), encoding="utf-8")
        return folder

    def test_accepts_complete_contract_with_balanced_evals(self):
        with tempfile.TemporaryDirectory() as raw:
            root = pathlib.Path(raw)
            self.make_skill(root, evals=True)
            self.assertEqual(MODULE.validate(root), 1)

    def test_rejects_name_drift_and_unknown_dependency(self):
        with tempfile.TemporaryDirectory() as raw:
            root = pathlib.Path(raw)
            folder = self.make_skill(root)
            text = (folder / "SKILL.md").read_text(encoding="utf-8")
            (folder / "SKILL.md").write_text(
                text.replace("name: probe", "name: other"), encoding="utf-8")
            with self.assertRaises(MODULE.SkillContractError):
                MODULE.validate(root)
        with tempfile.TemporaryDirectory() as raw:
            root = pathlib.Path(raw)
            self.make_skill(root, dependencies=["missing"])
            with self.assertRaises(MODULE.SkillContractError):
                MODULE.validate(root)

    def test_rejects_dependency_cycles_and_unportable_content(self):
        with tempfile.TemporaryDirectory() as raw:
            root = pathlib.Path(raw)
            self.make_skill(root, "first", ["second"])
            self.make_skill(root, "second", ["first"])
            with self.assertRaises(MODULE.SkillContractError):
                MODULE.validate(root)
        with tempfile.TemporaryDirectory() as raw:
            root = pathlib.Path(raw)
            folder = self.make_skill(root)
            slash = chr(92)
            (folder / "notes.md").write_text(
                "C:" + slash + "Users" + slash + "Example" + slash + "private",
                encoding="utf-8")
            with self.assertRaises(MODULE.SkillContractError):
                MODULE.validate(root)


if __name__ == "__main__":
    unittest.main()

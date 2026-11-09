#!/usr/bin/env python3
"""Regression tests for repository Skill validation."""

import importlib.util
import json
import pathlib
import py_compile
import tempfile
import unittest


SCRIPT = pathlib.Path(__file__).with_name("validate_agent_skills.py")
SPEC = importlib.util.spec_from_file_location("validate_agent_skills", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class ValidateAgentSkillsTest(unittest.TestCase):
    def make_skill(self, root, name="probe"):
        folder = root / ".agents" / "skills" / name
        folder.mkdir(parents=True)
        (folder / "SKILL.md").write_text(
            "---\n"
            f"name: {name}\n"
            'description: "Use for a focused probe. Ordinary product work remains with its owning workflow."\n'
            "---\n\n# Probe\n",
            encoding="utf-8",
        )
        agents = folder / "agents"
        agents.mkdir()
        (agents / "openai.yaml").write_text(
            "interface:\n"
            '  display_name: "Probe Skill"\n'
            '  short_description: "Exercise the repository Skill validator"\n'
            f'  default_prompt: "Use ${name} to exercise validation."\n',
            encoding="utf-8",
        )
        (folder / "evals.json").write_text(json.dumps({
            "schema_version": 1,
            "cases": [
                {"prompt": "use it", "should_activate": True,
                 "rationale": "in scope"},
                {"prompt": "skip it", "should_activate": False,
                 "rationale": "out of scope"},
            ],
        }), encoding="utf-8")
        self.write_activation_evals(root, [name])
        return folder

    def write_activation_evals(self, root, names):
        path = root / ".agents" / "skills" / "activation-evals.json"
        path.write_text(json.dumps({
            "schema_version": 1,
            "cases": [
                {"prompt": f"activate {name}", "activate": [name],
                 "do_not_activate": [other for other in names if other != name],
                 "rationale": "positive coverage"}
                for name in names
            ] + [
                {"prompt": f"exclude {name}",
                 "activate": [other for other in names if other != name],
                 "do_not_activate": [name],
                 "rationale": "negative coverage"}
                for name in names
            ],
        }), encoding="utf-8")

    def test_accepts_complete_contract_with_positive_and_negative_evals(self):
        with tempfile.TemporaryDirectory() as raw:
            root = pathlib.Path(raw)
            self.make_skill(root)
            self.assertEqual(MODULE.validate(root), 1)

    def test_rejects_incomplete_skill_directory(self):
        # A second broken Skill must not disappear from an otherwise valid catalog.
        with tempfile.TemporaryDirectory() as raw:
            root = pathlib.Path(raw)
            self.make_skill(root)
            (root / ".agents" / "skills" / "incomplete").mkdir()
            with self.assertRaisesRegex(MODULE.SkillContractError,
                                        "missing Skill entry point"):
                MODULE.validate(root)

    def test_validates_skill_routes_against_discovered_owners(self):
        with tempfile.TemporaryDirectory() as raw:
            root = pathlib.Path(raw)
            folder = self.make_skill(root, "labkit-probe")
            path = folder / "SKILL.md"
            original = path.read_text(encoding="utf-8")
            path.write_text(original + "Use `labkit-probe`.\n", encoding="utf-8")
            self.assertEqual(MODULE.validate(root), 1)
            path.write_text(original + "Use `labkit-missing`.\n", encoding="utf-8")
            with self.assertRaisesRegex(MODULE.SkillContractError,
                                        "unknown Skill route labkit-missing"):
                MODULE.validate(root)

    def test_checks_literal_documentation_routes_from_repository_root(self):
        with tempfile.TemporaryDirectory() as raw:
            root = pathlib.Path(raw)
            folder = self.make_skill(root)
            manual = root / "docs" / "develop" / "tool.md"
            manual.parent.mkdir(parents=True)
            manual.write_text("# Tool\n", encoding="utf-8")
            path = folder / "SKILL.md"
            original = path.read_text(encoding="utf-8")
            path.write_text(original + "Read `docs/develop/tool.md#usage`.\n",
                            encoding="utf-8")
            self.assertEqual(MODULE.validate(root), 1)
            manual.unlink()
            with self.assertRaisesRegex(MODULE.SkillContractError,
                                        "missing documentation route"):
                MODULE.validate(root)

    def test_rejects_name_drift(self):
        with tempfile.TemporaryDirectory() as raw:
            root = pathlib.Path(raw)
            folder = self.make_skill(root)
            text = (folder / "SKILL.md").read_text(encoding="utf-8")
            (folder / "SKILL.md").write_text(
                text.replace("name: probe", "name: other"), encoding="utf-8")
            with self.assertRaises(MODULE.SkillContractError):
                MODULE.validate(root)

    def test_accepts_scope_boundary_without_fixed_prohibition_phrase(self):
        with tempfile.TemporaryDirectory() as raw:
            root = pathlib.Path(raw)
            self.make_skill(root)
            self.assertEqual(MODULE.validate(root), 1)

    def test_rejects_unportable_content(self):
        with tempfile.TemporaryDirectory() as raw:
            root = pathlib.Path(raw)
            folder = self.make_skill(root)
            slash = chr(92)
            (folder / "notes.md").write_text(
                "C:" + slash + "Users" + slash + "Example" + slash + "private",
                encoding="utf-8")
            with self.assertRaises(MODULE.SkillContractError):
                MODULE.validate(root)

    def test_ignores_generated_python_cache_after_skill_script_execution(self):
        with tempfile.TemporaryDirectory() as raw:
            root = pathlib.Path(raw)
            folder = self.make_skill(root)
            script = folder / "probe.py"
            script.write_text("value = 1\n", encoding="utf-8")
            py_compile.compile(
                str(script), dfile="/".join(["", "Users", "Example", "probe.py"]),
                doraise=True,
            )
            self.assertEqual(MODULE.validate(root), 1)

    def test_rejects_missing_ui_metadata_and_one_sided_evals(self):
        with tempfile.TemporaryDirectory() as raw:
            root = pathlib.Path(raw)
            folder = self.make_skill(root)
            (folder / "agents" / "openai.yaml").unlink()
            with self.assertRaises(MODULE.SkillContractError):
                MODULE.validate(root)
        with tempfile.TemporaryDirectory() as raw:
            root = pathlib.Path(raw)
            folder = self.make_skill(root)
            path = folder / "evals.json"
            data = json.loads(path.read_text(encoding="utf-8"))
            data["cases"] = [data["cases"][0]]
            path.write_text(json.dumps(data), encoding="utf-8")
            with self.assertRaises(MODULE.SkillContractError):
                MODULE.validate(root)

    def test_rejects_unknown_activation_skill(self):
        with tempfile.TemporaryDirectory() as raw:
            root = pathlib.Path(raw)
            self.make_skill(root)
            path = root / ".agents" / "skills" / "activation-evals.json"
            data = json.loads(path.read_text(encoding="utf-8"))
            data["cases"][0]["activate"] = ["missing"]
            path.write_text(json.dumps(data), encoding="utf-8")
            with self.assertRaises(MODULE.SkillContractError):
                MODULE.validate(root)
        with tempfile.TemporaryDirectory() as raw:
            root = pathlib.Path(raw)
            self.make_skill(root)
            path = root / ".agents" / "skills" / "activation-evals.json"
            data = json.loads(path.read_text(encoding="utf-8"))
            data["cases"][0]["do_not_activate"] = ["probe"]
            path.write_text(json.dumps(data), encoding="utf-8")
            with self.assertRaises(MODULE.SkillContractError):
                MODULE.validate(root)


    def test_accepts_standard_yaml_and_optional_metadata(self):
        with tempfile.TemporaryDirectory() as raw:
            root = pathlib.Path(raw)
            folder = self.make_skill(root)
            (folder / "SKILL.md").write_text(
                "---\ndescription: >-\n  Run a focused probe\n  when requested.\n"
                "metadata:\n  short-description: A probe\nname: probe\n---\n# Probe\n")
            (folder / "agents" / "openai.yaml").write_text(
                "policy:\n  allow_implicit_invocation: false\n"
                "interface:\n  default_prompt: Use $probe to inspect a fixture.\n"
                "  short_description: Exercise the repository Skill validator\n"
                "  display_name: Probe\n"
                "dependencies:\n  tools:\n    - type: mcp\n      value: example\n")
            self.assertEqual(MODULE.validate(root), 1)

    def test_rejects_ambiguous_yaml_and_invalid_invocation_policy(self):
        with tempfile.TemporaryDirectory() as raw:
            root = pathlib.Path(raw)
            folder = self.make_skill(root)
            metadata = folder / "agents" / "openai.yaml"
            original = metadata.read_text()
            metadata.write_text(original + "policy:\n  allow_implicit_invocation: 'false'\n")
            with self.assertRaisesRegex(MODULE.SkillContractError, "invocation policy"):
                MODULE.validate(root)
            metadata.write_text(original + "interface: {}\n")
            with self.assertRaisesRegex(MODULE.SkillContractError, "duplicate YAML key"):
                MODULE.validate(root)

    def test_follows_references_and_checks_their_routes(self):
        with tempfile.TemporaryDirectory() as raw:
            root = pathlib.Path(raw)
            folder = self.make_skill(root)
            entry = folder / "SKILL.md"
            entry.write_text(entry.read_text() + "Read [mode](references/mode.md).\n")
            refs = folder / "references"
            refs.mkdir()
            mode = refs / "mode.md"
            mode.write_text("Read [details](details.md).\n")
            detail = refs / "details.md"
            detail.write_text("# Details\n")
            self.assertEqual(MODULE.validate(root), 1)
            detail.write_text("Use `labkit-missing`.\n")
            with self.assertRaisesRegex(MODULE.SkillContractError, "unknown Skill route"):
                MODULE.validate(root)
            detail.unlink()
            with self.assertRaisesRegex(MODULE.SkillContractError, "missing link"):
                MODULE.validate(root)

    def test_rejects_unreachable_reference_even_with_valid_content(self):
        with tempfile.TemporaryDirectory() as raw:
            root = pathlib.Path(raw)
            folder = self.make_skill(root)
            refs = folder / "references"
            refs.mkdir()
            (refs / "unreachable.md").write_text("# Unreachable\n")
            with self.assertRaisesRegex(MODULE.SkillContractError, "unreachable reference"):
                MODULE.validate(root)

    def test_instruction_budget_includes_ancestors_and_utf8_bytes(self):
        with tempfile.TemporaryDirectory() as raw:
            root = pathlib.Path(raw)
            (root / "AGENTS.md").write_text("a" * 16000)
            nested = root / "library" / "internal"
            nested.mkdir(parents=True)
            (nested.parent / "AGENTS.md").write_text("b" * 8000)
            (nested / "AGENTS.md").write_text(chr(0x754C) * 3000)
            chains = dict(MODULE.instruction_chains(root))
            self.assertEqual(chains[pathlib.Path("library/internal")], 33004)
            with self.assertRaisesRegex(MODULE.SkillContractError, "instruction chain"):
                MODULE.validate_instruction_chains(root)

    def test_instruction_budget_uses_override_and_ignores_artifact_worktrees(self):
        with tempfile.TemporaryDirectory() as raw:
            root = pathlib.Path(raw)
            (root / "AGENTS.md").write_text("x" * 40000)
            override = root / "AGENTS.override.md"
            override.write_text("Short override")
            generated = root / "artifacts" / "worktrees" / "task"
            generated.mkdir(parents=True)
            (generated / "AGENTS.md").write_text("x" * 40000)
            MODULE.validate_instruction_chains(root)
            override.write_text("")
            with self.assertRaises(MODULE.SkillContractError):
                MODULE.validate_instruction_chains(root)

    def test_behavior_scenarios_validate_identity_and_skill_references(self):
        with tempfile.TemporaryDirectory() as raw:
            path = pathlib.Path(raw) / "behavior-evals.json"
            case = {"id": "run", "prompt": "Run existing evidence",
                    "skills": ["probe"], "expected": ["Report result"],
                    "forbidden": ["Invent evidence"]}
            data = {"schema_version": 1, "cases": [case]}
            path.write_text(json.dumps(data))
            MODULE.validate_behavior_evals(path, {"probe"})
            data["cases"].append(case)
            path.write_text(json.dumps(data))
            with self.assertRaisesRegex(MODULE.SkillContractError, "duplicate behavior"):
                MODULE.validate_behavior_evals(path, {"probe"})
            data["cases"] = [dict(case, skills=["missing"])]
            path.write_text(json.dumps(data))
            with self.assertRaisesRegex(MODULE.SkillContractError, "unknown behavior Skill"):
                MODULE.validate_behavior_evals(path, {"probe"})


if __name__ == "__main__":
    unittest.main()

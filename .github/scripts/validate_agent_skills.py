#!/usr/bin/env python3
"""Validate repository-owned LabKit Skill contracts without dependencies."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


FRONTMATTER = re.compile(
    r"\A---\s*\nname:\s*([^\n]+)\n"
    r"description:\s*(?:\"([^\"]+)\"|([^\n]+))\n---\s*\n",
)
LINK = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
MANIFEST_KEYS = {"schema_version", "name", "scope", "dependencies"}
OPENAI = re.compile(
    r'\Ainterface:\n'
    r'  display_name: "([^"\n]+)"\n'
    r'  short_description: "([^"\n]+)"\n'
    r'  default_prompt: "([^"\n]+)"\s*\Z',
)
ACTIVATION_KEYS = {
    "prompt", "activate", "do_not_activate", "rationale",
}


class SkillContractError(ValueError):
    pass


def load_json(path: Path) -> object:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as cause:
        raise SkillContractError(
            f"{path}: invalid JSON-compatible YAML/JSON") from cause


def validate(root: Path) -> int:
    skills_root = root / ".agents" / "skills"
    skill_dirs = sorted(
        path for path in skills_root.iterdir()
        if path.is_dir() and (path / "SKILL.md").is_file()
    )
    if not skill_dirs:
        raise SkillContractError("No repository Skills were found.")
    manifests: dict[str, dict[str, object]] = {}
    for folder in skill_dirs:
        skill_path = folder / "SKILL.md"
        text = skill_path.read_text(encoding="utf-8")
        match = FRONTMATTER.match(text)
        if not match:
            raise SkillContractError(f"{skill_path}: invalid frontmatter")
        name = match.group(1).strip().strip("\"'")
        description = (match.group(2) or match.group(3)).strip()
        if name != folder.name:
            raise SkillContractError(f"{folder}: folder and Skill name differ")
        if "Do not use" not in description:
            raise SkillContractError(
                f"{folder}: description needs a negative boundary")
        manifest_path = folder / "manifest.yaml"
        manifest = load_json(manifest_path)
        if not isinstance(manifest, dict) or set(manifest) != MANIFEST_KEYS:
            raise SkillContractError(
                f"{manifest_path}: manifest keys differ from contract")
        dependencies = manifest["dependencies"]
        if (manifest["schema_version"] != 1 or manifest["name"] != name or
                manifest["scope"] != "labkit-repository" or
                not isinstance(dependencies, list) or
                not all(isinstance(item, str) for item in dependencies)):
            raise SkillContractError(f"{manifest_path}: invalid manifest value")
        manifests[name] = manifest
        validate_links(folder, text)
        validate_portability(folder)
        validate_openai_metadata(folder, name)
        validate_evals(folder / "evals.json")
    validate_dependencies(manifests)
    validate_dependency_routing(skills_root, manifests)
    validate_activation_evals(
        skills_root / "activation-evals.json", set(manifests))
    return len(skill_dirs)


def validate_links(folder: Path, text: str) -> None:
    for target in LINK.findall(text):
        target = target.split("#", 1)[0]
        if not target or "://" in target:
            continue
        if not (folder / target).resolve().exists():
            raise SkillContractError(
                f"{folder / 'SKILL.md'}: missing link {target}")


def validate_portability(folder: Path) -> None:
    for path in folder.rglob("*"):
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        if re.search(r"(?:[A-Za-z]:\\Users\\|/Users/|/home/[^/\s]+/)", text):
            raise SkillContractError(
                f"{path}: contains a user-specific absolute path")
        if any(token in text for token in (
                "runLabKitTests", "tests/runner/", "tests/cases/")):
            raise SkillContractError(
                f"{path}: contains a retired repository token")


def validate_evals(path: Path) -> None:
    data = load_json(path)
    if not isinstance(data, dict) or set(data) != {"schema_version", "cases"}:
        raise SkillContractError(f"{path}: invalid eval contract")
    cases = data["cases"]
    if data["schema_version"] != 1 or not isinstance(cases, list) or not cases:
        raise SkillContractError(f"{path}: eval cases are required")
    decisions = set()
    for case in cases:
        if (not isinstance(case, dict) or
                set(case) != {"prompt", "should_activate", "rationale"} or
                not isinstance(case["prompt"], str) or
                not case["prompt"].strip() or
                not isinstance(case["rationale"], str) or
                not case["rationale"].strip() or
                not isinstance(case["should_activate"], bool)):
            raise SkillContractError(f"{path}: malformed eval case")
        decisions.add(case["should_activate"])
    if decisions != {False, True}:
        raise SkillContractError(
            f"{path}: evals need positive and negative cases")


def validate_openai_metadata(folder: Path, name: str) -> None:
    path = folder / "agents" / "openai.yaml"
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as cause:
        raise SkillContractError(f"{path}: missing UI metadata") from cause
    match = OPENAI.match(text)
    if not match:
        raise SkillContractError(f"{path}: invalid UI metadata")
    display_name, short_description, default_prompt = match.groups()
    if not display_name.strip():
        raise SkillContractError(f"{path}: display name is required")
    if not 25 <= len(short_description) <= 64:
        raise SkillContractError(
            f"{path}: short description must be 25-64 characters")
    if f"${name}" not in default_prompt:
        raise SkillContractError(
            f"{path}: default prompt must mention ${name}")


def validate_dependency_routing(
        skills_root: Path,
        manifests: dict[str, dict[str, object]]) -> None:
    for name, manifest in manifests.items():
        text = (skills_root / name / "SKILL.md").read_text(encoding="utf-8")
        for dependency in manifest["dependencies"]:
            if f"`{dependency}`" not in text:
                raise SkillContractError(
                    f"{name}: dependency {dependency} lacks an explicit "
                    "SKILL.md route")


def validate_activation_evals(path: Path, skills: set[str]) -> None:
    data = load_json(path)
    if not isinstance(data, dict) or set(data) != {"schema_version", "cases"}:
        raise SkillContractError(f"{path}: invalid activation eval contract")
    cases = data["cases"]
    if data["schema_version"] != 1 or not isinstance(cases, list) or not cases:
        raise SkillContractError(f"{path}: activation eval cases are required")
    activated: set[str] = set()
    excluded: set[str] = set()
    for case in cases:
        if (not isinstance(case, dict) or set(case) != ACTIVATION_KEYS or
                not isinstance(case["prompt"], str) or
                not case["prompt"].strip() or
                not isinstance(case["rationale"], str) or
                not case["rationale"].strip()):
            raise SkillContractError(f"{path}: malformed activation case")
        positive = case["activate"]
        negative = case["do_not_activate"]
        if (not isinstance(positive, list) or
                not isinstance(negative, list) or
                not all(isinstance(item, str) for item in positive + negative)):
            raise SkillContractError(
                f"{path}: activation lists must contain only skill names")
        if not positive and not negative:
            raise SkillContractError(
                f"{path}: activation case must classify at least one skill")
        positive_set = set(positive)
        negative_set = set(negative)
        if len(positive_set) != len(positive) or len(negative_set) != len(negative):
            raise SkillContractError(f"{path}: duplicate skill in activation case")
        if positive_set & negative_set:
            raise SkillContractError(
                f"{path}: a skill cannot be activated and excluded together")
        unknown = (positive_set | negative_set) - skills
        if unknown:
            raise SkillContractError(
                f"{path}: unknown activation skill {sorted(unknown)[0]}")
        activated.update(positive_set)
        excluded.update(negative_set)
    if activated != skills or excluded != skills:
        missing_positive = sorted(skills - activated)
        missing_negative = sorted(skills - excluded)
        raise SkillContractError(
            f"{path}: incomplete activation coverage; "
            f"missing positive={missing_positive}, negative={missing_negative}")


def validate_dependencies(manifests: dict[str, dict[str, object]]) -> None:
    for name, manifest in manifests.items():
        for dependency in manifest["dependencies"]:
            if dependency not in manifests:
                raise SkillContractError(
                    f"{name}: unknown dependency {dependency}")
    visiting: set[str] = set()
    visited: set[str] = set()

    def visit(name: str) -> None:
        if name in visiting:
            raise SkillContractError(f"{name}: dependency cycle")
        if name in visited:
            return
        visiting.add(name)
        for dependency in manifests[name]["dependencies"]:
            visit(dependency)
        visiting.remove(name)
        visited.add(name)

    for name in manifests:
        visit(name)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--root", type=Path,
        default=Path(__file__).resolve().parents[2],
    )
    args = parser.parse_args()
    try:
        count = validate(args.root.resolve())
    except SkillContractError as cause:
        parser.error(str(cause))
    print(f"Validated {count} repository Skill contract(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

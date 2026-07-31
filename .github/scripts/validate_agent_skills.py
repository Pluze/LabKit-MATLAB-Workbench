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
        eval_path = folder / "evals.json"
        if eval_path.exists():
            validate_evals(eval_path)
    validate_dependencies(manifests)
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

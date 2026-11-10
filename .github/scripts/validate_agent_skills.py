#!/usr/bin/env python3
"""Validate repository-owned LabKit Skill contracts and instruction discovery budgets."""

from __future__ import annotations

import argparse
import json
import re
import os

import yaml
from pathlib import Path


FRONTMATTER = re.compile(r"\A---[ \t]*\r?\n(.*?)\r?\n---[ \t]*(?:\r?\n|$)", re.DOTALL)
LINK = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
PROJECT_DOC_MAX_BYTES = 32768  # Codex default; includes separators between files.


class UniqueKeyLoader(yaml.SafeLoader):
    """Reject ambiguous duplicate mapping keys instead of silently choosing one."""


def unique_mapping(loader, node, deep=False):
    pairs = loader.construct_pairs(node, deep=deep)
    result = {}
    for key, value in pairs:
        if key in result:
            raise SkillContractError(f"duplicate YAML key: {key}")
        result[key] = value
    return result


UniqueKeyLoader.add_constructor(
    yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, unique_mapping)


def yaml_mapping(text: str, path: Path) -> dict:
    try:
        data = yaml.load(text, Loader=UniqueKeyLoader)
    except (yaml.YAMLError, TypeError, SkillContractError) as cause:
        raise SkillContractError(f"{path}: invalid YAML: {cause}") from cause
    if not isinstance(data, dict):
        raise SkillContractError(f"{path}: expected a YAML mapping")
    return data


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
        if path.is_dir() and not path.name.startswith(".")
        and path.name != "__pycache__"
    )
    if not skill_dirs:
        raise SkillContractError("No repository Skills were found.")
    skills = {folder.name for folder in skill_dirs}
    for folder in skill_dirs:
        skill_path = folder / "SKILL.md"
        if not skill_path.is_file():
            raise SkillContractError(f"{skill_path}: missing Skill entry point")
        text = skill_path.read_text(encoding="utf-8")
        match = FRONTMATTER.match(text)
        if not match:
            raise SkillContractError(f"{skill_path}: invalid frontmatter")
        metadata = yaml_mapping(match.group(1), skill_path)
        name = metadata.get("name")
        description = metadata.get("description")
        if not isinstance(name, str) or not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", name) or len(name) > 64:
            raise SkillContractError(f"{skill_path}: invalid Skill name")
        if name != folder.name:
            raise SkillContractError(f"{folder}: folder and Skill name differ")
        if not isinstance(description, str) or not description.strip():
            raise SkillContractError(f"{folder}: description is required")
        for resource in [skill_path, *sorted((folder / "references").rglob("*.md"))]:
            resource_text = resource.read_text(encoding="utf-8")
            validate_skill_routes(resource, resource_text, skills)
            validate_documentation_routes(root, resource, resource_text)
            validate_links(resource.parent, resource_text)
        validate_reference_reachability(folder)
        validate_portability(folder)
        validate_openai_metadata(folder, name)
        validate_evals(folder / "evals.json")
    validate_activation_evals(skills_root / "activation-evals.json", skills)
    behavior_path = skills_root / "behavior-evals.json"
    if behavior_path.exists():
        validate_behavior_evals(behavior_path, skills)
    validate_instruction_chains(root)
    return len(skill_dirs)


def validate_skill_routes(path: Path, text: str, skills: set[str]) -> None:
    # Backticked repository Skill names are executable workflow routes.
    references = set(re.findall(r"`(labkit-[a-z0-9-]+)`", text))
    unknown = references - skills
    if unknown:
        raise SkillContractError(
            f"{path}: unknown Skill route {sorted(unknown)[0]}")


def validate_documentation_routes(root: Path, path: Path, text: str) -> None:
    # Literal current-manual routes are repo-relative even inside a Skill.
    references = re.findall(r"`(docs/[^`\s]+\.md(?:#[^`\s]*)?)`", text)
    for reference in references:
        target = reference.split("#", 1)[0]
        if any(character in target for character in "<>*"):
            continue  # Parameterized documentation families are not literal routes.
        if not (root / target).is_file():
            raise SkillContractError(f"{path}: missing documentation route {target}")


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
        # Python caches embed execution paths and are not authored Skill content.
        if "__pycache__" in path.relative_to(folder).parts or not path.is_file():
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        if re.search(r"(?:[A-Za-z]:\\Users\\|/Us" r"ers/|/ho" r"me/[^/\s]+/)", text):
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
    data = yaml_mapping(text, path)
    interface = data.get("interface", {})
    if not isinstance(interface, dict):
        raise SkillContractError(f"{path}: interface must be a mapping")
    display_name = interface.get("display_name")
    short_description = interface.get("short_description")
    default_prompt = interface.get("default_prompt")
    if not isinstance(display_name, str) or not display_name.strip():
        raise SkillContractError(f"{path}: display name is required")
    if not isinstance(short_description, str) or not 25 <= len(short_description) <= 64:
        raise SkillContractError(f"{path}: short description must be 25-64 characters")
    if not isinstance(default_prompt, str) or f"${name}" not in default_prompt:
        raise SkillContractError(f"{path}: default prompt must mention ${name}")
    policy = data.get("policy", {})
    if not isinstance(policy, dict) or ("allow_implicit_invocation" in policy and
            not isinstance(policy["allow_implicit_invocation"], bool)):
        raise SkillContractError(f"{path}: invalid invocation policy")


def validate_reference_reachability(folder: Path) -> None:
    references = {path.resolve() for path in (folder / "references").rglob("*.md")}
    pending = [(folder / "SKILL.md").resolve()]
    visited = set()
    while pending:
        source = pending.pop()
        if source in visited:
            continue
        visited.add(source)
        for link in LINK.findall(source.read_text(encoding="utf-8")):
            target = link.split("#", 1)[0]
            if not target or "://" in target:
                continue
            path = (source.parent / target).resolve()
            if path in references:
                pending.append(path)
    missing = references - visited
    if missing:
        raise SkillContractError(f"{folder}: unreachable reference {sorted(missing)[0].name}")


def instruction_chains(root: Path) -> list[tuple[Path, int]]:
    """Measure repository defaults; private worktrees and generated trees are separate scopes."""
    selected = {}
    for raw, directories, files in os.walk(root):
        directories[:] = [name for name in directories if name not in
                          {".git", "artifacts", "site", "private_apps", "__pycache__"}]
        directory = Path(raw)
        for name in ("AGENTS.override.md", "AGENTS.md"):
            if name in files:
                data = (directory / name).read_bytes()
                if data.strip():
                    selected[directory] = data
                    break
    result = []
    for directory in selected:
        ancestors = [p for p in [directory, *directory.parents] if p == root or root in p.parents]
        chain = [selected[p] for p in reversed(ancestors) if p in selected]
        result.append((directory.relative_to(root), len(b"\n\n".join(chain))))
    return sorted(result)


def validate_instruction_chains(root: Path) -> None:
    for directory, size in instruction_chains(root):
        if size > PROJECT_DOC_MAX_BYTES:
            raise SkillContractError(
                f"{directory}: instruction chain is {size} bytes; default limit is {PROJECT_DOC_MAX_BYTES}")


def validate_behavior_evals(path: Path, skills: set[str]) -> None:
    data = load_json(path)
    if not isinstance(data, dict) or set(data) != {"schema_version", "cases"} or data["schema_version"] != 1:
        raise SkillContractError(f"{path}: invalid behavior eval contract")
    cases = data["cases"]
    if not isinstance(cases, list) or not cases:
        raise SkillContractError(f"{path}: behavior cases required")
    seen = set()
    for case in cases:
        if not isinstance(case, dict) or set(case) != {"id", "prompt", "skills", "expected", "forbidden"}:
            raise SkillContractError(f"{path}: malformed behavior case")
        for key in ("id", "prompt"):
            if not isinstance(case[key], str) or not case[key].strip():
                raise SkillContractError(f"{path}: missing behavior {key}")
        if case["id"] in seen:
            raise SkillContractError(f"{path}: duplicate behavior id")
        seen.add(case["id"])
        for key in ("skills", "expected", "forbidden"):
            if not isinstance(case[key], list) or not case[key] or not all(isinstance(x, str) and x.strip() for x in case[key]):
                raise SkillContractError(f"{path}: invalid behavior {key}")
        if set(case["skills"]) - skills:
            raise SkillContractError(f"{path}: unknown behavior Skill")


def validate_activation_evals(path: Path, skills: set[str]) -> None:
    data = load_json(path)
    if not isinstance(data, dict) or set(data) != {"schema_version", "cases"}:
        raise SkillContractError(f"{path}: invalid activation eval contract")
    cases = data["cases"]
    if data["schema_version"] != 1 or not isinstance(cases, list) or not cases:
        raise SkillContractError(f"{path}: activation eval cases are required")
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
    chains = instruction_chains(args.root.resolve())
    if chains:
        directory, size = max(chains, key=lambda item: item[1])
        print(f"Largest instruction chain: {directory} = {size}/{PROJECT_DOC_MAX_BYTES} bytes.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

---
name: labkit-agent-governance
description: "Use when adding, changing, reviewing, or retiring LabKit AGENTS.md files, repository Skills, Skill metadata/evals/scripts, .agents/dos-and-donts.md, or .agents/migration_guide.md, and after repeated inspection, discarded approaches, rollback, repeated boundary cost, or user correction. Do not use for ordinary product or documentation edits with no agent-governance change."
---

# LabKit Agent Governance

Maintain agent guidance as a scoped executable system. Read the affected
`AGENTS.md`, complete affected Skills and resources, the Skill README,
validator and tests, and the current experience reservoir.

## Choose one owner

- durable invariant or routing rule: root or nearest scoped `AGENTS.md`;
- repeatable judgment or procedure: one Skill;
- repeated fragile operation: its owning script or repository automation;
- enforceable behavior: production or governance test;
- unresolved costly decision trap: `.agents/dos-and-donts.md`;
- active compatibility retirement: `.agents/migration_guide.md`;
- user or public API behavior: source help or the owning manual.

Search before adding guidance. Replace duplicate procedure with a route to its
owner, and retire guidance with the operation it described.

## Maintain and validate

Keep frontmatter limited to `name` and `description`, with positive triggers and
a real negative boundary. Keep bodies imperative and repository-specific;
move stable facts to scoped rules and retry-prone mechanics to scripts. Keep
`agents/openai.yaml` and balanced `evals.json` aligned, and add cross-Skill
activation cases only for genuine collisions. Exercise changed scripts.

Review the experience reservoir after a non-obvious boundary, failed approach,
rollback, focused validation, user correction, and before commit or handoff.
Record nothing when a stronger owner already prevents recurrence; otherwise
capture one principle-first lesson and remove it after promotion.

Run the repository Skill validator and unit tests, changed script paths,
`docsCheck` when documentation instructions or discovery change, and
`git diff --check`. Report authoritative homes, duplication removed, activation
coverage, the reservoir decision, exact evidence, and remaining judgment.

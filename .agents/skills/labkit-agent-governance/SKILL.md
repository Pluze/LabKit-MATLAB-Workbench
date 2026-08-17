---
name: labkit-agent-governance
description: "Use when adding, changing, reviewing, or retiring LabKit AGENTS.md files, repository Skills, Skill metadata/evals/scripts, .agents/dos-and-donts.md, or .agents/migration_guide.md, and at checkpoints with repeated inspection, discarded approaches, rollback, repeated boundary cost, or user correction. Do not use for ordinary product code or documentation edits that do not change agent governance."
---

# LabKit Agent Governance

Maintain agent guidance as an executable, scoped system rather than an
accumulating prompt. Read the root and affected scoped `AGENTS.md`, the complete
affected Skills and resources, `.agents/skills/README.md`, the governance
validator and tests, and the current experience reservoir before editing.

## Choose one owner

Place each fact in exactly one authoritative layer:

- durable repository invariant or routing rule: root or nearest scoped
  `AGENTS.md`;
- repeatable judgment or multi-step procedure: one Skill;
- fragile or repeated mechanical operation: the owning Skill's script or the
  repository automation owner named by `AGENTS.md`;
- enforceable behavior: production or governance test;
- unresolved costly agent decision trap: `.agents/dos-and-donts.md`;
- active compatibility retirement: `.agents/migration_guide.md`;
- user or public API behavior: source help or the owning manual.

Keep root rules short and route detail to the closest owner. Search distinctive
phrases before adding policy. Replace duplicate procedure with a link or
conditional Skill route; do not create a second checklist that can drift.

## Maintain Skills

For every affected Skill:

1. Keep only `name` and `description` in frontmatter. State both positive
   triggers and a meaningful negative boundary in the description.
2. Keep the body imperative, repository-specific, and focused on non-obvious
   workflow. Move stable scoped invariants to `AGENTS.md` and deterministic
   retry-prone work to scripts.
3. Keep `agents/openai.yaml`, `manifest.yaml`, and `evals.json` aligned. Treat
   manifest dependencies as audited routing metadata, not automatic loading;
   name every dependency in a conditional body route.
4. Add cross-Skill activation and exclusion cases when scopes overlap. Include
   near-boundary prompts, not only obvious examples.
5. Exercise every changed script path. Retire a Skill when its owning product
   operation or repository workflow no longer exists.

## Review the experience reservoir

Run this review after a non-obvious boundary decision, failed or discarded
approach, rollback, focused validation checkpoint, user correction, or before
commit and handoff.

1. Identify repeated inspection, command reconstruction, selector discovery,
   rollback, user correction, or time lost on the same boundary.
2. Record nothing when an existing rule, Skill, test, source contract, or
   manual already prevents recurrence.
3. Otherwise add or merge one principle-first lesson naming the observable
   signal and the different decision it should trigger. Do not record commands,
   filenames, versions, current failures, or chronological work history.
4. Promote a lesson only after repeated use proves its stable owner. Remove or
   compress the reservoir copy when policy, procedure, automation, or a test
   prevents the mistake.

## Validate and report

Run `.github/scripts/validate_agent_skills.py` and its unit tests after any
Skill contract change. Run the changed script path, `docsCheck` when scoped
documentation instructions or discovery change, and `git diff --check`.
Forward-test materially changed triggers with raw task prompts when practical;
do not give the evaluating agent the intended classification.

Report the authoritative homes chosen, duplicate guidance removed, activation
coverage, experience-reservoir decision, exact validation, and any behavior
that remains dependent on agent judgment.

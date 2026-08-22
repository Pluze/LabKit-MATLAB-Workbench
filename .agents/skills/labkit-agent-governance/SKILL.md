---
name: labkit-agent-governance
description: "Use to add, change, review, or retire LabKit AGENTS.md files, repository Skills, their metadata/evals/scripts, or an active migration ledger. Ordinary product and documentation contracts remain with their owning workflows."
---

# LabKit Agent Governance

Maintain agent guidance as a scoped executable system. Read the affected
`AGENTS.md`, complete affected Skills and resources, the Skill README,
validator, tests, and any active migration ledger.

## Choose one owner

- durable invariant or routing rule: root or nearest scoped `AGENTS.md`;
- repeatable judgment or procedure: one Skill;
- repeated fragile operation: its owning script or repository automation;
- enforceable behavior: production or governance test;
- active compatibility retirement: temporary `.agents/migration_guide.md`;
- user or public API behavior: source help or the owning manual.

Search before adding guidance. Replace duplicate procedure with a route to its
owner, and retire guidance with the operation it described.

## Control provenance and final surfaces

Classify proposed guidance as current invariant, repeatable procedure,
enforceable behavior, active migration, or session-only control data. A user
correction, reverted edit, rejected proposal, or failed attempt does not by
itself justify repository guidance. Require repeated current evidence and put
the resulting rule directly in its smallest authoritative owner.

Write guidance for a future agent that has no access to the working session.
Prefer positive ownership, accepted behavior, and routing language. Retain a
negative boundary when it materially distinguishes neighboring Skills or
protects safety, compatibility, scientific meaning, or repository integrity.
Inspect headings, examples, metadata, eval prompts, scripts, and handoff text
for process residue after the complete change is assembled.

## Maintain and validate

Keep frontmatter limited to `name` and `description`, with a positive trigger
and clear routing boundary. Keep bodies imperative and repository-specific;
move stable facts to scoped rules and retry-prone mechanics to scripts. Keep
`agents/openai.yaml` and balanced `evals.json` aligned, and add cross-Skill
activation cases only for genuine collisions. Exercise changed scripts.

Run the repository Skill validator and unit tests, changed script paths,
`docsCheck` when documentation instructions or discovery change, and
`git diff --check`. Report authoritative homes, duplication removed, activation
coverage, retired guidance, exact evidence, and remaining judgment.

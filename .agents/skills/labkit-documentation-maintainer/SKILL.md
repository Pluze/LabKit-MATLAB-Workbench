---
name: labkit-documentation-maintainer
description: "Use for LabKit documentation architecture, public API reference, component history, path-derived navigation, the MATLAB documentation renderer, generated site consistency, or documentation deployment. Source-only edits remain with their source owner."
---

# LabKit Documentation Maintainer

Read the root and docs rules, affected manual/help, renderer source, and focused
tests. Read the documentation tooling manual for renderer behavior, the history
format for records, and the release manual only when release output changes.

Apply `docs/AGENTS.md` as the reader, ownership, API-page, App-manual, example,
and generated-site contract. Documentation pressure does not justify a public
API; use `labkit-boundary-guard` when discoverability exposes an ownership
question.

## Workflow

1. Change authored sources or renderer code, never generated `site/` output.
2. After moving or retiring Markdown, inspect current manuals and published
   history for inbound links; run link maintenance and review every rewrite.
3. Run the smallest documentation regression, then deterministic `docsCheck`.
4. Render the ignored local site only when reading or visual inspection helps.
5. Inspect HTML when layout, navigation, responsiveness, links, lists, or
   search behavior changes.

Preserve published history identity and evidence while repairing stale links.
Create history only for a versioned component change or meaningful project
evolution, not mechanical generation or link-only maintenance.

Use repository GitHub templates for public artifacts. Keep PR evidence in the
PR record and express release notes as user-visible behavior, compatibility,
and required action; exact commands, hashes, CI details, and internal movement
belong in maintainer records.

Use `labkit-test-planner` only when validation extends beyond documentation
ownership. Report authored sources, link and renderer evidence, visual checks,
deployment state when applicable, and remaining manual review.

---
name: labkit-documentation-maintainer
description: "Use for LabKit documentation architecture, reader content, public API reference, changes, releases, navigation, search, the MATLAB renderer, or documentation deployment. Source-only edits remain with their source owner."
---

# LabKit Documentation Maintainer

Read the root and docs rules, affected manual or help, renderer source, and
focused tests. Read the documentation tooling manual for page contracts and
renderer behavior, and the release manual when release output changes. Read an
active `.agents/migration_guide.md` when the affected area is listed there.

Apply `docs/AGENTS.md` as the reader, fact-owner, page-type, API, scientific,
movement, style, and generated-site contract. Documentation pressure does not
justify a public API; use `labkit-boundary-guard` when discoverability exposes
an ownership question.

## Workflow

1. Name the reader, supported outcome, page type, fact authority, component,
   and version before adding or moving content.
2. Inspect current code, tests, source help, and authoritative external
   evidence for every behavioral or scientific claim. Treat old prose as a
   question source, not proof.
3. Place each fact once: current behavior in a manual or help, an accepted
   logical change in a change record, a published version summary in GitHub
   Releases, and delivery evidence in the pull request or CI record. Keep the
   accepted rationale with the change it explains.
4. Start from the owning page contract. Keep one stable topic per page and one
   complete manual per App by default. Split only when the child has an
   independent reader goal, enough content to stand alone, and a stable
   destination.
5. Design the reader path separately from source ownership and use one axis at
   the top level. Preserve Use for running LabKit and App manuals, Develop for
   the complete source lifecycle, Reference for exact lookup, and Changes for
   accepted rationale. Keep bounded local context and semantic cross-links;
   generate maps and Change browse views from the model.
6. Keep each prose paragraph on one physical source line. Never reflow prose
   to a column width or split it sentence by sentence; preserve semantic
   Markdown lines for list items, table rows, quotes, and literal blocks.
7. Change authored sources, metadata, renderer code, or source assets; never
   edit generated `site/` output.
8. When moving or deleting a page, update live internal links and launcher
   destinations, then remove the old source and route. Do not add redirects,
   aliases, archived site copies, or legacy navigation.
9. When a route or component relationship changes, verify the complete reader
   loop: Launcher or section landing to current guide, current guide to API or
   Change, and Change back to current documentation. Keep hand-authored related
   links only for relationships the renderer cannot derive.
10. Run the smallest page-contract and renderer regression, then deterministic
   `docsCheck`. Render the ignored local site when reading or visual inspection
   can expose presentation errors.
11. Inspect representative HTML at desktop and mobile widths when layout,
   navigation, tables, long symbols, search, or interaction changes.

Write one lightweight change record for an accepted logical change that a
user or developer may need to understand without Git. Keep it to why, what
changed, impact, and compatibility or limits; summarize net behavior rather
than commit order. Do not create a local release page; link the authoritative
GitHub Release when a reader needs a published version summary. Put the problem, constraints, accepted choice, and
relevant rejected alternatives in the Change record's Why section. When a
later Change replaces an earlier choice, link it with `supersedes`. Remove
obsolete current guidance instead of keeping route-compatible archives.

Use repository GitHub templates for public artifacts. Express release notes as
user-visible behavior, compatibility, and required action. Keep exact commands,
hashes, test inventories, CI details, and internal movement in the PR or
workflow record.

Use `labkit-agent-governance` when documentation rules, this Skill, its evals,
or the migration ledger change. Use `labkit-test-planner` only when validation
extends beyond documentation ownership. Report authoritative fact homes,
authored sources, removed content and routes, contract and renderer evidence,
visual checks, deployment state when applicable, and remaining manual review.

---
name: labkit-documentation-maintainer
description: "Use for LabKit documentation architecture, reader content, public API reference, changes, releases, navigation, search, the MATLAB renderer, or documentation deployment. Source-only edits remain with their source owner."
---

# LabKit Documentation Maintainer

Read the root and docs rules, the affected current manual and MATLAB help,
relevant source and tests, and the documentation tooling manual. Read the
release manual only when published release output changes and an active
`.agents/migration_guide.md` only when it owns the affected migration.

Apply `docs/AGENTS.md` as the reader, fact-owner, page, movement, style, and
generated-site contract. Documentation pressure does not justify a public API;
use `labkit-boundary-guard` when discoverability exposes a package boundary.

## Classify source impact

Compare the accepted base and result, then classify every changed user workflow,
App, public symbol, schema, error, default, output, and compatibility contract:

- **Create** when the result adds a supported reader goal, App, public API, or
  schema. Add the current manual or help owner and verify generated discovery.
- **Update** when an existing supported fact changes. Edit its current owner;
  do not create a parallel page for an implementation move.
- **Retire** when a supported surface disappears. Remove obsolete current prose,
  routes, links, and catalog ownership; link a current replacement when one
  exists and keep only durable rationale in a Change.
- **No current-doc change** only after verifying that behavior, public contracts,
  discovery, compatibility, and every documented fact remain unchanged. Record
  the conclusion in the PR, not in a manual.

Inspect an App definition, version, current manual, public App APIs, affected UI
labels and tests together. Inspect a facade's complete public help, consumers,
module guide, version, and generated catalog together. Renames and moves use the
accepted public result: update live destinations and delete the former route;
never add redirects, aliases, archives, or retired navigation.

## Maintain the reader system

1. Name the primary reader, outcome, page type, fact authority, component, and
   compatibility before writing.
2. Establish behavioral and scientific claims from current source, tests, and
   authoritative external evidence. Old prose is a question source, not proof.
3. Place each fact once: supported behavior in current manuals or help, accepted
   rationale in one Change, a published version summary in GitHub Releases, and
   delivery evidence in the PR or workflow record.
4. Keep one complete App manual by default. Split only for an independent reader
   goal with enough substance and a stable destination.
5. Preserve the Use, Develop, Reference, and Changes intent routes. Verify the
   full reader loop from landing or Launcher to current guidance, exact API or
   Change, and back to affected current guidance.
6. Edit authored Markdown, MATLAB help, metadata, renderer components, or source
   assets only. Never edit generated `site/` output.
7. Keep prose paragraphs on one physical source line and preserve Markdown
   structure for headings, list items, table rows, quotes, and literal blocks.

Create one Change only when an accepted logical change has rationale, impact,
compatibility, or limits a reader should understand without Git. Use its four
canonical sections and `supersedes` only when the new choice replaces an older
choice. Do not create local release summaries or copy validation inventories,
hashes, commands, CI mechanics, or implementation chronology into reader docs.

## Audit published release coverage

Treat release notes as a complete tag-to-tag reader summary. Identify the
immediately preceding published GitHub Release rather than assuming the nearest
tag or latest merged PR is the baseline, verify both tag targets and ancestry,
and inspect the complete `<previous-published-tag>..<release-tag>` log and
changed paths. Inventory every structured Change record and every App, facade,
or launcher version transition in that range, then classify each user-visible
addition, change, retirement, compatibility condition, and user action under
Highlights, Fixes, or Upgrade Note. Record non-user-visible classifications in
the release work record, not the public notes.

Draft from that inventory and reconcile each item against the tagged source,
current manuals, and Change records; do not reconstruct release scope from one
PR body, merge subject, or memory. Normalize GitHub Markdown before writing.
After creating or editing the Release, read back its title, tag, body, state,
and assets and repeat the inventory-to-body comparison. A valid tag and asset
do not compensate for an incomplete user-facing summary.

## Verify

Run the smallest source/help/page contract first, then `buildtool docsCheck`.
The renderer must reject missing outputs, duplicate IDs, malformed landmarks or
tables, broken links or anchors, unreachable pages, incomplete search/map/API
coverage, and nondeterministic output. Render the ignored site and inspect
representative desktop and mobile pages when layout, navigation, tables, long
symbols, search, or interaction changes.

For a release-only correction that changes no authored repository
documentation, validate the normalized GitHub Markdown and the read-back
release coverage audit; `docsCheck` is not required solely for the external
Release body. Run it when repository documentation instructions, authored
pages, discovery, or rendering also change.

Use `labkit-agent-governance` when rules, this Skill, its metadata/evals, or the
migration ledger changes. Use `labkit-test-planner` only when evidence extends
beyond documentation ownership. Report created, updated, and retired owners and
routes; verified no-doc conclusions; renderer and visual evidence; deployment
state; and remaining manual review.

---
name: labkit-documentation-maintainer
description: "Use for LabKit documentation architecture, public API reference, component history, path-derived navigation, the MATLAB documentation renderer, generated site consistency, or documentation deployment changes. Do not use for source-only edits with no authored documentation contract."
---

# LabKit Documentation Maintainer

## Sources of truth

Read `AGENTS.md`, `docs/AGENTS.md`, the affected manual/help block, renderer
source under `tools/docs`, and focused documentation tests. Read
`docs/development/tools/documentation.md` for renderer behavior and
`docs/development/maintain-and-release/release.md` when release history is
involved.

## Page design

Apply the reader, ownership, API-page, App-manual, example, and generated-site
contracts in `docs/AGENTS.md` rather than restating them here.

- Documentation or discoverability pressure does not by itself justify a new
  public API. Prefer documenting a natural extension to an existing focused
  contract or internal framework behavior; route a proposed new name through
  the boundary guard when multiple consumers or anti-bucket clarity justify
  it.
- Organize the App SDK progressively: `Definition`, `layout`, and `Snapshot`
  first; typed events and `CallbackContext` for normal dynamic Apps; then
  project, result, interaction, and payload details in advanced paths.
## History

Apply `docs/AGENTS.md` and the authored
[history record format](../../../docs/history/record-format.md). Sequence
defines linear order, including same-day changes; filenames and Git timestamps
do not. A change to documentation retirement policy itself needs a
project-evolution record; link-only maintenance does not create a component
transition.

## GitHub templates

When creating or updating public GitHub artifacts, use the matching template
under `.github/` rather than drafting a parallel format. Preserve the template
headings and fill them with repository-relative targets, current documentation
paths, exact validation evidence, and any remaining manual checks. Issue
requests state user outcomes and acceptance criteria; pull requests state
scope, behavior, documentation/boundary decisions, delivery state, and data
hygiene. Never place sensitive lab data or local absolute paths in an Issue or
PR.

## Release notes

Treat a GitHub Release as a user interface for deciding whether and how to
upgrade. Preserve historical facts, breaking changes, safety warnings, and
required migration actions, but express them through user-visible workflows
and supported contracts. Do not turn the note into a delivery log: omit commit
and run identifiers, shell commands, test inventories, CI routing, internal
package moves, hashes, byte counts, and asset-verification procedure. Summarize
validation only at the level useful to a user, such as supported MATLAB and OS
coverage or completed interactive checks. Keep exact evidence in the PR,
workflow record, structured component history, and release verification.

## Workflow

1. Change authored sources or renderer code. After moving or retiring
   Markdown, inspect current manuals and published history for inbound links,
   remove obsolete links when no replacement page exists, then run
   `maintainLabKitDocLinks(repoRoot, "Update", true)` and review every rewrite.
2. Run `maintainLabKitDocLinks(repoRoot)` and the smallest documentation
   contract/regression test during iteration.
3. Run `docsCheck` to render two independent temporary trees and byte-compare
   their output. The check must not depend on a tracked or preexisting site.
4. When local reading or visual inspection is useful, run
   `addpath("tools/docs"); renderLabKitDocs()` from the repository root to
   synchronize the default `docs/` sources into ignored `site/`. Custom roots
   use positional arguments `renderLabKitDocs(sourceRoot, outputRoot)`; the
   renderer does not accept Name-Value options. It must rebuild from a missing
   output root and remove pages no longer present in the source model.
5. Inspect changed HTML visually when layout, navigation, responsive behavior,
   ordered lists, links, or client-side search changed.
6. Review authored source and generator diffs. Never stage local `site/`
   output; GitHub Pages generates its deployment artifact from the exact main
   source.

Use `labkit-boundary-guard` when public API ownership changes and
`labkit-test-planner` for broader validation. Report authored sources,
renderer/docs tests, optional local visual inspection, broken-link/search
status, and deployment status when applicable.

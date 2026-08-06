---
name: labkit-documentation-maintainer
description: "Use for LabKit documentation architecture, public API reference, component history, path-derived navigation, the MATLAB documentation renderer, generated site consistency, or documentation deployment changes. Do not use for source-only edits with no authored documentation contract."
---

# LabKit Documentation Maintainer

## Sources of truth

Read `AGENTS.md`, the affected manual/help block, renderer source under
`tools/docs`, and focused documentation tests. Read
`docs/development/tools/documentation.md` for renderer behavior and
`docs/development/maintain-and-release/release.md` when release history is
involved.

Authored sources are path-organized Markdown and public MATLAB help. Narrative
pages are discovered from `docs/`; public Apps come from
`labkit_launcher("list")` plus path-conventional manuals; App API pages come
from complete public help contracts. `site/` is ignored local output and the
GitHub Pages workflow rebuilds the deployed artifact from `main`. Never track
or hand-edit HTML, CSS, JavaScript, or search indexes.

## Page design

- Organize by reader task and component ownership: getting started, apps,
  framework, libraries, development, reference, and history.
- One API page resolves to one concrete public MATLAB function. Explain syntax,
  inputs, outputs, options, defaults, legal values, units, assumptions, errors,
  examples, and related APIs; link symbols to their reference pages.
- Documentation or discoverability pressure does not by itself justify a new
  public API. Prefer documenting a natural extension to an existing focused
  contract or internal framework behavior; route a proposed new name through
  the boundary guard when multiple consumers or anti-bucket clarity justify
  it.
- App manuals explain workflow, interaction, state/projects, outputs, GUI-free
  APIs, limitations, troubleshooting, and component history.
- Private implementation helpers do not need public reference pages.
- Prefer contextual cross-links and map/index pages over duplicated prose.
- Organize the App SDK progressively: `Definition`, `layout`, and `Snapshot`
  first; typed events and `CallbackContext` for normal dynamic Apps; then
  project, result, interaction, and payload details in advanced paths.
- Canonical minimal, standard, and advanced examples must use exact production
  symbols and be executable tests; do not preserve approximate RFC syntax.

## History

The authored [history record format](../../../docs/history/record-format.md)
is the single authority for metadata, legal values, and required narrative
sections. Sequence defines linear order, including same-day changes; filenames
and Git timestamps do not.

Update history only with a versioned component change or a meaningful project
evolution record. Do not create records for mechanical regeneration, typo-only
copy edits, or generated-site churn.

When a current page is retired or moved, repair or remove stale links in
published history instead of retaining an obsolete compatibility page. Keep
the published record's metadata and decision content unchanged. Link-only
maintenance does not create a new component transition, but the documentation
retirement policy itself needs a project-evolution record when it changes.

## GitHub templates

When creating or updating public GitHub artifacts, use the matching template
under `.github/` rather than drafting a parallel format. Preserve the template
headings and fill them with repository-relative targets, current documentation
paths, exact validation evidence, and any remaining manual checks. Issue
requests state user outcomes and acceptance criteria; pull requests state
scope, behavior, documentation/boundary decisions, delivery state, and data
hygiene. Never place sensitive lab data or local absolute paths in an Issue or
PR.

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

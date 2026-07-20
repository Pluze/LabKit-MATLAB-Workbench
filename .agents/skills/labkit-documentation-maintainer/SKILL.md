---
name: labkit-documentation-maintainer
description: "Use for LabKit documentation architecture, public API reference, component history, path-derived navigation, the MATLAB documentation renderer, generated site consistency, or documentation deployment changes."
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
from complete public help contracts. `site/` is tracked generated output.
Never hand-edit HTML, CSS, JavaScript, or search indexes.

Migration evidence summaries are generated views of one machine-readable
inventory. When an audit schema or classifier changes, regenerate the
baseline, capability matrix, behavior classification, and worksheet together,
then run their aggregate-consistency test; do not reconcile counts by hand.

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
- Organize the UI SDK progressively: minimal Application/Layout first,
  Command/Presentation/RuntimeContext for normal dynamic Apps, and project,
  result, resource, interaction, and payload details only in advanced paths.
- Canonical minimal, standard, and advanced examples must use exact production
  symbols and be executable tests; do not preserve approximate RFC syntax.

## History

Component history records use schema 2 metadata, a globally unique stable ID,
date, monotonic unique sequence, type, compatibility, affected components, and
scopes. Content explains context, decision, changes, user/data impact,
compatibility, validation, evidence, and known follow-up. Sequence defines
linear order, including same-day changes; filenames and Git timestamps do not.

Update history only with a versioned component change or a meaningful project
evolution record. Do not create records for mechanical regeneration, typo-only
copy edits, or generated-site churn.

## Workflow

1. Change authored sources or renderer code. After moving Markdown, run
   `maintainLabKitDocLinks(repoRoot, "Update", true)` and review every rewrite.
2. Run `maintainLabKitDocLinks(repoRoot)` and the smallest documentation
   contract/regression test during iteration.
3. From the repository root, run `addpath("tools/docs"); renderLabKitDocs()`
   to synchronize the default `docs/` sources into `site/`. Custom roots use
   positional arguments `renderLabKitDocs(sourceRoot, outputRoot)`; the
   renderer does not accept Name-Value options. It must rebuild from a missing
   output root and remove pages no longer present in the source model.
4. Run `docsCheck` to rebuild in a temporary tree and byte-compare output.
5. Inspect changed HTML visually when layout, navigation, responsive behavior,
   ordered lists, links, or client-side search changed.
6. Review source and generated diffs together; generated changes must be fully
   explained by authored inputs or renderer behavior.

Use `labkit-boundary-guard` when public API ownership changes and
`labkit-test-planner` for broader validation. Report authored sources,
generated outputs, renderer/docs tests, visual inspection, broken-link/search
status, and deployment status when applicable.

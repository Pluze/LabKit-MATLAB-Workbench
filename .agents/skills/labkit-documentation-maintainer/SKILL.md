---
name: labkit-documentation-maintainer
description: "Use for LabKit documentation architecture, public API reference, component history, catalogs/navigation, the MATLAB documentation renderer, generated site consistency, or documentation deployment changes."
---

# LabKit Documentation Maintainer

## Sources of truth

Read `AGENTS.md`, the affected manual/help block, `docs/site.json`, relevant
catalog JSON, renderer source under `tools/docs`, and focused documentation
tests. Read `docs/development/tools/documentation.md` for renderer behavior and
`docs/development/release.md` when release history is involved.

Authored sources are Markdown, structured JSON catalogs/navigation, and public
MATLAB help. `site/` is tracked generated output. Never hand-edit HTML, CSS,
JavaScript, or search indexes.

## Page design

- Organize by reader task and component ownership: getting started, apps,
  framework, libraries, development, reference, and history.
- One API page resolves to one concrete public MATLAB function. Explain syntax,
  inputs, outputs, options, defaults, legal values, units, assumptions, errors,
  examples, and related APIs; link symbols to their reference pages.
- App manuals explain workflow, interaction, state/projects, outputs, GUI-free
  APIs, limitations, troubleshooting, and component history.
- Private implementation helpers do not need public reference pages.
- Prefer contextual cross-links and map/index pages over duplicated prose.

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

1. Change authored sources or renderer code.
2. Run the smallest documentation contract/regression test during iteration.
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

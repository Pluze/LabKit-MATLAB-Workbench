---
name: labkit-app-builder
description: "Use to create or substantially refactor a LabKit MATLAB app from scripts, functions, protocols, existing GUIs, workflow notes, or prose requirements. Do not use for a narrow bug fix that preserves the existing App shape."
---

# LabKit App Builder

## Read and intake

Read `AGENTS.md`, `apps/AGENTS.md`, the source/protocol, the closest genuinely
similar app, and affected app docs/tests. Read `+labkit/AGENTS.md` only if a
facade may change and `tests/AGENTS.md` when creating fixtures or test policy.

Before coding, map:

- accepted inputs and file variability;
- user actions and order;
- parameters, defaults, units, formulas, and thresholds;
- plots, annotations, results, exports, and failed-row behavior;
- state that must persist versus transient view/cache state;
- sensitive examples that must become synthetic fixtures.

Treat legacy code as evidence, not the target architecture. Preserve science,
units, result/export contracts, and relied-upon status meanings unless the user
requests change. Discard workspace plumbing, hard-coded paths, debug staging,
globals, `evalin/assignin`, repeated dialogs, pauses, and exploratory branches.
Do not invent missing scientific definitions.

If the user asks to correct behavior in an existing App, keep the current App
shape and public boundary unless the defect itself proves a boundary change is
necessary. Do not relabel a bug fix or UX correction as a refactor, and do not
use the full architecture build sequence to justify unrelated cleanup.

Treat a new framework public API as the last solution. Keep App-specific
meaning local, prefer a natural extension of an existing focused SDK contract,
and prefer private framework mechanics when no App-authored call is needed.
Add a new public name only after repeated multi-App need is demonstrated or
when extending the nearest API would make it an ambiguous bucket.

## Design

Write a short working brief with app/family, inputs, project/session shape,
controls, calculations, preserved compatibility, intentionally discarded flow,
previews, results, exports, tests, and manual GUI checks.

Use the required shape and prohibited forms in `apps/AGENTS.md` as the single
architecture authority. Start with only the entrypoint, `definition.m`, and
`+workbench/buildLayout.m`; add project, session, presentation, synthetic-input,
Start, and capability packages only when the working brief names the product
state or lifecycle each one owns.

Make `buildLayout.m` read in user-workflow order. Partition a complex workflow
by product capability and keep its layout, direct actions, presentation
fragment, and renderer together when they change together. Use ordinary SDK
bindings and defaults before adding callback or presenter glue. At a callback
boundary, name the complete application state, typed event value, and callback
context, then pass narrow domain values deeper.

When synthetic input is required, build an anonymous validated project through
the ordinary Developer Tools path, choose finite representative native-control
values, validate it headlessly, and launch it through the native adapter. Clean
construction alone is not operational evidence.

## Build order

1. Define identity, version, requirements, layout, and only the optional
   project/session capabilities the App needs.
2. Declare the semantic layout with direct business callbacks.
3. Implement GUI-free readers/calculations/result builders with synthetic
   tests.
4. Implement feature-owned snapshot fragments, renderers, and managed
   interactions. Give overlapping gestures one active owner; a movable
   rectangle must expose its visible interior or center as an ordinary drag
   target.
5. Keep selection cheap and batch loading lazy; separate preview-resolution
   work from original-resolution Run/Export.
6. Add portable project references, relinking, current-envelope save, and only
   the read-only compatibility imports/migrations actually required.
7. Test calculations, state transitions, renderers, and exports directly.
   Run the bounded GUI workflow once after those smaller checks are stable;
   do not use a long end-to-end GUI method as the edit-fail-edit loop.
8. Update the App definition version, manual, and component history.

Use `labkit-boundary-guard` before changing a public facade API,
record active compatibility retirement directly in `.agents/migration_guide.md`,
and use `labkit-test-planner` for validation. Report preserved science, changed flow,
files, tests, manual checks, and anything intentionally left app-local.

---
name: labkit-app-builder
description: "Use to create or substantially refactor a LabKit MATLAB App from scripts, functions, protocols, existing GUIs, workflow notes, or prose requirements. Narrow fixes that preserve the App shape remain ordinary App maintenance."
---

# LabKit App Builder

Read the root and App rules, source or protocol, closest genuinely similar App,
and affected docs/tests. Read framework rules only when its boundary may move.

Map inputs, action order, formulas, units, defaults, plots, results, exports,
failure behavior, durable state, transient state, and sensitive examples that
must become synthetic. Treat legacy code as evidence rather than architecture;
preserve science and observable contracts while discarding workspace plumbing,
hard-coded paths, globals, pauses, and exploratory branches.

Keep a narrow correction inside the current App shape unless the defect proves
a boundary change.

## Design and build

Write a short brief covering product state, capabilities, preserved behavior,
changed flow, input/commit/refresh classification, logging policy, evidence,
and manual GUI checks. Apply `apps/AGENTS.md` as the App shape authority. Add
only capabilities with a named product or lifecycle owner.

For every value-bearing control, state whether it is binding-only, bounded
preview, result-invalidating, or an explicit-work trigger. Slider drag and
rapid spinner edits use the SDK's commit boundary; their callback remains
light and does not own unbounded or potentially long IO/calculation, export,
waiting, or per-adjustment logs. It may perform one bounded current preview or
automatic refresh; a navigation control may read one bounded current record or
window for its core preview. Put work that cannot meet an interactive response
budget behind a named action. For every log,
justify the severity and retain only semantic aliases, bounded counts,
dimensions, units, and reasons; never retain paths, filenames, identities, or
scientific content.

For every plot, classify viewport invalidation separately from presentation
refresh. Use a semantic `ViewRevision` that changes for a new source/result,
plotted coordinate or unit/scale transform, changed image canvas, or explicit
fit/reset. Keep it stable for style, palette, grid, legend, annotation
visibility, same-size frame navigation, and overlay editing. Give live streams
an explicit rolling/out-of-view policy rather than refitting per sample. Use
App-owned IDs and bounded choices in revisions, never paths or filenames.

Make layout read in workflow order. Keep each capability's layout, direct
actions, presentation, and renderer together when they change together. Use
SDK bindings and defaults before callback glue; pass narrow domain values below
the callback boundary.

Build in this order:

1. identity, requirements, layout, and required project/session capabilities;
2. GUI-free readers, calculations, results, and synthetic tests;
3. feature-owned presentation, rendering, and managed interactions;
4. lazy batch input, preview/full-resolution separation, and exports;
5. portable persistence and only supported compatibility imports;
6. direct calculation, state, renderer, export, then bounded GUI evidence;
7. version, manual, and component history for the delivered contract.

Synthetic input must be anonymous, validated headlessly, and launched through
the ordinary native Developer Tools path; clean construction is insufficient.

Use `labkit-boundary-guard` before changing a public facade,
`labkit-scientific-change-guard` when scientific meaning changes, and
`labkit-test-planner` for evidence. Report preserved science, changed flow,
validation, manual checks, and intentionally App-local behavior.

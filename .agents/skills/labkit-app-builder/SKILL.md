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

Apply the callback commit, logging, and viewport rules in `apps/AGENTS.md`.
Record only the decisions the new App needs; do not restate SDK defaults.

For a panel redesign, walk through each requested operation from the user's
starting state to its visible result. Include empty, loaded, busy and recovery
states where they exist. Check the actual input shape: a single file may
need only a compact source row, while a batch may need a list. Try the narrow
layout with wrapped status text and check the space around sliders, numeric
fields and adjacent buttons. Identify which actions need keyboard, pointer or
touch checks. An HTML prototype can settle layout choices; verify the resulting
controls in MATLAB. Report which panels and operations were exercised and
which still need hands-on inspection.

Make layout read in workflow order. Keep each capability's layout, direct
actions, presentation, and renderer together when they change together. Use
SDK bindings and defaults before callback glue; pass narrow domain values below
the callback boundary.

Build the capabilities needed by the requested workflow, generally in this order.
Omit readers, calculation, batch/export, and persistence stages for Apps that
do not need them:

1. identity, requirements, layout, and only the in-memory state the App uses;
2. GUI-free readers, calculations, results, and synthetic tests;
3. feature-owned presentation, rendering, and managed interactions;
4. lazy batch input, preview/full-resolution separation, and exports;
5. App-owned persistence and compatibility imports only for an explicit
   continuation workflow;
6. direct calculation, state, renderer, export, then bounded GUI evidence;
7. version, manual, and component history for the delivered contract.

For Apps with input readers, validate anonymous synthetic input through the
production reader. For every App, validate its useful native-runtime outcome
using `labkit-test-planner`; a static reference App verifies displayed content
without inventing import or calculation. Keep relevant native dialog, pointer,
visual, and scientific checks explicit; clean construction is insufficient.

Use `labkit-boundary-guard` before changing a public facade,
`labkit-scientific-change-guard` when scientific meaning changes, and
`labkit-test-planner` for evidence. Report preserved science, changed flow,
validation, manual checks, and intentionally App-local behavior.

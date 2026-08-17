---
name: labkit-app-builder
description: "Use to create or substantially refactor a LabKit MATLAB app from scripts, functions, protocols, existing GUIs, workflow notes, or prose requirements. Do not use for a narrow bug fix that preserves the existing App shape."
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
a boundary change. Do not use a bug fix to justify unrelated rebuilding.

## Design and build

Write a short brief covering product state, capabilities, preserved behavior,
changed flow, evidence, and manual GUI checks. Apply `apps/AGENTS.md` as the App
shape authority. Add only capabilities with a named product or lifecycle owner.

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

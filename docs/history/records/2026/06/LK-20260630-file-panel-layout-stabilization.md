# File-panel layout stabilization

```labkit-change
schema: 1
id: LK-20260630-file-panel-layout-stabilization
date: 2026-06-30
type: fix
compatibility: compatible
component: `labkit.ui` | `3.2.3 -> 3.2.4`
component: `labkit.ui` | `3.2.4 -> 3.2.5`
```

## Context

The single-file panel allocated too much height to its rows and could render
inconsistently as the containing app resized. This was especially noticeable in
file-heavy apps, where the panel competed with analysis controls and plots.

## Decision and rationale

Give the panel explicit, compact row sizing and protect that geometry with GUI
layout tests. The change stayed in the shared file-panel builder because the
same visual defect appeared wherever the component was used.

## Changes

- `labkit.ui` `3.2.3 -> 3.2.5`

- Stabilized and compacted single file-panel layout.

## User and data impact

File names and actions occupied less vertical space, leaving more room for the
workflow below them. The change affected layout only; selections and loaded
file data were unchanged.

## Compatibility and migration

App definitions and selected files required no conversion. The shared panel
kept the same controls and callbacks with revised row geometry.

## Validation

Both commits extended `GuiLayoutUiDeclarativeAppTest` with the expected panel
geometry. Exact historical test commands were not recorded.

## Evidence

- Main commits `7f8df1cd` and `02b2f1b6`.

## Known limitations and follow-up

Later runtime generations replaced this private UI 3.x builder, but retained
the principle that shared components own and test their responsive geometry.

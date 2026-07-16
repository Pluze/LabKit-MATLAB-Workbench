# Legacy import and first app workbench

```labkit-change
schema: 2
id: LK-20260528-initial-app-workbench-foundation
date: 2026-05-28
sequence: 1
type: feat
compatibility: compatible
scope: historical project evolution
```

## Context

LabKit began with a direct import of older MATLAB analysis and GUI code. The
electrochem workflows mixed file parsing, calculations, session state, plots,
and exports inside large entry scripts, and several root commands exposed the
same legacy implementation through different paths.

## Decision and rationale

Separate the imported code by responsibility before adding new features. Move
Gamry parsing and pulse detection into reusable DTA operations; keep CIC, CSC,
VT resistance, EIS, and chrono calculations with their workflows; then expose
each workflow through one package-backed app command. Extract shared UI pieces
only after the app behavior is visible in more than one workflow.

## Changes

- Imported the legacy MATLAB tree without rewriting its scientific formulas.
- Extracted chrono, EIS, and CV/CT DTA parsers plus pulse detection and named
  synthetic fixtures.
- Separated chrono alignment/export, CIC, CSC, VT resistance, and EIS result
  operations from their GUI assembly.
- Added named app entry points and package-backed runners, then removed the
  duplicate root legacy entry points and legacy GUI directory.
- Introduced the first shared two-pane/tabbed shells, file panels, plot
  controls, log panels, and axes helpers used by the electrochem apps.

## User and data impact

Users gained named electrochem app commands instead of opening the old GUI
scripts directly. Calculations and exported values were intended to remain
unchanged while code ownership moved; laboratory files remained external
inputs rather than being copied into a central LabKit database.

## Compatibility and migration

- Component/app version files did not exist yet. Old root GUI entry points were
  removed as package-backed app commands became the supported launch path.

## Validation

The first regression evidence included named DTA fixtures, calculation tests,
an optional GUI smoke runner, and GUI compatibility checks. A single standard
test command had not yet been established.

## Evidence

- Initial import `5973bde0`.
- Parser and calculation extraction from `fc70f9b2` through `9f7c6e4e`.
- App entrypoint and package migration from `40f46561` through `4d58066c`.
- First shared app-shell work from `f05f4a35` through `61a8cb87`.

## Known limitations and follow-up

This stage improved structure but still contained several broad shared UI
helpers and session abstractions that were narrowed during the following DTA
facade and app-boundary work.

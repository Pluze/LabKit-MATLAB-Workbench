# Session logging gains coherent detail levels and automatic export

```labkit-change
id: LK-20260803-session-log-levels-and-automatic-export
date: 2026-08-03
sequence: 168
type: feat
compatibility: compatible
component: `labkit.app` | `2.1.0 -> 2.2.0`
scope: Session Log detail levels
scope: Automatic diagnostic export
```

## Context

The standard Session Log combined a severity selector with a second audience
view, presented an unexplained Default choice, and exposed a pause-follow
control that did not improve diagnosis. TRACE normally contained no more useful
detail than DEBUG because capture was off and Runtime emitted few trace stages.
Diagnostic ZIP export also asked for a destination before every attempt.

## Decision and rationale

Use one three-level display contract while keeping capture cost independent of
the selected view. Retain DEBUG and higher during ordinary operation, enable
TRACE automatically after the first error, and keep an explicit capture toggle
inside the owning log window. Give TRACE distinct transaction and presentation
stage records. Treat the repository artifacts area as the first diagnostic
destination and ask for another location only after automatic recovery fails.

## Changes

- The viewer now offers Full TRACE, DEBUG, and User levels, defaults to Full
  TRACE, follows new records continuously, and removes the duplicate View and
  pause-follow controls.
- Each viewer title names its owning App, and manual TRACE capture lives in the
  viewer instead of the App Tools menu.
- ERROR and CRITICAL records enable TRACE capture for later activity; trace
  records now distinguish state update, validation, presentation, native
  commit, and rollback cleanup stages.
- Diagnostic export generates a unique App-specific filename beneath
  `artifacts/diagnostics/`; its text fallback uses the same base name, and a
  prefilled save dialog appears only when automatic output fails.

## User and data impact

Users can distinguish concurrent App logs, select a meaningful amount of detail
with one control, and export diagnostics without choosing a path. Diagnostic
contents remain limited to validated privacy-safe Runtime records. Projects,
inputs, results, paths, filenames, images, and screenshots remain excluded.

## Compatibility and migration

The App SDK change is compatible with existing version-2 App requirements and
does not change callback logging syntax, canonical event fields, projects, or
results. Existing App definitions require no migration. The removed Tools-menu
TRACE item was a Runtime utility, not an App-facing API; the same manual ability
is available in the Session Log window.

## Validation

Focused headless specifications cover three-level projection, automatic trace
activation, distinct trace stages, generated ZIP and fallback names, and the
privacy boundary. Hidden-GUI specifications cover App-specific titles, the
single level selector, viewer-local TRACE control, continuous follow, removed
duplicate controls, and exports from both entry points.

## Evidence

- `labkittest.run(File="+labkit/+app/+internal/SessionLogProjection.m")`
- `labkittest.run(File="+labkit/+app/+internal/SessionLogViewer.m")`
- `labkittest.run(File="+labkit/+app/+internal/SessionDiagnosticBundle.m")`
- Deterministic documentation generation and authored-link validation.

## Known limitations and follow-up

TRACE cannot reconstruct stages that occurred before capture was enabled. A
process termination before Runtime records a terminal event still leaves only
the last successfully retained boundary. Native visual density and dialog feel
remain manual review boundaries.

# File-panel migration

```labkit-change
schema: 1
id: LK-20260624-file-panel-migration
date: 2026-06-24
type: refactor
compatibility: breaking
component: `labkit.dta` | `1.0.0 -> 2.0.0`
component: `labkit.ui` | `2.2.1 -> 3.0.0`
component: `labkit_DICPostprocess_app` | `1.0.1 -> 1.2.0`
component: `labkit_DICPreprocess_app` | `1.0.1 -> 1.2.0`
component: `labkit_ChronoOverlay_app` | `1.0.0 -> 1.2.0`
component: `labkit_CIC_app` | `1.0.0 -> 1.2.0`
component: `labkit_CSC_app` | `1.0.0 -> 1.2.0`
component: `labkit_EIS_app` | `1.0.0 -> 1.2.0`
component: `labkit_VTResistance_app` | `1.0.0 -> 1.2.0`
component: `labkit_BatchImageCrop_app` | `1.0.0 -> 1.2.0`
component: `labkit_CurvatureMeasurement_app` | `1.0.1 -> 1.2.0`
component: `labkit_FocusStack_app` | `1.0.0 -> 1.2.0`
component: `labkit_ImageEnhance_app` | `1.0.0 -> 1.2.0`
component: `labkit_ImageMatch_app` | `1.0.0 -> 1.2.0`
component: `labkit_NerveResponseAnalysis_app` | `1.0.0 -> 1.2.0`
component: `labkit_ResponseReviewStats_app` | `1.0.0 -> 1.2.0`
component: `labkit_RHSPreview_app` | `1.0.0 -> 1.2.0`
component: `labkit_ECGPrint_app` | `1.0.0 -> 1.2.0`
```

## Context

Apps implemented file selection through separate task-input adapters, which
produced inconsistent lists, selection events, and status feedback. The DTA
session helper also coupled parsing to that older UI model.

## Decision and rationale

Move supported apps to one reusable file-panel model and make DTA loading a
GUI-free file/curve API. Accept the breaking package versions because retaining
both task-input and file-panel paths would preserve ambiguous callback behavior.

## Changes

- `labkit.dta` `1.0.0 -> 2.0.0`
- `labkit.ui` `2.2.1 -> 3.0.0`
- All supported apps moved from `1.0.x` into the `1.2.0` workflow line.

- Replaced task inputs with file panels.
- Removed the old DTA session helper surface.

## User and data impact

File lists, current selection, add/remove actions, and status display became
consistent across the migrated apps. App code written against the removed task
inputs or DTA session helpers required an update.

## Compatibility and migration

- This was a breaking workflow migration. Older app code expecting task inputs
  or the removed DTA session helpers needed migration.

## Validation

The carrying commit migrated app GUI workflows and package compatibility tests
to the new file-panel and DTA APIs. The exact historical test command was not
recorded.

## Evidence

- Main commit `b145c904`.

## Known limitations and follow-up

This first file-panel generation was later refined for append behavior, native
dialog edge cases, and Runtime V2 events.

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

- File selection became a shared UI workflow instead of app-specific task-input
  plumbing.

## Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

## Changes

- `labkit.dta` `1.0.0 -> 2.0.0`
- `labkit.ui` `2.2.1 -> 3.0.0`
- All supported apps moved from `1.0.x` into the `1.2.0` workflow line.

- Replaced task inputs with file panels.
- Removed the old DTA session helper surface.

## User and data impact

- File selection became a shared UI workflow instead of app-specific task-input
  plumbing.

## Compatibility and migration

- This was a breaking workflow migration. Older app code expecting task inputs
  or the removed DTA session helpers needed migration.

## Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

## Evidence

- Main commit `b145c904`.

## Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

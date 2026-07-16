# CSC export and viewport policy

```labkit-change
schema: 1
id: LK-20260703-csc-export-and-viewport-policy
date: 2026-07-03
type: feat
compatibility: compatible
component: `labkit.ui` | `4.0.0 -> 4.1.0`
component: `labkit_DICPostprocess_app` | `1.3.2 -> 1.3.3`
component: `labkit_DICPreprocess_app` | `1.3.2 -> 1.3.3`
component: `labkit_ChronoOverlay_app` | `1.3.2 -> 1.3.3`
component: `labkit_CIC_app` | `1.3.4 -> 1.3.5`
component: `labkit_CSC_app` | `1.3.4 -> 1.3.6`
component: `labkit_EIS_app` | `1.3.2 -> 1.3.3`
component: `labkit_VTResistance_app` | `1.3.4 -> 1.3.5`
component: `labkit_BatchImageCrop_app` | `1.6.4 -> 1.6.5`
component: `labkit_CurvatureMeasurement_app` | `1.3.2 -> 1.3.3`
component: `labkit_FLIRThermal_app` | `1.2.3 -> 1.2.4`
component: `labkit_FocusStack_app` | `1.4.3 -> 1.4.4`
component: `labkit_ImageEnhance_app` | `1.5.3 -> 1.5.4`
component: `labkit_ImageMatch_app` | `1.5.3 -> 1.5.4`
component: `labkit_NerveResponseAnalysis_app` | `1.3.2 -> 1.3.3`
component: `labkit_ResponseReviewStats_app` | `1.3.2 -> 1.3.3`
component: `labkit_RHSPreview_app` | `1.3.2 -> 1.3.3`
component: `labkit_ECGPrint_app` | `1.3.3 -> 1.3.4`
```

## Context

- Users can export more complete CSC cycle data, and app layouts share the same
  viewport assumptions.

## Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

## Changes

- `labkit.ui` `4.0.0 -> 4.1.0`
- All supported apps received aligned patch bumps.

- Added CSC all-cycle export.
- Added viewport policy support and aligned app contracts with the UI 4.x line.

## User and data impact

- Users can export more complete CSC cycle data, and app layouts share the same
  viewport assumptions.

## Compatibility and migration

No manual migration was recorded for this historical change.

## Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

## Evidence

- Main commit `a69829c6`.

## Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

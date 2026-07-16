# Debug sample packs

```labkit-change
schema: 1
id: LK-20260701-debug-sample-packs
date: 2026-07-01
type: feat
compatibility: compatible
component: `labkit.ui` | `3.3.1 -> 3.4.0`
component: `labkit_DICPostprocess_app` | `1.2.4 -> 1.3.0`
component: `labkit_DICPreprocess_app` | `1.2.2 -> 1.3.0`
component: `labkit_ChronoOverlay_app` | `1.2.1 -> 1.3.0`
component: `labkit_CIC_app` | `1.2.1 -> 1.3.0`
component: `labkit_CSC_app` | `1.2.1 -> 1.3.0`
component: `labkit_EIS_app` | `1.2.1 -> 1.3.0`
component: `labkit_VTResistance_app` | `1.2.1 -> 1.3.0`
component: `labkit_BatchImageCrop_app` | `1.5.1 -> 1.6.0`
component: `labkit_CurvatureMeasurement_app` | `1.2.4 -> 1.3.0`
component: `labkit_FLIRThermal_app` | `1.1.2 -> 1.2.0`
component: `labkit_FocusStack_app` | `1.3.0 -> 1.4.0`
component: `labkit_ImageEnhance_app` | `1.4.1 -> 1.5.0`
component: `labkit_ImageMatch_app` | `1.4.1 -> 1.5.0`
component: `labkit_NerveResponseAnalysis_app` | `1.2.4 -> 1.3.0`
component: `labkit_ResponseReviewStats_app` | `1.2.3 -> 1.3.0`
component: `labkit_RHSPreview_app` | `1.2.4 -> 1.3.0`
component: `labkit_ECGPrint_app` | `1.2.2 -> 1.3.0`
```

## Context

- Reproducing app failures became a maintained workflow instead of an ad hoc
  collection of local files.

## Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

## Changes

- `labkit.ui` `3.3.1 -> 3.4.0`
- All supported apps moved into the `1.3.x`, `1.4.x`, `1.5.x`, or `1.6.x`
  debug-sample-pack lines.

- Added app-owned debug sample packs.
- Added debug artifact sample and output folders.

## User and data impact

- Reproducing app failures became a maintained workflow instead of an ad hoc
  collection of local files.

## Compatibility and migration

No manual migration was recorded for this historical change.

## Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

## Evidence

- Main commit `279befbc`.

## Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

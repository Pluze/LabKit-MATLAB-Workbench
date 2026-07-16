# UI groups migration

```labkit-change
schema: 1
id: LK-20260703-ui-groups-migration
date: 2026-07-03
type: refactor
compatibility: compatible
component: `labkit.ui` | `3.4.5 -> 4.0.0`
component: `labkit_DICPostprocess_app` | `1.3.1 -> 1.3.2`
component: `labkit_DICPreprocess_app` | `1.3.1 -> 1.3.2`
component: `labkit_ChronoOverlay_app` | `1.3.1 -> 1.3.2`
component: `labkit_CIC_app` | `1.3.3 -> 1.3.4`
component: `labkit_CSC_app` | `1.3.3 -> 1.3.4`
component: `labkit_EIS_app` | `1.3.1 -> 1.3.2`
component: `labkit_VTResistance_app` | `1.3.3 -> 1.3.4`
component: `labkit_BatchImageCrop_app` | `1.6.3 -> 1.6.4`
component: `labkit_CurvatureMeasurement_app` | `1.3.1 -> 1.3.2`
component: `labkit_FLIRThermal_app` | `1.2.2 -> 1.2.3`
component: `labkit_FocusStack_app` | `1.4.2 -> 1.4.3`
component: `labkit_ImageEnhance_app` | `1.5.2 -> 1.5.3`
component: `labkit_ImageMatch_app` | `1.5.2 -> 1.5.3`
component: `labkit_NerveResponseAnalysis_app` | `1.3.1 -> 1.3.2`
component: `labkit_ResponseReviewStats_app` | `1.3.1 -> 1.3.2`
component: `labkit_RHSPreview_app` | `1.3.1 -> 1.3.2`
component: `labkit_ECGPrint_app` | `1.3.2 -> 1.3.3`
```

## Context

- This is the point where app action layout became a grouped UI contract instead
  of a looser action-list convention.

## Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

## Changes

- `labkit.ui` `3.4.5 -> 4.0.0`
- All supported apps received patch bumps.

- Replaced action groups with UI groups.
- Moved the reusable UI contract into the 4.x line.

## User and data impact

- This is the point where app action layout became a grouped UI contract instead
  of a looser action-list convention.

## Compatibility and migration

- App workflow definitions had to align with the new grouped UI contract.

## Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

## Evidence

- Main commit `e81243a3`.

## Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

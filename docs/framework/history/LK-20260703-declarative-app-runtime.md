# Declarative app runtime

```labkit-change
schema: 1
id: LK-20260703-declarative-app-runtime
date: 2026-07-03
type: refactor
compatibility: compatible
component: `labkit.ui` | `3.4.4 -> 3.4.5`
component: `labkit_DICPostprocess_app` | `1.3.0 -> 1.3.1`
component: `labkit_DICPreprocess_app` | `1.3.0 -> 1.3.1`
component: `labkit_ChronoOverlay_app` | `1.3.0 -> 1.3.1`
component: `labkit_CIC_app` | `1.3.0 -> 1.3.1`
component: `labkit_CSC_app` | `1.3.0 -> 1.3.1`
component: `labkit_EIS_app` | `1.3.0 -> 1.3.1`
component: `labkit_VTResistance_app` | `1.3.0 -> 1.3.1`
component: `labkit_BatchImageCrop_app` | `1.6.1 -> 1.6.2`
component: `labkit_CurvatureMeasurement_app` | `1.3.0 -> 1.3.1`
component: `labkit_FLIRThermal_app` | `1.2.0 -> 1.2.1`
component: `labkit_FocusStack_app` | `1.4.0 -> 1.4.1`
component: `labkit_ImageEnhance_app` | `1.5.0 -> 1.5.1`
component: `labkit_ImageMatch_app` | `1.5.0 -> 1.5.1`
component: `labkit_NerveResponseAnalysis_app` | `1.3.0 -> 1.3.1`
component: `labkit_ResponseReviewStats_app` | `1.3.0 -> 1.3.1`
component: `labkit_RHSPreview_app` | `1.3.0 -> 1.3.1`
component: `labkit_ECGPrint_app` | `1.3.1 -> 1.3.2`
```

## Context

- Maintainers can reason about app wiring through workflow definitions instead
  of hand-following callback construction.

## Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

## Changes

- `labkit.ui` `3.4.4 -> 3.4.5`
- All supported apps received patch bumps.

- Migrated apps to declarative workflow runtime.

## User and data impact

- Maintainers can reason about app wiring through workflow definitions instead
  of hand-following callback construction.

## Compatibility and migration

No manual migration was recorded for this historical change.

## Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

## Evidence

- Main commit `568b3e9b`.

## Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

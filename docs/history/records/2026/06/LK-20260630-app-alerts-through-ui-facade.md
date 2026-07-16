# App alerts through UI facade

```labkit-change
schema: 1
id: LK-20260630-app-alerts-through-ui-facade
date: 2026-06-30
type: feat
compatibility: compatible
component: `labkit.ui` | `3.2.7 -> 3.2.8`
component: `labkit_DICPostprocess_app` | `1.2.2 -> 1.2.3`
component: `labkit_DICPreprocess_app` | `1.2.1 -> 1.2.2`
component: `labkit_ChronoOverlay_app` | `1.2.0 -> 1.2.1`
component: `labkit_CIC_app` | `1.2.0 -> 1.2.1`
component: `labkit_CSC_app` | `1.2.0 -> 1.2.1`
component: `labkit_EIS_app` | `1.2.0 -> 1.2.1`
component: `labkit_VTResistance_app` | `1.2.0 -> 1.2.1`
component: `labkit_BatchImageCrop_app` | `1.3.6 -> 1.3.7`
component: `labkit_CurvatureMeasurement_app` | `1.2.2 -> 1.2.3`
component: `labkit_FocusStack_app` | `1.2.4 -> 1.2.5`
component: `labkit_ImageEnhance_app` | `1.3.3 -> 1.3.4`
component: `labkit_ImageMatch_app` | `1.3.4 -> 1.3.5`
component: `labkit_ECGPrint_app` | `1.2.1 -> 1.2.2`
```

## Context

- App error reporting became testable without each app inventing its own alert
  mechanics.

## Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

## Changes

- `labkit.ui` `3.2.7 -> 3.2.8`
- DIC, electrochem, image-measurement, and ECG apps patch bumped where alert
  routing changed.

- Routed app alerts through hidden-test-safe `labkit.ui.app.showAlert`.

## User and data impact

- App error reporting became testable without each app inventing its own alert
  mechanics.

## Compatibility and migration

No manual migration was recorded for this historical change.

## Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

## Evidence

- Main commit `8d7c83b1`.

## Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

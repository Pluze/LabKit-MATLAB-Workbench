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

Apps opened alerts directly, which made hidden GUI tests unreliable and led to
small differences in modal behavior across workflows.

## Decision and rationale

Route user-visible alerts through one UI service that can display a modal
message normally and record it safely during hidden tests. Keep each app
responsible for the message and the decision that triggers it.

## Changes

- `labkit.ui` `3.2.7 -> 3.2.8`
- DIC, electrochem, image-measurement, and ECG apps patch bumped where alert
  routing changed.

- Routed app alerts through hidden-test-safe `labkit.ui.app.showAlert`.

## User and data impact

Errors continued to appear as app alerts, but test and debug runs could capture
them without blocking on an invisible dialog. No saved or exported data changed.

## Compatibility and migration

No manual migration was recorded for this historical change.

## Validation

The carrying commit migrated alert call sites and updated hidden workflow tests
across the listed apps. The exact historical command was not recorded.

## Evidence

- Main commit `8d7c83b1`.

## Known limitations and follow-up

The historical `labkit.ui.app.showAlert` entry point was later replaced by the
injected `services.dialogs.alert` service in Runtime V2.

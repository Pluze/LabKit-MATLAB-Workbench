# App alerts through UI facade

```labkit-change
id: CHG-20260630-app-alerts-through-ui-facade
date: 2026-06-30
type: feat
compatibility: compatible
component: labkit.ui | 3.2.7 -> 3.2.8
component: labkit_DICPostprocess_app | 1.2.2 -> 1.2.3
component: labkit_DICPreprocess_app | 1.2.1 -> 1.2.2
component: labkit_ChronoOverlay_app | 1.2.0 -> 1.2.1
component: labkit_CIC_app | 1.2.0 -> 1.2.1
component: labkit_CSC_app | 1.2.0 -> 1.2.1
component: labkit_EIS_app | 1.2.0 -> 1.2.1
component: labkit_VTResistance_app | 1.2.0 -> 1.2.1
component: labkit_BatchImageCrop_app | 1.3.6 -> 1.3.7
component: labkit_CurvatureMeasurement_app | 1.2.2 -> 1.2.3
component: labkit_FocusStack_app | 1.2.4 -> 1.2.5
component: labkit_ImageEnhance_app | 1.3.3 -> 1.3.4
component: labkit_ImageMatch_app | 1.3.4 -> 1.3.5
component: labkit_ECGPrint_app | 1.2.1 -> 1.2.2
```

## Why

Apps opened alerts directly, which made hidden GUI tests unreliable and led to small differences in modal behavior across workflows.

### Accepted choice

Route user-visible alerts through one UI service that can display a modal message normally and record it safely during hidden tests. Keep each app responsible for the message and the decision that triggers it.

## What changed

- DIC, electrochem, image-measurement, and ECG apps patch bumped where alert routing changed.

- Routed app alerts through hidden-test-safe `labkit.ui.app.showAlert`.

## Impact

Errors continued to appear as app alerts, but test and debug runs could capture them without blocking on an invisible dialog. No saved or exported data changed.

## Compatibility and limits

App error conditions and messages remained app-owned. Only the display route changed, so user data and app project formats required no conversion.

### Remaining limits

The historical `labkit.ui.app.showAlert` entry point was later replaced by the injected `services.dialogs.alert` service in Runtime V2.

# Declarative app runtime

```labkit-change
id: CHG-20260703-declarative-app-runtime
date: 2026-07-03
type: refactor
compatibility: compatible
component: labkit.ui | 3.4.4 -> 3.4.5
component: labkit_DICPostprocess_app | 1.3.0 -> 1.3.1
component: labkit_DICPreprocess_app | 1.3.0 -> 1.3.1
component: labkit_ChronoOverlay_app | 1.3.0 -> 1.3.1
component: labkit_CIC_app | 1.3.0 -> 1.3.1
component: labkit_CSC_app | 1.3.0 -> 1.3.1
component: labkit_EIS_app | 1.3.0 -> 1.3.1
component: labkit_VTResistance_app | 1.3.0 -> 1.3.1
component: labkit_BatchImageCrop_app | 1.6.1 -> 1.6.2
component: labkit_CurvatureMeasurement_app | 1.3.0 -> 1.3.1
component: labkit_FLIRThermal_app | 1.2.0 -> 1.2.1
component: labkit_FocusStack_app | 1.4.0 -> 1.4.1
component: labkit_ImageEnhance_app | 1.5.0 -> 1.5.1
component: labkit_ImageMatch_app | 1.5.0 -> 1.5.1
component: labkit_NerveResponseAnalysis_app | 1.3.0 -> 1.3.1
component: labkit_ResponseReviewStats_app | 1.3.0 -> 1.3.1
component: labkit_RHSPreview_app | 1.3.0 -> 1.3.1
component: labkit_ECGPrint_app | 1.3.1 -> 1.3.2
```

## Why

Apps had adopted common shells and controls, but each runner still assembled callbacks, startup steps, refresh behavior, and debug hooks in its own order. Understanding an app meant reading a long construction procedure before reaching the scientific workflow.

### Accepted choice

Describe an app through a definition containing its layout, actions, state, startup, and rendering contracts, then let the runtime perform the common wiring. Keep action bodies, calculations, and result structures in the app so the definition exposes workflow structure without becoming a generic analysis language.

## What changed

- All supported apps received patch bumps.

- Migrated apps to declarative workflow runtime.

## Impact

The visible workflows were intended to remain the same. For maintainers, each app gained a recognizable definition and lifecycle, while repeated setup moved out of its runner. Debug sample packs and focused app tests continued to call the same app-owned operations.

## Compatibility and limits

Users kept the same app entry points and data files. App implementations moved to definitions and runtime actions; unsupported code that reached into old runner construction details needed to adopt the declarative APIs.

### Remaining limits

The first declarative vocabulary still used the mixed `app`, `spec`, `view`, `tool`, and `diag` package names. The UI 4 and UI 5 passes refined how groups, plots, interactions, and lifecycle responsibilities were named.

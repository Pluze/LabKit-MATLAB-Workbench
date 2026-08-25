# Close guards and caught-exception diagnostics

```labkit-change
id: CHG-20260630-close-guards-and-caught-exception-diagnostics
date: 2026-06-30
type: feat
compatibility: compatible
component: labkit.ui | 3.2.6 -> 3.2.7
component: labkit_DICPostprocess_app | 1.2.1 -> 1.2.2
component: labkit_BatchImageCrop_app | 1.3.4 -> 1.3.6
component: labkit_CurvatureMeasurement_app | 1.2.1 -> 1.2.2
component: labkit_FocusStack_app | 1.2.2 -> 1.2.4
component: labkit_ImageEnhance_app | 1.3.2 -> 1.3.3
component: labkit_ImageMatch_app | 1.3.2 -> 1.3.4
component: labkit_NerveResponseAnalysis_app | 1.2.3 -> 1.2.4
component: labkit_ResponseReviewStats_app | 1.2.2 -> 1.2.3
component: labkit_RHSPreview_app | 1.2.1 -> 1.2.2
component: labkit_ECGPrint_app | 1.2.0 -> 1.2.1
```

## Why

Many app callbacks caught an exception, showed its message, and returned. That protected the UI but discarded the stack and callback context needed to diagnose the failure. Image apps also tracked unsaved or incomplete work in slightly different ways when deciding whether a window could close.

### Accepted choice

Report caught exceptions to the existing debug trace before presenting the user-facing error, and promote the file-index and close-guard mechanics that were shared by several image apps. Preserve app ownership of what counts as dirty or incomplete work.

## What changed

- DIC, Batch Crop, Curvature, Focus Stack, Image Match, neurophysiology apps, and ECG Print patch bumped for diagnostics or close-guard work.

- Reported caught app-runner exceptions through framework debug diagnostics.
- Promoted file-entry index helpers.
- Connected dirty/incomplete workflow state to close guards.

## Impact

An app could still recover from a failed load, calculation, or export, while its debug report retained the exception evidence. Closing an image workflow with unfinished state produced a consistent warning instead of silently discarding work. Scientific results and saved schemas were unchanged.

## Compatibility and limits

Existing app state and result files remained valid. Closing an incomplete workflow gained an additional confirmation, and debug reports gained exception details.

### Remaining limits

Runtime V2 later replaced direct debug-log and close-guard calls with lifecycle and diagnostic services, but retained the requirement that caught exceptions remain observable.

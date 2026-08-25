# Version metadata baseline

```labkit-change
id: CHG-20260623-version-metadata-baseline
date: 2026-06-23
type: feat
compatibility: compatible
component: labkit_launcher | new -> 1.0.0
component: labkit.ui | 2.1.0 -> 2.2.0
component: labkit_DICPostprocess_app | new -> 1.0.0
component: labkit_DICPreprocess_app | new -> 1.0.0
component: labkit_ChronoOverlay_app | new -> 1.0.0
component: labkit_CIC_app | new -> 1.0.0
component: labkit_CSC_app | new -> 1.0.0
component: labkit_EIS_app | new -> 1.0.0
component: labkit_VTResistance_app | new -> 1.0.0
component: labkit_BatchImageCrop_app | new -> 1.0.0
component: labkit_CurvatureMeasurement_app | new -> 1.0.0
component: labkit_FocusStack_app | new -> 1.0.0
component: labkit_ImageEnhance_app | new -> 1.0.0
component: labkit_ImageMatch_app | new -> 1.0.0
component: labkit_NerveResponseAnalysis_app | new -> 1.0.0
component: labkit_ResponseReviewStats_app | new -> 1.0.0
component: labkit_RHSPreview_app | new -> 1.0.0
component: labkit_ECGPrint_app | new -> 1.0.0
```

## Why

The repository had release tags and package contracts, but the launcher and individual apps did not display their own component versions.

### Accepted choice

Add lightweight `version` requests to every app and the launcher, show those versions in titles and the launcher catalog, and validate their format so a debug report can identify the exact component being run.

## What changed

- Release tag `v2.4.0`
- `labkit_launcher` `1.0.0`
- All supported apps `1.0.0`

- Added app and launcher version metadata.
- Added versioned titles, lightweight version requests, launcher catalog version display, and version guardrails.

## Impact

Users and maintainers could read the launcher and app version without inspecting Git history. The change added metadata only and did not modify saved data or numerical results.

## Compatibility and limits

Version requests and titles were additive. Existing app commands, inputs, and saved results continued to work without conversion.

### Remaining limits

These component versions describe displayed app/library builds; compatibility between reusable packages is handled separately by `labkit.contract`.

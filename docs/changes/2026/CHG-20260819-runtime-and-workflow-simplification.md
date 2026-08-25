# Simplified runtime and workflow ownership

```labkit-change
id: CHG-20260819-runtime-and-workflow-simplification
date: 2026-08-19
type: refactor
compatibility: compatible
component: labkit.dta | 3.1.0 -> 3.1.1
component: labkit.mark10 | 1.0.0 -> 1.0.1
component: labkit_DICPreprocess_app | 1.7.2 -> 1.7.3
component: labkit_CIC_app | 1.6.2 -> 1.6.3
component: labkit_EIS_app | 1.6.2 -> 1.6.3
component: labkit_VTResistance_app | 1.6.2 -> 1.6.3
component: labkit_Mark10Monitor_app | 1.0.0 -> 1.0.1
component: labkit_GaitAnalysis_app | 2.2.2 -> 2.2.3
component: labkit_BatchImageCrop_app | 1.9.3 -> 1.9.4
component: labkit_CurvatureMeasurement_app | 1.6.2 -> 1.6.3
component: labkit_FLIRThermal_app | 1.6.2 -> 1.6.3
component: labkit_FocusStack_app | 1.7.2 -> 1.7.3
component: labkit_ImageEnhance_app | 1.8.2 -> 1.8.3
component: labkit_ImageMatch_app | 1.8.2 -> 1.8.3
component: labkit_NerveResponseAnalysis_app | 1.6.1 -> 1.6.2
component: labkit_ResponseReviewStats_app | 1.6.1 -> 1.6.2
component: labkit_RHSPreview_app | 1.6.2 -> 1.6.3
```

## Why

Repository-wide simplification found private helpers that duplicated direct MATLAB operations, retained retired workflow layers, or split one parser or callback responsibility across unnecessary files. Keeping those paths increased dependency and test-maintenance cost without preserving an independent user contract.

### Accepted choice

The affected Apps now keep straightforward workflow glue at its natural caller, while the DTA and Mark-10 facades retain their existing public surfaces with fewer internal ownership seams. This favors visible fixed symbol calls and one clear state transition over compatibility-only or speculative helper layers.

## What changed

Unused App helpers and their implementation-shaped tests were removed, repeated DTA table-section parsing was consolidated, and Mark-10 sampling and App callbacks were reduced to their direct owners. Gait step review composition and several result or presentation paths now express the same supported workflow with less intermediate state and dispatch code.

## Impact

Entrypoints, controls, supported inputs, calculations, exports, project data, and facade call syntax remain available. Existing projects and laboratory data require no conversion; the changes reduce internal code and do not introduce a new runtime dependency.

## Compatibility and limits

The release is compatible within each component's existing major-version range. No saved-data migration, API rename, optional Toolbox, Java, Python, Conda, or third-party runtime is required.

### Remaining limits

No known compatibility limitation or follow-up remains for this simplification.

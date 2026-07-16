# Image app workflow improvements

```labkit-change
schema: 2
id: LK-20260701-image-app-workflow-improvements
date: 2026-07-01
sequence: 27
type: feat
compatibility: compatible
component: `labkit_launcher` | `1.1.5 -> 1.1.6`
component: `labkit.image` | `1.0.0 -> 1.1.0`
component: `labkit.ui` | `3.2.10 -> 3.3.0`
component: `labkit.ui` | `3.3.0 -> 3.3.1`
component: `labkit_BatchImageCrop_app` | `1.4.0 -> 1.5.0`
component: `labkit_BatchImageCrop_app` | `1.5.0 -> 1.5.1`
component: `labkit_FLIRThermal_app` | `1.0.0 -> 1.1.0`
component: `labkit_FLIRThermal_app` | `1.1.0 -> 1.1.2`
component: `labkit_ImageEnhance_app` | `1.4.0 -> 1.4.1`
component: `labkit_ImageMatch_app` | `1.4.0 -> 1.4.1`
```

## Context

Image apps used full-resolution data for several previews even when the screen
could not display that detail. Controls also accepted ranges that were awkward
for the current image, and FLIR point and ROI measurements were not yet a
complete direct-manipulation workflow.

## Decision and rationale

Set an explicit preview budget, derive sensible control bounds from the loaded
image, and preserve full-resolution data for calculations and exports. Expand
the FLIR app around point and ROI temperature tools rather than adding more
separate analysis dialogs.

## Changes

- `labkit.image` `1.0.0 -> 1.1.0`
- `labkit.ui` `3.2.10 -> 3.3.1`
- Batch Crop `1.4.0 -> 1.5.1`
- FLIR Thermal `1.0.0 -> 1.1.2`
- `labkit_launcher` `1.1.5 -> 1.1.6`

- Added preview-budget helpers.
- Improved image app range and preview controls.
- Improved image measurement workflows.

## User and data impact

Large images produced bounded previews while exports continued to use source
resolution. Batch Crop controls reflected the crop and scale being edited, and
FLIR users could place temperature points or regions directly on the image and
read their values in the detail panel.

## Compatibility and migration

Existing image inputs and app exports remained valid. Preview budgeting changed
display resolution only; calculations and exports continued to use the source
data required by each workflow.

## Validation

The two commits expanded Batch Crop export tests, FLIR operation and layout
tests, image-facade preview tests, busy-state tests, scale-bar gesture checks,
and launcher coverage. Exact historical commands were not recorded.

## Evidence

- Main commits `15a798ba` and `70bfcfd4`.

## Known limitations and follow-up

Preview budgeting improved responsiveness but did not by itself remove every
eager image read. Batch Crop file selection was made lazy in the following
profiling work.

# App actions require explanatory hover help

```labkit-change
schema: 2
id: LK-20260720-app-action-tooltips
date: 2026-07-20
sequence: 140
type: feat
compatibility: compatible
component: `labkit.app` | `1.0.0 -> 1.1.0`
component: `labkit_DICPostprocess_app` | `1.5.0 -> 1.5.1`
component: `labkit_DICPreprocess_app` | `1.6.0 -> 1.6.1`
component: `labkit_ChronoOverlay_app` | `1.5.0 -> 1.5.1`
component: `labkit_CIC_app` | `1.5.0 -> 1.5.1`
component: `labkit_CSC_app` | `1.5.0 -> 1.5.1`
component: `labkit_EIS_app` | `1.5.0 -> 1.5.1`
component: `labkit_VTResistance_app` | `1.5.0 -> 1.5.1`
component: `labkit_GaitAnalysis_app` | `2.1.0 -> 2.1.1`
component: `labkit_BatchImageCrop_app` | `1.8.0 -> 1.8.1`
component: `labkit_CurvatureMeasurement_app` | `1.5.0 -> 1.5.1`
component: `labkit_FLIRThermal_app` | `1.5.0 -> 1.5.1`
component: `labkit_FocusStack_app` | `1.6.0 -> 1.6.1`
component: `labkit_ImageEnhance_app` | `1.7.0 -> 1.7.1`
component: `labkit_ImageMatch_app` | `1.7.0 -> 1.7.1`
component: `labkit_VideoMarker_app` | `1.6.0 -> 1.6.1`
component: `labkit_FigureStudio_app` | `0.3.0 -> 0.3.1`
component: `labkit_NerveResponseAnalysis_app` | `1.5.0 -> 1.5.1`
component: `labkit_ResponseReviewStats_app` | `1.5.0 -> 1.5.1`
component: `labkit_RHSPreview_app` | `1.5.0 -> 1.5.1`
component: `labkit_TTestWizard_app` | `1.1.0 -> 1.1.1`
component: `labkit_ECGPrint_app` | `1.5.0 -> 1.5.1`
scope: App Framework
scope: All tracked Apps
```

## Context

The native text-fit adapter copied button text through a column-shaped char
conversion. MATLAB therefore received one newline between every character and
rendered hover help as a narrow vertical strip. The generated tooltip also
only repeated the visible label, so it did not explain the scientific or
workflow consequence of an action.

## Decision and rationale

Make explanatory hover help part of the semantic layout contract. Every
`layout.button` produces a nonempty Tooltip, and tracked Apps must replace the
label-based framework fallback with App-owned explanatory text. File-list
actions expose dedicated tooltip fields and retain framework-owned defaults
for generic folder, remove, and clear mechanics. Scientific meaning stays in
the owning App rather than in the native adapter.

All tracked Apps now describe what their actions consume, calculate, mutate,
or export. The contract guardrail rejects App tooltips that only repeat the
visible action label and also requires an explanatory input-selection tooltip.

## Changes

- Preserved char row vectors as one text line during native text fitting,
  eliminating the injected character-by-character newlines.
- Added `Tooltip` support with a nonempty label fallback to `layout.button`
  and dedicated file-list tooltips for choose, folder, recursive folder,
  remove, and clear actions.
- Added scientific and workflow-specific text for all 138 tracked App business
  buttons and all 26 App input selectors.
- Updated each owning App manual and the framework authoring examples.

## Compatibility and user impact

Existing tracked Apps and third-party layouts retain their actions and
calculations. Hovering now always shows readable text; tracked Apps additionally
carry domain-specific explanations.

## Validation and evidence

- App SDK unit coverage for required and compiled tooltip values.
- Cross-App definition guardrail for non-label business and input tooltips.
- Native adapter GUI coverage for exact tooltip text without injected
  newlines.
- DIC Postprocess GUI coverage for scientific action and Ncorr input help.

## Follow-up

Developer-led interactive checks should confirm tooltip timing, width, and
line wrapping on supported MATLAB releases and desktop platforms.

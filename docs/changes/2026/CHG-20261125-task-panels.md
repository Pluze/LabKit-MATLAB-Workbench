# Follow task-oriented control panels in the native workbench

```labkit-change
id: CHG-20261125-task-panels
date: 2026-11-25
type: feat
compatibility: compatible
component: labkit.app | 3.7.1 -> 3.7.2
component: labkit_DICPostprocess_app | 1.9.0 -> 1.10.0
component: labkit_DICPreprocess_app | 1.9.0 -> 1.10.0
component: labkit_NIDMMRecorder_app | 1.2.0 -> 1.3.0
component: labkit_ChronoOverlay_app | 1.8.0 -> 1.9.0
component: labkit_CIC_app | 1.9.0 -> 1.10.0
component: labkit_CSC_app | 1.9.0 -> 1.10.0
component: labkit_EIS_app | 1.12.1 -> 1.13.0
component: labkit_VTResistance_app | 1.9.0 -> 1.10.0
component: labkit_Mark10Monitor_app | 2.3.1 -> 2.4.0
component: labkit_GaitAnalysis_app | 3.1.0 -> 3.2.0
component: labkit_BatchImageCrop_app | 1.11.0 -> 1.12.0
component: labkit_CurvatureMeasurement_app | 1.8.0 -> 1.9.0
component: labkit_FLIRThermal_app | 1.8.0 -> 1.9.0
component: labkit_FocusStack_app | 1.10.0 -> 1.11.0
component: labkit_ImageEnhance_app | 1.10.0 -> 1.11.0
component: labkit_ImageMatch_app | 1.10.0 -> 1.11.0
component: labkit_ROIAnalyzer_app | 1.2.0 -> 1.3.0
component: labkit_VideoMarker_app | 1.10.0 -> 1.11.0
component: labkit_FigureStudio_app | 0.11.0 -> 0.12.0
component: labkit_NerveResponseAnalysis_app | 1.8.0 -> 1.9.0
component: labkit_ResponseReviewStats_app | 1.8.0 -> 1.9.0
component: labkit_RHSPreview_app | 1.8.0 -> 1.9.0
component: labkit_TTestWizard_app | 1.6.0 -> 1.7.0
component: labkit_ECGPrint_app | 4.2.0 -> 4.3.0
component: labkit_EMGReview_app | 1.1.0 -> 1.2.0
```

## Why

Input, review and export controls could occur far from the data or decision they affected. Short readouts could scroll or reserve large blank areas.

## What changed

The App control panes group related steps for acquisition, analysis, inspection and export. For example, Mark-10 separates recording review, reference setup and fit/export. Native status panels wrap selectable text at a consistent body size and grow with their content up to a scrollable limit.

## Impact

See the control-pane sequence in each App guide. Read the status next to the operation that produced it.

## Compatibility and limits

The layout changes preserve existing scientific settings, saved data and export formats.

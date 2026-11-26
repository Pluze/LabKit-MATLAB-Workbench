# Navigate App workflows and result views from the native workbench

```labkit-change
id: CHG-20261125-native-workbench-navigation
date: 2026-11-25
type: feat
compatibility: compatible
component: labkit.app | 3.6.2 -> 3.7.0
component: labkit_launcher | 2.1.0 -> 2.2.0
component: labkit_DICPostprocess_app | 1.7.4 -> 1.8.0
component: labkit_DICPreprocess_app | 1.8.3 -> 1.9.0
component: labkit_NIDMMRecorder_app | 1.1.1 -> 1.2.0
component: labkit_ChronoOverlay_app | 1.7.3 -> 1.8.0
component: labkit_CIC_app | 1.7.3 -> 1.8.0
component: labkit_CSC_app | 1.7.3 -> 1.8.0
component: labkit_EIS_app | 1.11.0 -> 1.12.0
component: labkit_VTResistance_app | 1.7.2 -> 1.8.0
component: labkit_Mark10Monitor_app | 2.2.0 -> 2.3.0
component: labkit_GaitAnalysis_app | 3.0.5 -> 3.1.0
component: labkit_BatchImageCrop_app | 1.10.5 -> 1.11.0
component: labkit_CurvatureMeasurement_app | 1.7.4 -> 1.8.0
component: labkit_FLIRThermal_app | 1.7.4 -> 1.8.0
component: labkit_FocusStack_app | 1.9.2 -> 1.10.0
component: labkit_ImageEnhance_app | 1.9.4 -> 1.10.0
component: labkit_ImageMatch_app | 1.9.3 -> 1.10.0
component: labkit_ROIAnalyzer_app | 1.1.2 -> 1.2.0
component: labkit_VideoMarker_app | 1.9.2 -> 1.10.0
component: labkit_FigureStudio_app | 0.10.3 -> 0.11.0
component: labkit_NerveResponseAnalysis_app | 1.7.3 -> 1.8.0
component: labkit_ResponseReviewStats_app | 1.7.3 -> 1.8.0
component: labkit_RHSPreview_app | 1.7.3 -> 1.8.0
component: labkit_TTestWizard_app | 1.5.2 -> 1.6.0
component: labkit_ECGPrint_app | 4.1.0 -> 4.2.0
component: labkit_EMGReview_app | 1.0.1 -> 1.1.0
```

## Why

Long control lists placed frequently used actions alongside setup and diagnostic controls. Users needed to leave the current task to find related results or exports.

## What changed

Apps organize controls into task pages in a light left pane. Result views have a separate header navigator that adapts to the available width. Apps can place a primary action in the header. The launcher uses a searchable catalog, selection actions and a copyable activity log. A perspective LK mark identifies the launcher, Apps and documentation.

## Impact

Operators can switch tasks and inspect result views independently. App-specific guides identify the available pages and the location of primary actions. The launcher groups maintenance, version selection and logs under Workbench tools.

## Compatibility and limits

The navigation operates on existing App callbacks, results and saved-data formats. Apps using header actions require the updated App SDK. Hardware acquisition continues to require explicit operator actions.

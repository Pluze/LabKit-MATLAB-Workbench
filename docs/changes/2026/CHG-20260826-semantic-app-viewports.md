# App plot viewports follow workflow domains

```labkit-change
id: CHG-20260826-semantic-app-viewports
date: 2026-08-26
type: fix
compatibility: compatible
component: labkit_DICPostprocess_app | 1.7.1 -> 1.7.2
component: labkit_DICPreprocess_app | 1.8.1 -> 1.8.2
component: labkit_GaitAnalysis_app | 3.0.0 -> 3.0.1
component: labkit_BatchImageCrop_app | 1.10.1 -> 1.10.2
component: labkit_CurvatureMeasurement_app | 1.7.1 -> 1.7.2
component: labkit_FLIRThermal_app | 1.7.1 -> 1.7.2
component: labkit_FocusStack_app | 1.8.0 -> 1.8.1
component: labkit_ImageEnhance_app | 1.9.0 -> 1.9.1
component: labkit_ImageMatch_app | 1.9.0 -> 1.9.1
component: labkit_VideoMarker_app | 1.8.1 -> 1.8.2
component: labkit_FigureStudio_app | 0.8.0 -> 0.8.1
component: labkit_NerveResponseAnalysis_app | 1.7.0 -> 1.7.1
component: labkit_ResponseReviewStats_app | 1.7.0 -> 1.7.1
component: labkit_RHSPreview_app | 1.7.1 -> 1.7.2
component: labkit_TTestWizard_app | 1.4.0 -> 1.4.1
component: labkit_ECGPrint_app | 2.1.0 -> 2.1.1
```

## Why

Several App plots redrew new sources, results, coordinate selections, or image canvases without identifying that their data domain had changed. The shared plot runtime then restored a manual zoom from the preceding domain, which could hide the new result. Other plots used an overly broad revision and reset zoom for styling, annotation, or same-domain editing, interrupting the user's inspection workflow.

### Accepted choice

Let each App define viewport identity from the smallest stable facts that change its plotted coordinate domain: semantic source IDs, result generations, selected coordinates or view modes, units/ranges, and displayed canvas geometry. Keep style, palette, grid, legend, annotation, ROI, and same-size frame or pixel redraws outside that identity. Keep explicit fit/reset actions as deliberate revision events.

A universal hash of complete plot models was rejected because it would treat ordinary pixel and presentation changes as new coordinate domains. A global revision on every state refresh was rejected because state refresh and viewport invalidation have different user meanings.

## What changed

- Refit image previews for new semantic sources, transformed or differently sized canvases, result generations, and preview compositions while preserving zoom through overlays, ROI edits, markers, palettes, and same-canvas processing.
- Refit ECG, gait, neurophysiology, and statistical plots for new accepted results, channels, selected windows/steps, or coordinate view modes while preserving zoom through unrelated presentation refreshes.
- Narrow Figure Studio viewport invalidation to source, panel, coordinate range/scale/direction, and explicit limit fitting; typography, ticks, layers, legends, color presentation, and annotation edits now preserve the inspected region.
- Keep existing live-stream and already-semantic App rules intact, including out-of-view refitting for Mark-10 monitoring and source/unit/coordinate revisions for electrochemistry plots.

## Impact

New data domains appear inside fitted axes without requiring a manual reset or App restart. Users can zoom into a current source or result and continue styling, annotating, measuring, navigating same-size frames, or refreshing presentation details without losing that context.

## Compatibility and limits

Scientific calculations, defaults, source formats, saved task data, result schemas, and exports are unchanged. App versions advance by compatible patches; no saved-data migration is required.

### Remaining limits

Automatic fitting exposes the plotted domain but does not assess scientific validity or visual quality. Live streams retain their App-owned rolling/out-of-view behavior rather than fitting every sample, and users can still request an explicit fit through the plot tools where available.

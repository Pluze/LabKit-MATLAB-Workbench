# Reviewable image batches, predictions, and diagnostic plots

```labkit-change
id: CHG-20260905-reviewable-app-results
date: 2026-09-05
type: feat
compatibility: compatible
component: labkit_ROIAnalyzer_app | 1.0.0 -> 1.1.0
component: labkit_FocusStack_app | 1.8.1 -> 1.9.0
component: labkit_VideoMarker_app | 1.8.2 -> 1.9.0
component: labkit_EIS_app | 1.7.1 -> 1.8.0
```

## Why

Existing ROI layouts, focus confidence, predicted annotations, and impedance columns contain useful results that were difficult to inspect together. The accepted change exposes those existing calculations through explicit batch and review actions. New scientific models, automatic data rejection, and cross-frequency interpolation would require separate contracts and are not prerequisites for these workflows.

Video frame navigation also performed prediction while advancing through intermediate frames. Separating inspection from explicit range prediction prevents a review action from changing the annotations being reviewed. These workflows stay with their owning Apps instead of introducing a generic framework task or analysis API.

## What changed

- [ROI Analyzer](../../use/apps/image-measurement/roi-analyzer/README.md) measures every configured image, reports per-image completeness, and exports ROI/channel rows with explicit failures and geometry-adjustment flags. Each batch replaces previous results, including failed entries. Preview and result invalidation helpers accept only their required state slices.
- [Focus Stack](../../use/apps/image-measurement/focus-stack/README.md) displays the existing confidence matrix beside the fused image and focus index with a fixed 0–1 scale. Grayscale output is rendered independently of the quality colormaps.
- [Video Marker](../../use/apps/image-measurement/video-marker/README.md) navigates without mutating annotations and provides explicit range prediction, review filters, directional matching, and frame completion counts. Prediction preserves manual anchors and reports progress through Diagnostics.
- [EIS](../../use/apps/electrochemistry/eis/README.md) opens a simultaneous Nyquist, magnitude, and phase overview while retaining the custom plot and its CSV. Invalid plot coordinates break lines rather than connecting across missing samples. Each source retains its own frequency grid.

## Impact

Users can inspect incomplete image batches, uncertain fusion areas, prediction drafts, and impedance relationships before exporting results. Explicit range prediction replaces the former forward-navigation trigger; the slider and previous/next controls are now safe inspection actions. Source-specific failures and progress remain observable without copying runtime objects or image caches into project files.

## Compatibility and limits

Entrypoints, scientific calculations, existing coordinate/measurement exports, and current project formats remain supported. ROI projects optionally retain validated batch-status metadata; projects without that field still open. ROI geometry and ratio changes invalidate the affected saved results. External source-pixel changes require a new measurement run.

Review controls are transient and do not promote predictions to confirmed data. Confidence is not a probability, the focus index is not physical height, and EIS overlays do not imply matched frequency samples. Batch measurement and range prediction remain synchronous, with progress at image/frame boundaries. Native pointer interaction and suitability for real laboratory data require representative manual review.

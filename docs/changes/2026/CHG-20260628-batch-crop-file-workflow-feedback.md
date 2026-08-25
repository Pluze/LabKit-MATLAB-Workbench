# Batch Crop file workflow feedback

```labkit-change
id: CHG-20260628-batch-crop-file-workflow-feedback
date: 2026-06-28
type: feat
compatibility: compatible
component: labkit.ui | 3.0.1 -> 3.1.0
component: labkit_BatchImageCrop_app | 1.2.0 -> 1.3.0
```

## Why

In a multi-file Batch Crop session, the window and preview did not consistently show which list item supplied the current image and crop settings.

### Accepted choice

Make the selected file part of the shared window-title context and update Batch Crop feedback whenever selection changes. Keep the title derived from the file panel so the app does not maintain a second selection label.

## What changed

- Batch Crop `1.2.0 -> 1.3.0`

- Added selected-file title context.
- Improved Batch Crop file workflow feedback.

## Impact

The active filename became visible while reviewing or editing a crop task, reducing the chance of applying settings to the wrong image. Crop geometry and exported data were unchanged.

## Compatibility and limits

Batch Crop tasks and exports kept their existing format. The change affected file-selection context and feedback in the window only.

### Remaining limits

Later file-panel work extended the same title context and append behavior to the rest of the app fleet.

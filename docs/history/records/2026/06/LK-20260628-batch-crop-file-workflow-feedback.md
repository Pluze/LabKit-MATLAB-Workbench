# Batch Crop file workflow feedback

```labkit-change
schema: 1
id: LK-20260628-batch-crop-file-workflow-feedback
date: 2026-06-28
type: feat
compatibility: compatible
component: `labkit.ui` | `3.0.1 -> 3.1.0`
component: `labkit_BatchImageCrop_app` | `1.2.0 -> 1.3.0`
```

## Context

In a multi-file Batch Crop session, the window and preview did not consistently
show which list item supplied the current image and crop settings.

## Decision and rationale

Make the selected file part of the shared window-title context and update Batch
Crop feedback whenever selection changes. Keep the title derived from the file
panel so the app does not maintain a second selection label.

## Changes

- `labkit.ui` `3.0.1 -> 3.1.0`
- Batch Crop `1.2.0 -> 1.3.0`

- Added selected-file title context.
- Improved Batch Crop file workflow feedback.

## User and data impact

The active filename became visible while reviewing or editing a crop task,
reducing the chance of applying settings to the wrong image. Crop geometry and
exported data were unchanged.

## Compatibility and migration

No manual migration was recorded for this historical change.

## Validation

The carrying commit updated shared title-context and Batch Crop GUI workflow
coverage. The exact historical test command was not recorded.

## Evidence

- Main commit `61e8edd3`.

## Known limitations and follow-up

Later file-panel work extended the same title context and append behavior to
the rest of the app fleet.

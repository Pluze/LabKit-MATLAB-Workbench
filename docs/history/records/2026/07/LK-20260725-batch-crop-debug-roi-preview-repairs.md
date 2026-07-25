# Batch Crop repairs debug launch, ROI movement, and ordinary-image preview

```labkit-change
id: LK-20260725-batch-crop-debug-roi-preview-repairs
date: 2026-07-25
sequence: 159
type: fix
compatibility: compatible
component: `labkit_BatchImageCrop_app` | `1.8.1 -> 1.8.2`
scope: Image Measurement
scope: Batch Crop
```

## Context

Batch Crop's synthetic debug sample contained source records without matching
crop tasks, so the App runtime rejected it as an invalid current project. Its
visible crop rectangle was display-only, despite the workflow requiring an ROI
drag to update the selected task. The preview canvas also used an unnecessarily
low budget for ordinary microscope images.

## Decision and rationale

Create debug crop tasks through the app-owned task factory, bind the crop ROI
to the existing managed rectangle interaction, and map its canvas translation
back to the durable source-image center. Retain native preview pixels through
12 megapixels; only larger inputs are sampled for interaction responsiveness.

## Changes

- Created matching crop tasks in the Batch Crop synthetic debug project.
- Replaced the display-only crop outline with a managed, draggable ROI.
- Kept ordinary images at native preview resolution through the revised budget
  and added targeted regression specifications.

## User and data impact

Debug launch now opens a valid synthetic project. Dragging the highlighted ROI
updates the selected crop center while preserving the viewport. Ordinary images
retain native preview resolution, while exports remain original-resolution.
Saved-project data remains compatible.

## Compatibility and migration

The saved-project schema, crop geometry, output files, and export behavior are
unchanged. Existing projects load without migration.

## Validation

- Batch Crop crop-geometry source contract, including native-preview and ROI
  movement regressions.
- Batch Crop debug-sample source contract.
- Synthetic-project runtime audit across all 21 public Apps.

## Evidence

- [Batch Image Crop](../../../../apps/image-measurement/batch-crop/README.md)
- [Testing](../../../../development/maintain-and-release/testing.md)

## Known limitations and follow-up

The automated checks do not replace a manual assessment of native ROI pointer
feel and visual placement on representative laboratory images.

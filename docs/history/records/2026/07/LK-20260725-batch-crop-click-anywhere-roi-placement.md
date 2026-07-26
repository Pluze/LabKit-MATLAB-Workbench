# Batch Crop places its ROI center from any preview click

```labkit-change
id: LK-20260725-batch-crop-click-anywhere-roi-placement
date: 2026-07-25
sequence: 166
type: fix
compatibility: compatible
component: `labkit.app` | `1.2.5 -> 1.2.6`
component: `labkit_BatchImageCrop_app` | `1.8.4 -> 1.8.5`
scope: App Framework
scope: Batch Crop
```

## Context

Batch Crop delegated blank-preview clicks to its crop-center placement callback,
but a click inside the managed crop rectangle was treated only as the start of
a drag. A user could therefore not place the center at an arbitrary point that
was already covered by the ROI.

## Decision and rationale

Keep one managed rectangle as the sole owner of the overlapping placement and
movement gestures. The private rectangle editor now distinguishes an
un-dragged click from an actual drag: its existing point callback receives the
click location, while its normal change callback continues to receive moved
rectangle positions. This is a domain-neutral interaction correction and does
not add an App SDK API.

## Changes

- Route a managed rectangle click without movement to its existing
  `OnBackgroundPressed` callback, including clicks within the rectangle.
- Retain the rectangle change callback for movement gestures.
- Update Batch Crop guidance and its manual to describe click-to-place and
  drag-to-move behavior.

## User and data impact

Users can click anywhere in the Batch Crop preview to set the crop center and
drag the ROI to translate it. Existing crop geometry, saved projects, and
exported pixels remain unchanged.

## Compatibility and migration

The public App SDK API shape and Batch Crop saved-project schema are
unchanged. Existing calls using `OnBackgroundPressed` gain the consistent
un-dragged rectangle-click behavior.

## Validation

- Batch Crop crop-geometry source contract verifies canvas clicks map to the
  durable source-image center and ROI drags translate that center.
- Framework and documentation checks remain required before integration.

## Evidence

- [Batch Image Crop](../../../../apps/image-measurement/batch-crop/README.md)
- [App SDK](../../../../framework/README.md)
- [Testing](../../../../development/maintain-and-release/testing.md)

## Known limitations and follow-up

Automated tests cannot replace developer-led assessment of native MATLAB
pointer feel and visual affordances on representative images.

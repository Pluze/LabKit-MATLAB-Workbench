# Batch Crop ROI accepts center-marker and body dragging

```labkit-change
id: LK-20260725-batch-crop-roi-body-drag
date: 2026-07-25
sequence: 161
type: fix
compatibility: compatible
component: `labkit_BatchImageCrop_app` | `1.8.3 -> 1.8.4`
component: `labkit.image` | `2.0.2 -> 2.0.3`
scope: Image Measurement
scope: Batch Crop
```

## Context

The persistent Batch Crop ROI could only begin a drag when the pointer landed
on its thin outline. The center indicator and the visible interior both hit the
underlying image, so ordinary center or body drags were interpreted as a
background click instead of a move. Batch Crop also inherited a generic image
preview budget after setting its own canvas budget, causing a second unintended
sampling pass.

## Decision and rationale

The private managed rectangle editor now accepts a pointer inside its current
position as a move gesture. Batch Crop presents a FLIR-style hollow center
marker and concise ROI guidance, while retaining the app-owned fixed crop size.
The image facade now preserves native pixels by default; Apps explicitly own
any finite preview budget. Batch Crop applies its sole 12 MP budget while
building the padded rotation canvas and renders that canvas without resampling.

## Changes

- Made managed rectangles draggable from their interior as well as their edge.
- Added a visible Batch Crop center marker and ROI guidance.
- Added a renderer regression specification for both drag affordances.
- Removed the implicit second Batch Crop preview budget and made the image
  facade's default preview budget unlimited.

## User and data impact

Users can drag either the crop-center marker or any point within the crop box
to translate the fixed-size crop. Clicking outside the box still repositions
its center. Ordinary Batch Crop images retain their app-selected canvas
resolution. Saved projects and exported image pixels are unchanged.

## Compatibility and migration

The saved-project schema and public App APIs are unchanged.

## Validation

- Batch Crop crop-preview source contract.
- Batch Crop crop-geometry source contract.
- Framework App SDK and image-facade source contracts.

## Evidence

- [Batch Image Crop](../../../../apps/image-measurement/batch-crop/README.md)
- [Testing](../../../../development/maintain-and-release/testing.md)

## Known limitations and follow-up

Hidden-GUI evidence cannot replace an interactive native MATLAB pointer check
of drag feel and overlay placement.

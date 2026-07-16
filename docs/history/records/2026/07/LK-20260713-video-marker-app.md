# Video Marker app

```labkit-change
schema: 2
id: LK-20260713-video-marker-app
date: 2026-07-13
sequence: 54
type: feat
compatibility: additive
introduced: `labkit_VideoMarker_app` | `1.0.0`
```

## Context

Image measurement workflows needed a generic video annotation tool for ordered
2D keypoints and skeleton connections. The app belongs with image measurement
tools because it uses the same axes interaction, scale calibration, and export
style, but the source media and frame navigation are video-specific.

## Decision and rationale

Add a standalone Video Marker app instead of extending an existing image-only
app or adding a public video facade. The first version keeps marker semantics
app-local, uses existing UI interaction tools for ordered points and scale
calibration, and avoids training, inference, multi-subject tracking, or
per-point missing-state semantics.

## Changes

- Added `labkit_VideoMarker_app` under Image Measurement with video loading,
  indexed frame navigation, ordered keypoint placement, skeleton overlays, and
  previous-confirmed-frame inheritance as draft annotations.
- Added a self-describing marker CSV that stores pixel coordinates for every
  frame and can be imported back into the app for overlay or editing.
- Added a separate coordinate CSV export for continuous confirmed frame ranges,
  with selectable pixel or calibrated units, top-left or first-point origin,
  and up/down Y-axis convention.
- Added project MAT save/load and debug sample-pack coverage for synthetic
  video marker assets.

## User and data impact

Users can manually annotate video frames without depending on a model-training
workflow. Marker CSV remains the editable round-trip format; coordinate CSV is
plain plotting data and does not mutate the saved marker annotations.

## Compatibility and migration

The app is additive and does not change existing image measurement apps or
public LabKit facades. No existing project files or exports require migration.

## Validation

`VideoMarkerTest` covers skeleton parsing, frame inheritance, marker CSV
round trip, coordinate transforms, and project save/load. `GuiLayoutVideoMarkerTest`
covers the hidden GUI launch and semantic control contract. Both accompanied
the app in commit `b41f5254`.

## Evidence

- Initial Video Marker app `b41f5254`.

## Known limitations and follow-up

The first version is manual and single-subject. It intentionally does not
perform automatic interpolation, optical flow, model inference, multi-camera
synchronization, 3D annotation, or per-point missing/out-of-frame labeling.

# Gait trajectory image-coordinate preview

```labkit-change
id: LK-20260716-gait-image-coordinates
date: 2026-07-16
sequence: 67
type: fix
compatibility: compatible
component: `labkit_GaitAnalysis_app` | `1.1.0 -> 1.1.1`
scope: trajectory preview
```

## Context

Marker coordinates use the image convention with an upper-left origin and Y
increasing downward. Gait Analysis plotted those values on MATLAB's default
Cartesian axes, so the trajectory preview appeared vertically flipped relative
to the source video.

## Decision and rationale

Preserve the imported coordinate values and scientific calculations. Reverse
only the trajectory preview's Y axis so its visual orientation matches Video
Marker and Image Marker. Time-series angle and step plots explicitly retain
the conventional upward Y direction.

## Changes

- Render trajectory previews with a reversed Y axis.
- Restore the normal Y direction when switching to Angles or Steps.
- Document the preview coordinate convention.

## User and data impact

Tracked motion now appears in the same orientation as the source image. Stored
coordinates, calculations, tables, and exports are unchanged.

## Compatibility and migration

The change is display-only and requires no project or data migration.

## Validation

The hidden Gait Analysis workflow test checks both trajectory and time-series
axis directions while exercising source load and analysis.

## Evidence

- [Gait Analysis](../../../../apps/gait/gait-analysis/README.md) documents the
  image-coordinate preview convention.

## Known limitations and follow-up

The preview assumes imported marker coordinates follow the documented image
coordinate convention. Generic coordinate files with a Cartesian convention
must be converted by their producer before import.

# Gait trajectory image-coordinate preview

```labkit-change
id: CHG-20260716-gait-image-coordinates
date: 2026-07-16
type: fix
compatibility: compatible
component: labkit_GaitAnalysis_app | 1.1.0 -> 1.1.1
```

## Why

Marker coordinates use the image convention with an upper-left origin and Y increasing downward. Gait Analysis plotted those values on MATLAB's default Cartesian axes, so the trajectory preview appeared vertically flipped relative to the source video.

### Accepted choice

Preserve the imported coordinate values and scientific calculations. Reverse only the trajectory preview's Y axis so its visual orientation matches Video Marker and Image Marker. Time-series angle and step plots explicitly retain the conventional upward Y direction.

## What changed

- Render trajectory previews with a reversed Y axis.
- Restore the normal Y direction when switching to Angles or Steps.
- Document the preview coordinate convention.

## Impact

Tracked motion now appears in the same orientation as the source image. Stored coordinates, calculations, tables, and exports are unchanged.

## Compatibility and limits

The change is display-only and requires no project or data migration.

### Remaining limits

The preview assumes imported marker coordinates follow the documented image coordinate convention. Generic coordinate files with a Cartesian convention must be converted by their producer before import.

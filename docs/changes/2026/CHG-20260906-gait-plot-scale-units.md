# Gait spatial plots use the selected scale

```labkit-change
id: CHG-20260906-gait-plot-scale-units
date: 2026-09-06
type: fix
compatibility: compatible
component: labkit_GaitAnalysis_app | 3.0.2 -> 3.0.3
```

## Why

Gait Analysis converted lengths, coordinates, tables, and CSV outputs with the configured pixels-per-unit value, but its two spatial plots continued to draw raw pixel coordinates and label both axes as pixels. The plot therefore disagreed with the selected physical unit even though the analysis result was scaled correctly.

### Accepted choice

Apply the current pixels-per-unit calibration to both spatial plot coordinate sets and label their axes with the selected unit. Preserve the source image origin, downward-positive Y direction, equal X/Y data units, analysis formulas, and exported values.

## What changed

- The selected-step skeleton and full-recording overview now divide source pixel coordinates by the current pixels-per-unit value.
- Both spatial plots show the configured unit in their X and Y axis labels.
- Scale changes continue to request one fresh viewport fit.

## Impact

Spatial plots now agree with the configured physical coordinate scale. Angle and segment-length time series, result tables, and CSV files are unchanged.

## Compatibility and limits

Existing Video Marker archives and Gait Analysis inputs require no migration. The spatial plots retain the image coordinate origin; enabling the first-frame origin option continues to affect scaled coordinate exports only.

### Remaining limits

Hidden-graphics validation checks converted plot data, labels, visibility, and equal data units. Readability with dense real recordings remains a manual review boundary.

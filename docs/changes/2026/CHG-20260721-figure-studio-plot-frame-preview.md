# Figure Studio fixes publication-frame preview and axis controls

```labkit-change
id: CHG-20260721-figure-studio-plot-frame-preview
date: 2026-07-21
type: fix
compatibility: compatible
component: labkit_FigureStudio_app | 0.6.0 -> 0.6.1
```

## Why

Figure Studio had treated a requested output size as a whole figure canvas. That made labels and titles consume the configured plot area, and resizing the preview could make the displayed typography unrelated to the eventual export. Copied UIAxes also needed a portable reconstruction path for reliable export.

### Accepted choice

Treat the requested width and aspect as the inner axes frame. Keep all publication-style calibration within Figure Studio, then calculate an outer figure from the live rendered text extents so visual styling cannot reduce the configured data area.

## What changed

- Defined the plot width and aspect controls as the inner axes frame; export now calculates an outer figure around that fixed frame from visible labels, ticks, titles, legends, and annotations.
- Calibrated the LabKit publication preset from the maintained single-panel visual measurements, including category-specific typography and strokes.
- Kept the preview as an interactive axes, reflowing its display scale when its allocated area changes without changing saved/export settings.
- Added explicit X/Y minimum and maximum controls, plus visible-data recalculation with a finite-data envelope expanded by 50 percent.
- Rebuilt UIAxes sources through the portable renderer for conventional export, retaining displayed scientific axis exponents.

## Impact

Existing Figure Studio projects remain compatible. Existing style sizes retain their meaning as a plot frame; the enclosing export figure may grow to avoid clipping external text. No scientific calculations or source figure data are changed.

## Compatibility and limits

The project schema migrates existing style records without changing their stored data. UIAxes exports use the portable display snapshot only for the screen-specific aspect geometry that cannot be transferred to normal axes.

### Remaining limits

Manual review remains appropriate for native MATLAB graphics that cannot be represented by the portable package.

# Preview-area per-axis wheel zoom

```labkit-change
id: CHG-20260709-preview-area-per-axis-wheel-zoom
date: 2026-07-09
type: feat
compatibility: compatible
component: labkit.ui | 5.0.3 -> 5.0.4
```

## Why

The preview area applied the same two-dimensional wheel zoom to every registered axes. That was appropriate for an image or main plot, but awkward for a narrow histogram or color-scale axes: horizontal zoom changed a dimension whose layout was meant to remain fixed.

### Accepted choice

Let a preview-area definition choose `xy`, `x`, or `y` wheel zoom for each axes. Preserve `xy` as the default so existing apps keep their behavior, while side axes can opt into only the dimension that carries data.

## What changed

- Added a `scrollZoomAxes` preview-area layout option so apps can declare whether each preview axis should mouse-wheel zoom in `xy`, `x`, or `y`.
- Preview-area side axes can now remain horizontally stable while still allowing app-selected vertical wheel zoom.

## Impact

A histogram or temperature scale could remain horizontally stable while still supporting vertical exploration. Main images and plots continued to zoom in both dimensions unless their app explicitly chose another mode.

## Compatibility and limits

- Existing preview areas keep default `xy` wheel zoom unless they opt into another per-axis setting.

### Remaining limits

The option controlled wheel navigation only. Toolbar zoom, pan, linked axes, and app-specific limit policies remained separate concerns.

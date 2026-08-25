# Figure Studio derives its publication preset from the nine-panel reference

```labkit-change
id: CHG-20260721-figure-studio-nine-panel-calibration
date: 2026-07-21
type: fix
compatibility: compatible
component: labkit_FigureStudio_app | 0.6.1 -> 0.6.4
```

## Why

The previous Figure Studio publication profile was described as a visual calibration even though its dimensions had been taken from a separate manual FIG example. It also allowed native figure chrome to reduce the exported drawable height.

### Accepted choice

Use only the maintained 3-by-3 scientific reference. Normalize every panel by its detected axes frame, measure typography and strokes in pixels, and select one robust profile from all nine panels. Keep those measurements app-local and size the chromeless export client area directly so the configured inner frame survives raster and vector export.

## What changed

- Recalibrated the reference plot frame, typography, semantic strokes, frame, grid, legend border, and legend token length from panels A through I.
- Set the data stroke to 6.5 pt after registered raster checks matched panel A exactly and reduced the remaining one-pixel deficits in panels E and H.
- Removed menu and toolbar chrome from temporary export figures and preserved the complete figure bounds through `exportgraphics`.
- Ignored zero-area text extents when computing outer margins so native log rulers cannot inflate an export canvas to tens of thousands of pixels.
- Added the calibrated 900 px plot width to the selectable sizes and made it the new-project default.
- Retained source token geometry for **FIG default** while applying the measured long token only to the LabKit preset.
- Replaced dynamic-array analyzer suppressions with bounded collection and documented the 72-to-96-PPI range used by cross-platform visual metrics.

## Impact

New LabKit-style projects open at the nine-panel reference scale. Existing scientific values, limits, source graphics, FIG files, and saved projects are not recalculated. Exports retain the requested inner-frame aspect instead of losing native-window height.

## Compatibility and limits

The style record remains extensible and existing projects stay readable. Switching an existing document to **LabKit figure** opts into the new profile; **FIG default** continues to use source presentation values.

### Remaining limits

Raster antialiasing varies slightly by renderer and platform. Exact scientific curve coordinates are source data and are not part of the style preset.

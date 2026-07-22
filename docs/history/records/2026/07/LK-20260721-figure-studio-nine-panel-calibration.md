# Figure Studio derives its publication preset from the nine-panel reference

```labkit-change
id: LK-20260721-figure-studio-nine-panel-calibration
date: 2026-07-21
sequence: 155
type: fix
compatibility: compatible
component: `labkit_FigureStudio_app` | `0.6.1 -> 0.6.3`
scope: LabKit Core
```

## Context

The previous Figure Studio publication profile was described as a visual
calibration even though its dimensions had been taken from a separate manual
FIG example. It also allowed native figure chrome to reduce the exported
drawable height.

## Decision and rationale

Use only the maintained 3-by-3 scientific reference. Normalize every panel by
its detected axes frame, measure typography and strokes in pixels, and select
one robust profile from all nine panels. Keep those measurements app-local and
size the chromeless export client area directly so the configured inner frame
survives raster and vector export.

## Changes

- Recalibrated the reference plot frame, typography, semantic strokes, frame,
  grid, legend border, and legend token length from panels A through I.
- Removed menu and toolbar chrome from temporary export figures and preserved
  the complete figure bounds through `exportgraphics`.
- Ignored zero-area text extents when computing outer margins so native log
  rulers cannot inflate an export canvas to tens of thousands of pixels.
- Added the calibrated 900 px plot width to the selectable sizes and made it
  the new-project default.
- Retained source token geometry for **FIG default** while applying the
  measured long token only to the LabKit preset.
- Replaced dynamic-array analyzer suppressions with bounded collection and
  documented the 72-to-96-PPI range used by cross-platform visual metrics.

## User and data impact

New LabKit-style projects open at the nine-panel reference scale. Existing
scientific values, limits, source graphics, FIG files, and saved projects are
not recalculated. Exports retain the requested inner-frame aspect instead of
losing native-window height.

## Compatibility and migration

The style record remains extensible and existing projects stay readable.
Switching an existing document to **LabKit figure** opts into the new profile;
**FIG default** continues to use source presentation values.

## Validation

- Pixel-frame, OCR glyph-height, colored-stroke, and registered-overlay checks
  against all nine reference panels.
- Focused Figure Studio result-file and project tests.
- Hidden-GUI Figure Studio workflow tests.
- Native logarithmic-axis margin regression.
- Linux-compatible visual-ratio and analyzer-policy regressions.
- Repository `changedFast` validation.

## Evidence

After width registration, the nine detected inner-frame height errors range
from -1.71 to +2.16 pixels; panel A is exact. Shared OCR glyph heights have a
median scale error below one percent. Reference and generated comparison
rasters remain untracked validation artifacts.

## Known limitations and follow-up

Raster antialiasing varies slightly by renderer and platform. Exact scientific
curve coordinates are source data and are not part of the style preset.

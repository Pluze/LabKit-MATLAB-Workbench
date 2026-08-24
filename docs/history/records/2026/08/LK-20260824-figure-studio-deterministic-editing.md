# Figure Studio gains deterministic axes editing

```labkit-change
id: LK-20260824-figure-studio-deterministic-editing
date: 2026-08-24
sequence: 193
type: feat
compatibility: compatible
component: `labkit_FigureStudio_app` | `0.7.5 -> 0.8.0`
scope: Deterministic figure styling and explicit axes editing
scope: Publication-oriented visual baseline
```

## Context

Figure Studio combined a large automatic visual transformation with a limited editor. Data-derived limit bounds prevented intentional empty ranges, some style changes did not refresh the preview, and preview and export could follow different reconstruction paths. Automatic recoloring, bar-fill replacement, hidden-line classification, and annotation movement also made authored presentation difficult to predict.

## Decision and rationale

Make explicit user state authoritative and keep automatic styling limited to stable presentation categories. A selected axes now has one source snapshot, explicit axes and style overrides, and one renderer for preview and export. Preserve the established nine-panel visual calibration as the authoritative default while keeping source data and authored object appearance unchanged.

## Changes

- Added direct editing for titles, axis labels, limits, scales, directions, and tick direction.
- Allowed any finite ascending axis range instead of applying a data-derived editing envelope.
- Made every style and axes edit advance the preview revision and routed preview and export through the same renderer.
- Renamed the standard preset to **Published figure** while retaining its measured 900-by-725 frame, typography, legend-token, and semantic-stroke calibration.
- Split the control panel into Figure, Appearance, Geometry, and Export workflows; replaced the fixed-width list with numeric frame dimensions and added explicit tight, balanced, and generous outside-whitespace choices.
- Removed low-value duplicate or incidental controls for all-font mirroring, grid alpha, export multiplication, axis placement, and independent minor ticks while preserving imported source metadata.
- Kept each preset's own reference frame during preset changes so an earlier source scale cannot silently restyle the next preset.
- Preserved the selected outside whitespace across preset changes and retained source TeX, LaTeX, or literal title and axis-label interpretation.
- Stopped automatic color-order replacement, bar recoloring or un-filling, hidden-line restyling, annotation movement, and limit expansion.

## User and data impact

Users can deliberately display empty regions, reverse axes, select logarithmic scales, edit plot text, set exact frame dimensions, and choose outside whitespace without changing the calculation. Existing colors, markers, line styles, bar fills, annotation coordinates, and explicit limits remain intact unless the corresponding control is changed. Projects still contain serializable plot and style state; no source laboratory files or reference screenshots are embedded.

## Compatibility and migration

The public launcher, FIG and UIAxes handoff paths, single-panel selection, portable data packages, and PNG, JPG, SVG, and FIG exports remain supported. No App-owned task archive or migration format is introduced. **Published figure** retains the established calibrated baseline; **FIG default** retains the source presentation.

## Validation

Focused source, result, workbench-presentation, and product contracts cover explicit ranges outside data, axes presentation, preview revision changes, authored object preservation, repeated-style idempotence, native preview/export parity, and handoff behavior. Documentation validation covers the current manual and structured record.

## Evidence

The retained visual baseline is supported by the earlier nine-panel axis-frame registration, OCR glyph-height, colored-stroke, and overlay evidence. Synthetic render evidence verifies that the deterministic renderer preserves that calibration and outer whitespace without retaining paper text, figures, filenames, or scientific data.

## Known limitations and follow-up

Figure Studio remains a single-axes editor and does not yet expose a universal property inspector for every MATLAB graphics class. Portable reconstruction remains narrower than native MATLAB graphics copying, so unsupported custom chart classes still require their source FIG as the authority.

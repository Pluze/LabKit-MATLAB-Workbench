# Plot inspection and responsive App updates

```labkit-change
id: CHG-20261019-plot-workspaces
date: 2026-10-19
type: feat
compatibility: compatible
component: labkit.app | 3.5.1 -> 3.6.0
component: labkit_EIS_app | 1.9.1 -> 1.10.0
component: labkit_Mark10Monitor_app | 2.0.0 -> 2.1.0
component: labkit_ECGPrint_app | 3.0.0 -> 3.0.1
component: labkit_VideoMarker_app | 1.9.1 -> 1.9.2
component: labkit_GaitAnalysis_app | 3.0.4 -> 3.0.5
component: labkit_FigureStudio_app | 0.10.2 -> 0.10.3
```

## Why

Low-frequency EIS tails can obscure the Nyquist semicircle, while stacked Mark-10 recording and analysis content leaves little room for fitted regions. Plot inspection also suffered from repeated SDK bookkeeping, plot models containing unrelated editing state, repeated ECG axis linking, and Video Marker preserving an unfinished automatic viewport.

## What changed

- Added logarithmic frequency controls directly left of EIS Nyquist, a current-range title, recommended and full-range actions, and coordinate reset. The display recommendation requires a resolved arc descent followed by a dominant low-frequency tail, with full-spectrum fallback when evidence is insufficient.
- Kept EIS overview legends compact and excluded hidden group uncertainty extents from fitting. Plot models contain their relevant display options, so group-name drafts and custom coordinate choices do not redraw unrelated overview plots.
- Gave Mark-10 modulus analysis the full workspace width with results below, retained analysis controls in the sidebar, and moved recording plots and time controls to Recording Review. Reset X/Y preserves fitted values.
- Extended SDK groups to combine controls, plots and tables with horizontal column widths, and added compact slider captions above the track. Standard axes toolbars are initialized once; snapshot composition and callback validation avoid repeated full scans and comparisons.
- Retained ECG time-axis linkage across redraws and restored independent raw-recording inspection when analysis is cleared. Video Marker uses the SDK viewport policy instead of freezing an unfinished automatic view.
- Kept Mark-10 pending zero inputs out of analysis plot models, isolated Gait Analysis detection drafts from display calibration, and kept Figure Studio object selection out of the rendered document. Editing controls no longer redraw unrelated plots.

## Impact

Users can inspect a chosen EIS frequency band while Bode retains the full spectrum, review larger Mark-10 stress–strain plots, and keep linked ECG and video inspection views consistent. See the [EIS](../../use/apps/electrochemistry/eis/README.md), [Mark-10](../../use/apps/force-gauges/mark10-monitor/README.md), [ECG Print](../../use/apps/wearable/ecg-print/README.md), and [Video Marker](../../use/apps/image-measurement/video-marker/README.md) manuals, and the [SDK layout contract](../../develop/framework/runtime.md).

[Gait Analysis](../../use/apps/gait/gait-analysis/README.md) preserves raw-pose inspection while detection settings are pending, and [Figure Studio](../../use/apps/labkit-core/figure-studio/README.md) keeps selection changes separate from figure styling.

## Compatibility and limits

EIS and Mark-10 require SDK 3.6 or newer within major version 3. Scientific formulas, imported measurements, group statistics, fitted results, saved-data formats, and numerical exports are unchanged. The EIS recommendation is a display heuristic, not a circuit fit or electrochemical identification; users can restore the full range. Each new Mark-10 monitoring run resets live views once, while subsequent in-range refreshes preserve manual zoom. Software validation does not establish hardware acquisition performance or native pointer feel.

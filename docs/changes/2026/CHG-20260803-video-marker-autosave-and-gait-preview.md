# Video Marker protects point edits and Gait keeps plots in view

```labkit-change
id: CHG-20260803-video-marker-autosave-and-gait-preview
date: 2026-08-03
type: fix
compatibility: compatible
component: labkit_VideoMarker_app | 1.7.1 -> 1.7.2
component: labkit_GaitAnalysis_app | 2.2.1 -> 2.2.2
```

## Why

Video Marker retained edited points in the live project but updated its visible source-adjacent autosave only when the user pressed **Save autosave**. Gait Analysis produced valid tables and plot children, yet reused the empty startup viewport after source load and analysis, placing real data outside the visible limits. Its selected-step skeleton also admitted unnamed connection lines into the legend and could stretch spatial geometry to fill the panel.

### Accepted choice

Write Video Marker's existing deterministic autosave after every committed point-information change, including manual edits, undo/clear, imported marker coordinates, and generated predictions. Keep the explicit action as a manual force-save path. In Gait, advance a transient plot-view revision whenever the source, result, or selected step changes so the renderer's new limits are accepted once and later user zoom remains stable. Compose two paired plot rows for a 2-by-2 preview, retain the selected-step plots, and add an equal-scale full-recording overlay. These remain App-owned workflow and presentation decisions; the shared fit helper only makes its existing equal-data-unit contract stable after release-specific axes layout changes.

## What changed

- Point edits and predicted/imported annotation changes atomically replace the fixed Video Marker autosave without opening a location dialog.
- Gait source load, analysis, option invalidation, and step navigation request one fresh data fit instead of preserving limits from a different model.
- The Gait workspace now shows selected-step skeletons and angles on the first row, segment lengths and the full-recording overlay on the second row.
- Selected-step and full-recording spatial plots use equal X/Y data units, and unnamed skeleton connections no longer appear as `dataN` legend entries.

## Impact

Committed marker coordinates have an immediately updated recovery document beside the source video. Autosave failures remain visible without discarding the in-memory edit. Gait calculations, units, result tables, saved projects, and CSV exports are unchanged; only plot organization, fitting, aspect, and legend contents change.

## Compatibility and limits

Existing Video Marker and Gait projects require no migration. The autosave path and MAT envelope are unchanged. The Gait preview adds one plot surface but does not change analysis or export schemas.

### Remaining limits

Hidden GUI checks prove native structure and data limits, not the visual feel of dense real recordings. Real-data readability and autosave latency remain manual review boundaries.

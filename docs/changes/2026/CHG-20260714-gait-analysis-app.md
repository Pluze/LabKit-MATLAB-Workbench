# Gait Analysis app

```labkit-change
id: CHG-20260714-gait-analysis-app
date: 2026-07-14
type: feat
compatibility: compatible
component: labkit_GaitAnalysis_app | new -> 1.0.0
```

## Why

Existing gait work used a script chain after pose tracking: import coordinates, smooth marker traces, make per-step figures, compute step and joint metrics, select useful steps, and export tables for downstream statistics. That work belongs in its own app family because the downstream task is not image annotation, signal import, or electrochemistry; it is gait-specific pose analysis from already tracked coordinates.

### Accepted choice

Add an independent Gait Analysis app instead of extending Video Marker or recreating a model-training workflow. The app accepts several coordinate-table shapes, keeps gait event detection and metric definitions app-local, and exports simple CSV tables that can be consumed by plotting or statistical programs.

## What changed

- Added `labkit_GaitAnalysis_app` under the new Gait family.
- Added CSV/TSV/TXT and MAT pose-coordinate import, including generic `point_x`/`point_y` and LabKit `point__x`/`point__y` column shapes.
- Added smoothing, foot-relative step-event detection, hip/knee/ankle angle calculation, segment lengths, per-step translations, stride length, step time, ROM, summary metrics, and trajectory/angle/step-event previews.
- Added CSV set export for frame metrics, step metrics, summary metrics, and per-frame coordinates that keep raw pixel columns alongside optional scale-calibrated and first-frame-origin-shifted columns.

## Impact

Users can analyze gait from multiple pose-coordinate sources without tying the workflow to a specific tracking model. The exported tables are plain CSV and separate frame-level, coordinate, step-level, and summary data for downstream overlay, plotting, or statistics.

## Compatibility and limits

The app is additive and does not change Video Marker, image measurement apps, public `+labkit` facades, or existing exports. Existing script outputs can be imported when they provide wide coordinate columns or MAT `coords` and `pointNames`.

### Remaining limits

The first version analyzes one tracked subject at a time and does not perform tracking, model training, group-level statistics, EMG/CAP synchronization, multi-limb phase analysis, or automatic step quality classification.

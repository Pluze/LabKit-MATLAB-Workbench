# Gait Analysis app

```labkit-change
schema: 2
id: LK-20260714-gait-analysis-app
date: 2026-07-14
sequence: 55
type: feat
compatibility: additive
introduced: `labkit_GaitAnalysis_app` | `1.0.0`
```

## Context

Existing gait work used a script chain after pose tracking: import coordinates,
smooth marker traces, make per-step figures, compute step and joint metrics,
select useful steps, and export tables for downstream statistics. That work
belongs in its own app family because the downstream task is not image
annotation, signal import, or electrochemistry; it is gait-specific pose
analysis from already tracked coordinates.

## Decision and rationale

Add an independent Gait Analysis app instead of extending Video Marker or
recreating a model-training workflow. The app accepts several coordinate-table
shapes, keeps gait event detection and metric definitions app-local, and
exports simple CSV tables that can be consumed by plotting or statistical
programs.

## Changes

- Added `labkit_GaitAnalysis_app` under the new Gait family.
- Added CSV/TSV/TXT and MAT pose-coordinate import, including generic
  `point_x`/`point_y` and LabKit `point__x`/`point__y` column shapes.
- Added smoothing, foot-relative step-event detection, hip/knee/ankle angle
  calculation, segment lengths, per-step translations, stride length, step
  time, ROM, summary metrics, and trajectory/angle/step-event previews.
- Added CSV set export for frame metrics, step metrics, summary metrics, and
  per-frame coordinates that keep raw pixel columns alongside optional
  scale-calibrated and first-frame-origin-shifted columns.

## User and data impact

Users can analyze gait from multiple pose-coordinate sources without tying the
workflow to a specific tracking model. The exported tables are plain CSV and
separate frame-level, coordinate, step-level, and summary data for downstream
overlay, plotting, or statistics.

## Compatibility and migration

The app is additive and does not change Video Marker, image measurement apps,
public `+labkit` facades, or existing exports. Existing script outputs can be
imported when they provide wide coordinate columns or MAT `coords` and
`pointNames`.

## Validation

`GaitAnalysisTest` covers coordinate import, synthetic step detection, metric
tables, MAT import, coordinate export calibration/origin semantics, coordinate
CSV readback, and CSV set export. `GuiLayoutGaitAnalysisTest` covers the hidden
GUI launch and semantic control contract. These tests were added with the app
in commit `49863964`.

## Evidence

- Initial Gait Analysis app `49863964`.

## Known limitations and follow-up

The first version analyzes one tracked subject at a time and does not perform
tracking, model training, group-level statistics, EMG/CAP synchronization,
multi-limb phase analysis, or automatic step quality classification.

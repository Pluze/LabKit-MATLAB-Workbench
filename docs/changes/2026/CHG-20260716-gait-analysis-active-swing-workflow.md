# Gait Analysis active-swing workflow

```labkit-change
id: CHG-20260716-gait-analysis-active-swing-workflow
date: 2026-07-16
type: feat
compatibility: breaking
component: labkit_GaitAnalysis_app | 1.1.1 -> 2.0.0
```

## Why

The migrated Gait app accepted loosely shaped coordinate files but did not recover the legacy workflow's step segmentation, per-step skeleton report, or complete translation and angle measurements. A coordinate file alone also could not prove its frame rate, skeleton order, or calibration.

### Accepted choice

Treat a current Video Marker payload-version-2 project or autosave as the sole file input. It is the first durable artifact that owns coordinates, timing, skeleton, calibration, and annotation provenance together. Segment the legacy treadmill active swing from a prominent foot-X maximum (lift-off) to the following minimum (landing), including a final completed swing that has no later lift-off.

## What changed

- Load only the named `labkitProject` variable and reject generic tables, arbitrary MAT variables, legacy marker payloads, and missing frame rate.
- Show all overlaid skeleton trajectories immediately after import.
- Detect active swings with app-owned prominence, peak-height, and temporal separation logic; compute cycle/stance measures when a following lift-off exists.
- Present one selected swing with connected landmarks, joint/segment traces, five endpoint translations, and joint minimum, maximum, and range of motion.
- Export per-frame, coordinate, step, summary, and provenance tables with lift-off/landing and `swing_time_s` terminology.
- Migrate version-1 Gait option names and invalidate its scientifically incompatible cached result.

## Impact

Users first inspect all trajectories, then run analysis and move between segmented swings. Existing Gait project settings are migrated, but old cached results are recalculated. Older or generic pose files must be converted by opening and saving the source in current Video Marker.

## Compatibility and limits

This is an intentional input and output-schema break. The durable project migration preserves equivalent thresholds while renaming stride/contact-era fields to active-swing terms. Video Marker project payload version 2 is required.

### Remaining limits

The detector represents image-kinematic treadmill events, not force-plate contact. Frame annotation status is preserved but is not yet an automatic step exclusion rule.

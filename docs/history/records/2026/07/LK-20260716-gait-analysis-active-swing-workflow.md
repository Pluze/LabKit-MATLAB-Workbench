# Gait Analysis active-swing workflow

```labkit-change
id: LK-20260716-gait-analysis-active-swing-workflow
date: 2026-07-16
sequence: 71
type: feat
compatibility: breaking
component: `labkit_GaitAnalysis_app` | `1.1.1 -> 2.0.0`
scope: Video Marker input contract
scope: treadmill swing segmentation
scope: gait visualization and exports
```

## Context

The migrated Gait app accepted loosely shaped coordinate files but did not
recover the legacy workflow's step segmentation, per-step skeleton report, or
complete translation and angle measurements. A coordinate file alone also
could not prove its frame rate, skeleton order, or calibration.

## Decision and rationale

Treat a current Video Marker payload-version-2 project or autosave as the sole
file input. It is the first durable artifact that owns coordinates, timing,
skeleton, calibration, and annotation provenance together. Segment the legacy
treadmill active swing from a prominent foot-X maximum (lift-off) to the
following minimum (landing), including a final completed swing that has no
later lift-off.

## Changes

- Load only the named `labkitProject` variable and reject generic tables,
  arbitrary MAT variables, legacy marker payloads, and missing frame rate.
- Show all overlaid skeleton trajectories immediately after import.
- Detect active swings with app-owned prominence, peak-height, and temporal
  separation logic; compute cycle/stance measures when a following lift-off
  exists.
- Present one selected swing with connected landmarks, joint/segment traces,
  five endpoint translations, and joint minimum, maximum, and range of motion.
- Export per-frame, coordinate, step, summary, and provenance tables with
  lift-off/landing and `swing_time_s` terminology.
- Migrate version-1 Gait option names and invalidate its scientifically
  incompatible cached result.

## User and data impact

Users first inspect all trajectories, then run analysis and move between
segmented swings. Existing Gait project settings are migrated, but old cached
results are recalculated. Older or generic pose files must be converted by
opening and saving the source in current Video Marker.

## Compatibility and migration

This is an intentional input and output-schema break. The durable project
migration preserves equivalent thresholds while renaming stride/contact-era
fields to active-swing terms. Video Marker project payload version 2 is
required.

## Validation

Focused unit tests cover source metadata recovery, rejection of incomplete and
legacy MAT files, lift-off/landing pairs, retention of the final completed
swing, migration of old option names, scientific table fields, and exports.
The focused GUI test covers trajectory orientation, analysis, step preview,
export, and project reopen.

## Evidence

- [Gait Analysis](../../../../apps/gait/gait-analysis/README.md) documents the
  source, calculation, visualization, and export contracts.
- [Video Marker](../../../../apps/image-measurement/video-marker/README.md)
  documents the durable payload used as input.

## Known limitations and follow-up

The detector represents image-kinematic treadmill events, not force-plate
contact. Frame annotation status is preserved but is not yet an automatic step
exclusion rule.

# Gait Analysis

Gait Analysis 2 converts a current Video Marker project into independently
segmented treadmill swing steps, per-frame kinematics, per-step gait
parameters, visual step reports, and reproducible CSV outputs. Loading and
analysis are deliberately separate: loading first shows the complete tracked
skeleton trajectory; analysis then enables one-step-at-a-time review.

## Open Gait Analysis

From the LabKit launcher, select **Gait Analysis** and choose **Open**. From a
source checkout, run:

```matlab
labkit_GaitAnalysis_app
```

## Input Contract

The only file input is a current Video Marker `labkitProject` MAT document or
autosave. The MAT file is the analysis source of truth and the cross-App data
contract; Gait Analysis does not call the Video Marker package at runtime. The
saved fields are described by
[Video Marker project and session state](../../image-measurement/video-marker/README.md#project-and-session-state).
Gait Analysis reads:

- frames-by-points-by-2 pixel coordinates;
- point IDs, point names, and skeleton edges;
- frame annotation status and source when present;
- video frame count, frame rate, duration, width, and height;
- scale calibration and physical unit when calibrated.

The app does not reopen the original video to obtain scientific metadata.
Video Marker payloads older than the embedded-video-metadata contract must be
opened and saved with the current Video Marker before analysis. Gait Analysis
rejects generic coordinate tables and arbitrary MAT variables because they do
not jointly own timing, skeleton, calibration, and annotation provenance.
`computeGait` still accepts an in-memory normalized pose for deterministic
tests and programmatic calculations.

The Video Marker document is stored as a portable project source. Older Gait
Analysis projects are upgraded on load.

Coordinates use image convention: the origin is at the upper left and Y
increases downward. The skeleton preview preserves that convention. Angle and
length time series use conventional plot axes.

## Project And Session State

The pose source, analysis options, computed tables/events, and export record
are saved. Decoded pose data and the currently selected step are reconstructed
after load. Projects from the older stride-naming contract invalidate results
whose scientific meaning changed, so rerun the analysis before export.

## Two-Stage Workflow

### 1. Load And Inspect All Trajectories

Choose **Open Video Marker MAT**. Before any analysis runs, the workspace overlays
every recorded skeleton and each named point trajectory. This view is intended
to expose gross tracking failures, missing landmarks, unexpected skeleton
order, and coordinate orientation before derived numbers are produced.

The source summary reports frame count, point count, embedded frame rate,
source format, and unit. Role fields are populated from matching source point
names; `iliac_crest` is accepted for the iliac role.

### 2. Analyze And Review One Step

Choose **Run analysis**. Select a row in the step table or use **Previous
step** and **Next step**. The workspace then shows only that step:

1. all skeleton poses from lift-off through landing, with point trajectories;
2. hip, knee, and ankle angle traces;
3. iliac-hip, hip-knee, knee-ankle, and ankle-foot length traces.

The skeleton plot annotates swing duration, step length, iliac/hip/knee/ankle/
foot translations, and each joint's minimum, maximum, and range of motion. This
is the app version of the earlier per-step gait figure; the figures no longer
need to be generated as an intermediate image set merely to inspect each step.

## Step Segmentation

The default treadmill detector operates on the smoothed foot X coordinate.
A lift-off candidate is a local maximum whose prominence is at least the
configured threshold and whose height is at least the configured
mean-minus-sigma standard-deviation floor. Candidates closer than the minimum
interval retain the higher peak. Every accepted lift-off is independently paired with the lowest
subsequent foot X value before the next lift-off, or before the recording ends.
That following minimum is the landing event.

This pairing is important: a completed last swing remains a valid step even
when the recording ends before another lift-off. Earlier contact-to-contact
implementations lost that final step. These are image-kinematic treadmill
events, not force-plate contact measurements.

When a later lift-off exists, the app additionally derives cycle time, stance
time, cadence, and duty factor. Those values are legitimately unavailable for
the final independently complete swing if no next lift-off was recorded.

## Parameters

| Parameter | Default | Meaning |
| --- | --- | --- |
| Iliac, hip, knee, ankle, foot point | Matching role name | Exact, case-insensitive source point assigned to each anatomical role. |
| Frame rate | `0` until supplied by the source | Used only when the source has no usable per-frame time vector. Current Video Marker projects populate it automatically. |
| Pixels per unit | `1` | Pixel density for physical outputs. A valid Video Marker calibration replaces it automatically. |
| Unit name | `px` | Physical unit label associated with pixels per unit. |
| First-frame first point as origin | Off | Shifts scaled coordinate exports; raw pixel coordinates remain unchanged. |
| Smooth window | 5 frames | Centered finite-value mean applied independently to each point and axis. |
| Minimum foot-X prominence | 20 source units | Minimum lift-off peak prominence inherited from the legacy treadmill workflow. |
| Peak-height sigma | 2 | Requires a lift-off peak to be at least mean foot X minus this many standard deviations, matching the legacy treadmill detector. |
| Minimum interval | 0.2 s | Minimum time between lift-off peaks; converted to frames from source timing. |
| Minimum swing | 3 frames | Minimum accepted inclusive lift-off-to-landing span and timing-free separation fallback. |
| Maximum swing | 300 frames | Maximum accepted inclusive lift-off-to-landing span. |
| Minimum step length | 1 output unit | Minimum two-dimensional foot endpoint displacement. |
| Maximum hip translation | 1,000,000 output units | Upper endpoint-displacement QC rule; the default normally leaves it inactive. |

Changing any parameter invalidates the previous result. Repeating a run with
the same source and parameters is skipped when its deterministic fingerprint
is unchanged.

## Calculations

For each frame the app calculates unsigned 0-180 degree hip, knee, and ankle
angles from adjacent segment vectors and four Euclidean segment lengths. A
nonfinite or zero-length vector produces `NaN`; the app does not invent an
angle.

For each lift-off-to-landing step it calculates:

- swing duration;
- two-dimensional foot endpoint displacement, reported as step length;
- two-dimensional endpoint translation for iliac, hip, knee, ankle, and foot;
- minimum, maximum, and range of motion for hip, knee, and ankle;
- cycle time, stance time, cadence per minute, and duty factor when the next
  lift-off exists;
- validity and a concrete rejection reason for duration, step length, or hip
  translation rules.

The former scripts sometimes called foot displacement `stride_length` even
though only one active swing was measured. Version 2 uses `step_length` so the
column name matches the calculation.

## Outputs

**Export CSV set** writes:

- `<source>_frames.csv`: frame/time, step membership, event flags, three joint
  angles, four segment lengths, and scaled point coordinates;
- `<source>_coordinates.csv`: raw pixel and scaled/origin-shifted coordinates;
- `<source>_steps.csv`: event boundaries, timing, cadence/duty factor, step
  length, five point translations, joint extrema/ROM, validity and reason;
- `<source>_summary.csv`: source geometry, counts, valid-step means, and global
  joint extrema;
- `<source>_gait.labkit.json`: provenance manifest for inputs, parameters,
  outputs, and valid-step count.

## Use Without The GUI

```matlab
pose = gait_analysis.sourceFiles.readPoseFile("marker-project.mat");
opts = gait_analysis.analysisRun.optionsForPose( ...
    pose, gait_analysis.analysisRun.defaultOptions());
result = gait_analysis.analysisRun.computeGait(pose, opts);
writetable(result.stepTable, "steps.csv");
```

`computeGait` performs no UI or file writes. Its result contains `frameTable`,
`coordinateTable`, `stepTable`, `summaryTable`, paired `events`, normalized
`options`, `ok`, and `message`.

## Limitations

- Kinematic lift-off and landing are not substitutes for force or pressure
  measurements.
- The default detector reflects lateral treadmill motion and assumes the foot
  travels toward increasing X before returning toward decreasing X.
- Smoothing and prominence affect event boundaries and must be reported with
  scientific results.
- Tracking confidence and manual/predicted frame status are preserved from
  Video Marker but are not yet automatic step-exclusion rules.
- Group statistics and between-animal inference are outside this single-
  recording app; exported step tables are the boundary for that workflow.

## Related Functions And Apps

- `gait_analysis.sourceFiles.readPoseFile`
- `gait_analysis.analysisRun.defaultOptions`
- `gait_analysis.analysisRun.optionsForPose`
- `gait_analysis.analysisRun.computeGait`
- [Video Marker](../../image-measurement/video-marker/README.md)
- [Gait apps](../README.md)

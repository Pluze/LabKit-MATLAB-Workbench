# Gait Analysis

Gait Analysis converts named two-dimensional pose coordinates into frame,
coordinate, step, and summary tables. The app keeps role mapping, time and
scale calibration, smoothing, event detection, preview, and export in one
reproducible project.

## Open Gait Analysis

From the LabKit launcher, select **Gait Analysis** and choose **Open**. From a
source checkout, run:

```matlab
labkit_GaitAnalysis_app
```

## Supported Inputs

Use **Source > Open pose file** to open one of these inputs:

- CSV, TSV, or TXT with paired `point_x`/`point_y` or
  `point__x`/`point__y` columns;
- MAT containing a `pose` or `poseData` structure;
- MAT containing `coords` and `pointNames` variables;
- a current Video Marker `labkit.project` document or autosave;
- compatible legacy `videoMarkerProject` or `imageMarkerProject` payloads.

Normalized coordinates have shape frames-by-points-by-2. Point names must
match the second dimension. A supplied frame index or time vector must match
the frame count.

## Analyze A Recording

1. On **Source**, open a pose or marker-project file.
2. On **Roles + Detection**, enter the exact point name for each anatomical
   role.
3. Set frame rate, pixels per unit, output unit, and optional origin shift.
4. Set smoothing and step quality thresholds.
5. Return to **Source** and choose **Run analysis**.
6. Use the preview mode selector to inspect **Trajectory**, **Angles**, or
   **Steps**.
7. On **Results + Export**, review the summary and step table, choose an output
   folder, and choose **Export CSV set**.

Changing an option invalidates the previous result. Repeating a run with the
same source and options is skipped when the result fingerprint is unchanged.

## Parameters

| Parameter | Default | Meaning |
| --- | --- | --- |
| Iliac, hip, knee, ankle, foot point | matching lowercase role name | Exact, case-insensitive source point name assigned to each role |
| Frame rate | 30 Hz | Used only when the source does not provide a usable time vector |
| Pixels per unit | 1 | Coordinate scale; physical distance equals pixels divided by this value |
| Unit name | `px` | Label attached to scaled coordinate and distance outputs |
| Use first-frame first point as origin | Off | Shifts derived export coordinates while retaining raw pixel columns |
| Smooth window | 5 frames | Centered finite-value mean applied independently to every coordinate |
| Minimum step | 3 frames | Shorter candidates fail step quality control |
| Maximum step | 300 frames | Longer candidates fail step quality control |
| Minimum stride | 1 output unit | Smaller candidates fail step quality control |
| Maximum hip drift | 1,000,000 output units | Upper drift rule; the default effectively leaves it disabled |

## Calculation Sequence

`computeGait` resolves the five role names, selects source time or derives time
from frame rate, determines coordinate scale, and smooths each point and axis.
It then computes hip, knee, and ankle angles from adjacent segment vectors,
computes scaled segment lengths, detects step events, evaluates step quality,
and assembles all result tables.

Joint angles use the vector dot product and are reported in degrees. A zero or
nonfinite segment produces `NaN`; the app does not invent an angle. Missing
coordinate samples are ignored inside each smoothing window when at least one
finite value is available.

## Outputs

**Export CSV set** writes four CSV files and one LabKit result manifest:

- frame metrics, including time, angles, lengths, and step membership;
- coordinates, including raw pixels and optional scaled/origin-shifted values;
- one row per detected step with quality status and step measurements;
- summary metrics;
- `<source>_gait.labkit.json`, which records inputs, parameters, output names,
  and the valid-step count.

The manifest is provenance metadata, not an extra scientific result.

## Use Gait Analysis Without The GUI

```matlab
pose = gait_analysis.sourceFiles.readPoseFile("marker-project.mat");

opts = gait_analysis.appState.defaultOptions();
opts.frameRate = 120;
opts.pixelsPerUnit = 24.6;
opts.unitName = "mm";

result = gait_analysis.analysisRun.computeGait(pose, opts);
writetable(result.stepTable, "steps.csv");
```

The returned structure contains `frameTable`, `coordinateTable`, `stepTable`,
`summaryTable`, detected `events`, the normalized `options`, `ok`, and a
message. `computeGait` performs no UI or file writes.

## Errors And Limitations

- Every required role name must resolve to a source point.
- Coordinate units are only as valid as the entered calibration.
- Frame rate is ignored when a usable source time vector is present.
- Smoothing changes event locations and derived angles; save the chosen window
  with any reported results.
- The app analyzes existing coordinates; it does not assess landmark placement
  accuracy.

## Related Functions And Apps

- `gait_analysis.sourceFiles.readPoseFile`
- `gait_analysis.analysisRun.computeGait`
- [Video Marker](../../image-measurement/video-marker/README.md)
- [Gait apps](../README.md)

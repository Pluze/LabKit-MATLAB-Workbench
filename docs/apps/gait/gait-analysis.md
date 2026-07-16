# Gait Analysis

Gait Analysis converts ordered pose coordinates into frame, step, and summary
metrics with explicit point-role, scale, time, smoothing, and origin options.

## Launch

```matlab
labkit_GaitAnalysis_app
```

## Inputs

- CSV, TSV, or TXT tables with paired point X/Y columns;
- MAT files containing `pose`, `poseData`, or `coords` plus `pointNames`;
- current Video Marker project or recovery envelopes;
- compatible legacy Video Marker or Image Marker project/autosave payloads.

Marker projects are read directly. Gait Analysis does not require an
intermediate CSV and does not modify the source project.

## Workflow

1. Load a coordinate or marker-project file.
2. Map point names to anatomical roles.
3. Set frame rate/time source, smoothing window, scale, coordinate unit, and
   origin policy.
4. Configure step-event detection.
5. Run analysis and review the QC preview.
6. Export frame, coordinate, step, and summary tables.

## Scientific Semantics

Coordinates remain ordered by point name. Smoothing is applied before joint
angles, segment lengths, translations, and event detection. Scale converts
pixel distances to the selected physical unit; origin shifting affects derived
coordinate columns but the export retains raw pixel coordinates for audit.

Step metrics are derived from detected events and their frame/time positions.
Role mapping is explicit because point labels from different marker projects
are not assumed to share anatomical meaning.

## Outputs

- frame metrics CSV;
- coordinate CSV with raw pixel and scaled/origin-shifted columns;
- step metrics CSV;
- summary CSV and QC plot.

## Use Without The GUI

```matlab
pose = gait_analysis.sourceFiles.readPoseFile("marker-project.mat");
opts = gait_analysis.appState.defaultOptions();
opts.frameRate = 120;
result = gait_analysis.analysisRun.computeGait(pose, opts);
writetable(result.stepTable, "steps.csv");
```

## Errors And Troubleshooting

- Every point requires paired X/Y columns and a stable name.
- A marker MAT must contain a recognized project envelope or supported legacy
  payload.
- Review role mapping and scale before interpreting physical distances or ROM.

## See Also

- `gait_analysis.analysisRun.computeGait`
- [Video Marker](../image-measurement/video-marker.md)
- [Gait family](../families/gait.md)

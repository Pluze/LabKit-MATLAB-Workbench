# Gait Apps

Gait apps turn frame-ordered landmark coordinates into auditable kinematic
tables. Annotation stays in the image or video marker workflow; this family
owns role mapping, coordinate calibration, temporal interpretation, gait
metrics, quality checks, and result export.

## Choose An App

| Task | App |
| --- | --- |
| Place and revise landmarks on video frames | [Video Marker](../image-measurement/video-marker/README.md) |
| Convert completed landmarks into gait metrics | [Gait Analysis](gait-analysis/README.md) |

## Data Flow

1. The current Video Marker records one ordered set of named points per frame
   and saves coordinates, skeleton, timing, and calibration in its project.
2. Gait Analysis validates that project and normalizes the saved payload to a
   frame-by-point-by-two coordinate array.
3. The user maps point names to iliac, hip, knee, ankle, and foot roles.
4. The app smooths coordinates, calculates joint angles and segment lengths,
   detects steps, applies quality rules, and builds export tables.

Gait Analysis reads current Video Marker archive files directly.
It never rewrites the annotation project and does not accept generic MAT or
coordinate-table substitutes that lack the required source metadata.

## Use The Calculation Without The App

The app-owned calculation entry point is
`gait_analysis.analysisRun.computeGait`. It accepts normalized pose data from
`gait_analysis.sourceFiles.readPoseFile` and the same option structure used by
the app. See the [Gait Analysis manual](gait-analysis/README.md) for the data
shape, defaults, outputs, and example.

## Related Documentation

- [Image Measurement apps](../image-measurement/README.md)
- [App catalog](../README.md)
- [App Framework](../../framework/README.md)

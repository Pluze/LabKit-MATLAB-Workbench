# Gait Apps

The gait family converts ordered pose coordinates into frame metrics, step
events, joint angles, translations, range of motion, and quality-control
previews.

## App

[Gait Analysis](gait-analysis/README.md) reads coordinate tables, MAT
coordinate payloads, and compatible Video Marker or legacy Image Marker
projects and autosaves.

## Workflow Boundary

Marker placement and frame annotation belong in Video Marker or Image Marker.
Gait Analysis consumes those coordinates, maps point names to anatomical roles,
applies configured smoothing and scale/origin transforms, and exports derived
metrics without changing the annotation project.

## Programmatic Entry Point

`gait_analysis.analysisRun.computeGait` accepts normalized pose data and an
option struct and returns the same GUI-free frame, coordinate, step, and summary
tables used by the app.

## Related Apps

- [Video Marker](../image-measurement/video-marker/README.md)
- [Gait Analysis](gait-analysis/README.md)

# Video Marker

Video Marker defines an ordered landmark skeleton, records coordinates across
video frames, predicts forward positions between manual anchors, and saves a
portable project with autosave and recovery.

## Requirements And Launch

The app declares compatibility with LabKit UI 7.x and uses the image functions
shipped with the same workbench. Video decoding uses MATLAB's available video
support. Predictive navigation is implemented in repository-owned MATLAB code;
no model weights or third-party runtime package are downloaded.

```matlab
labkit_VideoMarker_app
```

## Start Or Open A Project

The **Session** panel appears first in the Video tab. **Open MAT** uses the same
loader as the window's top-level Load State action and accepts an explicit
project or compatible autosave. **Save autosave** immediately updates
`Video Marker Autosaves/<video>.video_marker.autosave.mat` beside the source
video without asking for a path and without turning that recovery copy into the
named project file. **New setup** offers Cancel, Save and start new, or Discard
and start new; it never silently clears the current session.

For a new project, choose a preset or add keypoints, edit their names, reorder
them, and define connections. **Connect in order** links every adjacent pair.
At least one keypoint is required before opening a new annotation session. The
skeleton is locked after the video opens so coordinate column meaning remains
stable.

## Marking Workflow

1. Define the ordered skeleton and optional scale calibration.
2. Open the video.
3. Click blank image locations to place the next missing keypoint in order.
4. Drag an existing marker to refine it.
5. Use Undo last point or Clear frame points when needed.
6. Move to the next frame; the current frame is saved automatically.
7. Correct predicted frames periodically and export or save the project.

Point marking remains active while a video is open. A complete edited frame is
a manual anchor. Moving forward predicts every ordered point using cropped
multiscale patch matching. The tracker compares mean-centered local patches by
normalized correlation, refines accepted matches to subpixel coordinates, and
reports confidence for each point. A rejected point retains its bounded motion-
prior estimate. Predicted frames remain editable drafts. Editing a complete
frame makes it a new manual anchor for later prediction. Jumping forward
propagates through intermediate frames and does not overwrite existing manual
anchors.

Frame navigation and marker refresh preserve the current zoom. Opening a new
video or project starts at its own home view.

## Scale And Coordinate Export

Scale calibration stores a measured pixel distance, known length, and unit.
The coordinate export options are:

- units: `pixels` or `calibrated_physical`;
- origin: `top_left_pixel_center` or `first_point`;
- Y axis: `up` or `down`;
- inclusive start and end frame.

Marker CSV is the round-trip editing format. Coordinate CSV is the
plotting-oriented table after optional calibration, origin shift, and Y-axis
conversion. Raw pixel coordinates remain available in the project.

## Autosave, Recovery, And Portability

Changes to the skeleton or annotations are atomically saved to `Video Marker
Autosaves` beside the source video. Autosave and explicit project MAT files use
the same project data. They store frame count, frame rate, duration, image
dimensions, skeleton edges, annotation status/source, and calibration alongside
the durable coordinates. The portable source record stores the video path
relative to the MAT file, the original path, and same-folder filename fallbacks.
Downstream apps such as Gait Analysis therefore use the MAT document as their
scientific data source without reopening the original video.

When a project tree moves between folders, users, or operating systems, the
relative reference is tried first. If no candidate exists, the app asks the
user to locate the video without discarding skeleton or annotations. Opening a
video with adjacent recovery data asks whether to restore it or start new. A
compatible old Video Marker project or autosave opens with an unsaved marker;
choosing the top-level **Save State** action atomically upgrades that same MAT
path to the current `labkitProject` format.

## Project And Session State

`video_marker.projectSpec` is the single durable-project contract. It owns the
current schema factory and validator, the version-1 payload upgrade, the former
`videoMarkerProject` MAT-variable importer, and the lightweight current-frame
resume policy. Runtime V2 performs migration iteration, validates the imported
payload, resolves required video sources, and only then calls
`video_marker.createSession`.

Durable state consists of video metadata, the portable video source, skeleton,
frame annotations and provenance, calibration, export parameters, and output
manifest paths. The video reader, decoded frame, current interaction,
selection, preview graphics, and frame cache are transient session resources.
Only the current frame number is saved as navigation convenience; annotations
remain the authoritative scientific data.

## Outputs

- explicit project MAT and visible autosave MAT;
- marker CSV for round-trip editing;
- coordinate CSV for analysis and plotting;
- output manifests recording coordinate options and file roles.

## Use Without The GUI

<!-- labkit-runnable-example -->
```matlab
previousFrame = peaks(61);
nextFrame = circshift(previousFrame, [-2 3]);
[nextPoints, confidence] = video_marker.motionEstimate.trackPoints( ...
    previousFrame, nextFrame, [31 31]);

skeleton = video_marker.skeletonDefinition.fromText( ...
    "hip, knee", "hip-knee");
annotations = video_marker.frameAnnotations.emptyAnnotations(2, 2);
annotations = video_marker.frameAnnotations.setFramePoints( ...
    annotations, 1, [11 21; 31 41], "confirmed");
annotations = video_marker.frameAnnotations.setFramePoints( ...
    annotations, 2, [13 25; 35 45], "confirmed");
videoInfo = struct("frameRate", 10);
options = video_marker.coordinateExport.options( ...
    "startFrame", 1, "endFrame", 2, "unitMode", "pixels", ...
    "originMode", "first_point", "yAxisMode", "up");
coordinateTable = video_marker.coordinateExport.buildTable( ...
    annotations, skeleton, videoInfo, struct(), options);
```

## Errors And Limitations

- Prediction is an editing aid, not unattended long-duration tracking.
- Occlusion, blur, repeated texture, large deformation, and leaving the frame
  can invalidate patch matches; inspect and correct drafts.
- Calibrated export requires a valid positive scale calibration.
- Changing skeleton order after annotation would change coordinate meaning and
  is therefore prevented once a video session begins.

## Related Topics

- [Gait Analysis](../../gait/gait-analysis/README.md)
- [Image Measurement family](../README.md)
- [API Reference](../../../libraries/README.md)

## Framework Compatibility

This App requires `labkit.ui >=7 <8`. Its single `definition.m` owns product
metadata, requirements, layout, actions, presentation, renderers, and optional
capabilities. `projectSpec.m` concentrates all durable creation, validation,
migration, legacy import, and resume hooks; root `createSession.m` rebuilds the
transient video state.

The App reads video locations only through `labkit.ui.runtime.sourcePaths`.
Legacy portable references are passed intact to `sourceRecord` for framework
validation and canonicalization; no App helper knows the Runtime's nested path
schema. Busy state, callback queues, resource cleanup, source relinking,
serialization envelopes, and migration iteration remain framework-owned.

Its session factory returns only App-specific frame selection, editing
workflow, scale-bar view, and decoded video cache fields. Runtime supplies
absent canonical buckets and owns workflow-log initialization.

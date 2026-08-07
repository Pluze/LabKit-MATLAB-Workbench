# Video Marker

Video Marker defines an ordered landmark skeleton, records coordinates across
video frames, predicts forward positions between manual anchors, and saves a
portable project with a source-adjacent autosave copy.

## Requirements And Launch

The app declares compatibility with `labkit.app` 1.x and uses image functions
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
named project file. Point placement, dragging, undo, clear, imported marker
coordinates, and newly predicted frames update the same autosave automatically.
**New setup** offers Cancel, Save and start new, or Discard and start new; it
never silently clears the current session.

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

Every committed point-information change writes atomically to
`Video Marker Autosaves` beside the source video. This includes point placement
and dragging, undo and clear, marker CSV import, and forward prediction. The
**Save autosave** action remains available to force an immediate write without
waiting for another point change. Autosave and named project MAT files contain
the same project data: frame count, frame rate, duration, image dimensions,
skeleton edges, annotation status/source, calibration, and durable coordinates.
The video itself remains an external portable source and can be relinked
without discarding annotations.

When a project tree moves between folders, users, or operating systems, the
relative reference is tried first. If no candidate exists, the app asks the
user to locate the video without discarding skeleton or annotations. A
compatible old Video Marker project or autosave opens through **Open MAT** or
**Tools > Project State > Load State...**.

## What The Project Saves

The project saves the video reference and metadata, skeleton, frame
annotations, calibration, export settings, and current frame number. It does
not copy the video or a frame cache. When the project is reopened, Video Marker
reads frames from the source video and preserves the saved annotations.

Older compatible project and autosave formats are upgraded when opened. Save
the upgraded project before moving it into another workflow.

## Outputs

- explicit project MAT and visible autosave MAT;
- marker CSV for round-trip editing;
- coordinate CSV for analysis and plotting;
- output manifests recording coordinate options and file roles.

CSV dialogs start in a source-adjacent `video_marker` output folder. Result
manifests are written beside the chosen CSV.

## Diagnostics And Synthetic Inputs

Use **Tools > Diagnostics** to inspect the live session log, enable trace
capture, or export a diagnostic bundle after a problem occurs. Use **Tools >
Developer Tools > Generate Synthetic Inputs...** to create a synthetic video,
a valid marking project, and declared marker/coordinate output targets without
including user filenames or laboratory data. Generation does not load those
inputs into the running App.

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

## Function Reference

Use the generated
[`buildTable`](../../../reference/api/video_marker/coordinateExport/buildTable.html)
page for exact frame-range option types, defaults, coordinate transforms,
calibration requirements, output columns, failures, and related marker APIs.
The
[`trackPoints`](../../../reference/api/video_marker/motionEstimate/trackPoints.html)
page documents the repository-owned prediction contract separately.

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
- [API Reference](../../../reference/README.md)

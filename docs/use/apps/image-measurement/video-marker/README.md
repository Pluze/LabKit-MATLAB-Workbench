# Video Marker

```labkit-page
id: app-video-marker
type: landing
audience: app-user
summary: Define an ordered landmark skeleton, record or predict coordinates across video frames, and save an explicit project snapshot when requested.
```

Video Marker defines an ordered landmark skeleton, records coordinates across video frames, predicts forward positions between manual anchors, and saves an explicit App-owned MAT snapshot when requested.

## Requirements And Launch

The app uses the current LabKit App SDK and declares compatibility with `labkit.image` 2.x. Video decoding uses Base MATLAB's available video support. Predictive navigation is implemented in repository-owned MATLAB code; no optional Toolbox, model weight, or third-party runtime package is required.

```matlab
labkit_VideoMarker_app
```

## Start Or Open A Project

The **Session** panel appears first in the Video tab. **Open MAT** is Video Marker's task-specific continuation action and accepts the current explicit Video Marker MAT snapshot. **Save MAT** asks for a destination and writes the current video reference, skeleton, calibration, annotations, and frame position. Editing and navigation only update the live App; they never write an implicit autosave or record intermediate adjustments. **New setup** offers Cancel, Save and start new, or Discard and start new; it never silently clears the current session.

For a new project, choose a preset or add keypoints, edit their names, reorder them, and define connections. **Connect in order** links every adjacent pair. At least one keypoint is required before opening a new annotation session. The skeleton is locked after the video opens so coordinate column meaning remains stable.

## Marking Workflow

1. Define the ordered skeleton and optional scale calibration.
2. Open the video.
3. Click blank image locations to place the next missing keypoint in order.
4. Drag an existing marker to refine it.
5. Use Undo last point or Clear frame points when needed.
6. Move to the next frame and correct predicted frames periodically.
7. Export results or use **Save MAT** to preserve the current task snapshot.

Point marking remains active while a video is open. A complete edited frame is a manual anchor. Moving forward predicts every ordered point using cropped multiscale patch matching. The tracker compares mean-centered local patches by normalized correlation, refines accepted matches to subpixel coordinates, and reports confidence for each point. A rejected point retains its bounded motion- prior estimate. Predicted frames remain editable drafts. Editing a complete frame makes it a new manual anchor for later prediction. Jumping forward propagates through intermediate frames and does not overwrite existing manual anchors.

Frame navigation and marker refresh preserve the current zoom. Opening a new video or project starts at its own home view.

## Snapshot And Portability

**Save MAT** writes one current/final snapshot containing frame count, frame rate, duration, image dimensions, skeleton edges, annotation status/source, calibration, coordinates, settings, and current frame. It does not write an interaction log, intermediate edits, decoded frames, or the source video.

When a project tree moves between folders, users, or operating systems, the saved path, its archive-relative interpretation, and a same-folder filename are tried. A missing required source is reported without partially replacing the live task.

## Scale And Coordinate Export

Scale calibration stores a measured pixel distance, known length, and unit. The coordinate export options are:

- units: `pixels` or `calibrated_physical`;
- origin: `top_left_pixel_center` or `first_point`;
- Y axis: `up` or `down`;
- inclusive start and end frame.

Marker CSV is the round-trip editing format. Coordinate CSV is the plotting-oriented table after optional calibration, origin shift, and Y-axis conversion. Raw pixel coordinates remain available in the MAT snapshot.

## What The Project Saves

The project saves the video reference and metadata, skeleton, frame annotations, calibration, export settings, and current frame number. It does not copy the video or a frame cache. When the project is reopened, Video Marker reads frames from the source video and preserves the saved annotations.

Only the current App-owned snapshot format is accepted. Video Marker does not maintain migration behavior for retired framework or autosave formats.

## Outputs

- explicit Video Marker MAT snapshot;
- marker CSV for round-trip editing;
- coordinate CSV for analysis and plotting;

CSV and annotated-video dialogs start in a source-adjacent `video_marker` output folder. **Render annotated video** writes every source frame at the source frame rate, burning in the current landmark points and skeleton connections. Even source dimensions are retained; MATLAB pads an odd width or height by one pixel for MPEG-4. Frames without points remain unmarked. Output uses MP4 with H.264 encoding for ordinary-player compatibility. MATLAB supports MPEG-4 writing on macOS and Windows; the render button is unavailable on Linux.

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

The same renderer used by the export button can be called without the GUI:

```matlab
summary = video_marker.resultFiles.writeAnnotatedVideo( ...
    "source.avi", "annotated.mp4", annotations, skeleton);
```

## Function Reference

Use the generated [`buildTable`](../../../../reference/api/video_marker/coordinateExport/buildTable.html) page for exact frame-range option types, defaults, coordinate transforms, calibration requirements, output columns, failures, and related marker APIs. The [`trackPoints`](../../../../reference/api/video_marker/motionEstimate/trackPoints.html) page documents the repository-owned prediction contract separately. [`writeAnnotatedVideo`](../../../../reference/api/video_marker/resultFiles/writeAnnotatedVideo.html) documents supported video containers, progress reporting, output metadata, and failure behavior.

## Diagnostics

Use **Tools > Diagnostics** to inspect the live session log and enable trace capture; retained session journals remain available after a problem occurs. Rapid frame navigation records the committed navigation action instead of an INFO message for every predicted or visited frame. Long annotated-video exports expose bounded developer progress while preserving user-facing completion and failure milestones.

## Errors And Limitations

- Prediction is an editing aid, not unattended long-duration tracking.
- Occlusion, blur, repeated texture, large deformation, and leaving the frame can invalidate patch matches; inspect and correct drafts.
- Calibrated export requires a valid positive scale calibration.
- Changing skeleton order after annotation would change coordinate meaning and is therefore prevented once a video session begins.

## Related Topics

- [Gait Analysis](../../gait/gait-analysis/README.md)
- [Image Measurement family](../README.md)
- [API Reference](../../../../reference/README.md)

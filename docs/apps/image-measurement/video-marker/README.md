# Video Marker

Video Marker defines an ordered landmark skeleton, records coordinates across
video frames, predicts forward positions between manual anchors, and saves a
portable project with autosave and recovery.

## Requirements And Launch

The app requires the LabKit UI and Image facades. Video decoding uses MATLAB's
available video support. Predictive navigation uses MATLAB point tracking when
available and repository-owned fallback logic; no model weights or third-party
runtime package are downloaded.

```matlab
labkit_VideoMarker_app
```

## Start Or Open A Project

The **Session** panel appears first in the Video tab. **Open MAT** uses the same
loader as the window's top-level Load State action and accepts an explicit
project or compatible autosave. **New setup** offers Cancel, Save and start
new, or Discard and start new; it never silently clears the current session.

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
pyramidal KLT tracking with forward/backward reliability checks; rejected
points use a constant-velocity estimate. Predicted frames remain editable
drafts. Editing a complete frame makes it a new manual anchor for later
prediction. Jumping forward propagates through intermediate frames and does not
overwrite existing manual anchors.

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

Durable annotation changes are atomically saved to `Video Marker Autosaves`
beside the source video. Autosave and explicit project MAT files use the same
project payload. The payload stores the video path relative to the MAT file,
the original path, and same-folder filename fallbacks.

When a project tree moves between folders, users, or operating systems, the
relative reference is tried first. If no candidate exists, the app asks the
user to locate the video without discarding skeleton or annotations. Opening a
video with adjacent recovery data asks whether to restore it or start new.

## Outputs

- explicit project MAT and visible autosave MAT;
- marker CSV for round-trip editing;
- coordinate CSV for analysis and plotting;
- output manifests recording coordinate options and file roles.

## Use Without The GUI

```matlab
[nextPoints, confidence] = video_marker.motionEstimate.trackPoints( ...
    previousFrame, nextFrame, previousPoints, struct());
coordinateTable = video_marker.coordinateExport.buildTable(project);
```

## Errors And Limitations

- Prediction is an editing aid, not unattended long-duration tracking.
- Occlusion, blur, large deformation, and leaving the frame can invalidate KLT
  predictions; inspect and correct drafts.
- Calibrated export requires a valid positive scale calibration.
- Changing skeleton order after annotation would change coordinate meaning and
  is therefore prevented once a video session begins.

## Related Topics

- [Gait Analysis](../../gait/gait-analysis/README.md)
- [Image Measurement family](../README.md)
- [API Reference](../../../libraries/README.md)

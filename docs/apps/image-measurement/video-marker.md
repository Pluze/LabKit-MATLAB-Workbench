# Video Marker

Video Marker creates ordered frame-by-frame landmark annotations with project
save, autosave, recovery, and app-owned point tracking.

## Launch

```matlab
labkit_VideoMarker_app
```

## Projects And Session Actions

The Session panel is the first workflow panel. **Open MAT** loads a saved or
autosaved project. **New setup** requires confirmation and offers Cancel, Save
and start new, or Discard and start new so an active annotation session is not
silently destroyed.

## Marking Workflow

Open a video or image sequence, define ordered marker names, then place points
on each frame. Project state records coordinates, point order, source identity,
current frame, setup, and recovery information. Predictive navigation uses the
repository-owned tracker and keeps manually confirmed points authoritative.

## Use Without The GUI

```matlab
[trackedPoints, confidence] = video_marker.motionEstimate.trackPoints( ...
    previousFrame, nextFrame, previousPoints, struct());
tableOut = video_marker.coordinateExport.buildTable(project);
```

## Outputs

- current project MAT and autosave MAT;
- coordinate tables ordered by frame and marker;
- recoverable setup and navigation state.

## See Also

- [Gait Analysis](../gait/gait-analysis.md)
- `video_marker.motionEstimate.trackPoints`
- `video_marker.coordinateExport.buildTable`


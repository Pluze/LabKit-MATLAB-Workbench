# Source-adjacent Video Marker autosave

```labkit-change
id: CHG-20260716-source-adjacent-video-autosave
date: 2026-07-16
type: fix
compatibility: compatible
component: labkit.ui | 6.0.3 -> 6.0.4
component: labkit_VideoMarker_app | 1.4.0 -> 1.4.1
```

## Why

The first explicit Runtime V2 autosave action wrote only the framework's hidden recovery generation. Video Marker already had a product contract for a visible, stable autosave beside the source video, and users select those MAT files directly in downstream workflows such as Gait Analysis.

### Accepted choice

Keep generic debounced recovery framework-owned, but let an app provide a deterministic autosave destination when that location is part of its workflow. Video Marker derives the destination from the source video and never asks the user to choose it.

## What changed

- Added `services.project.saveAutosave(state,filepath)` without changing named project ownership or dirty status.
- Restored the visible `Video Marker Autosaves` folder and stable `<video>.video_marker.autosave.mat` filename.
- Enabled **Save autosave** only after a video is open and report write failures through the standard diagnostics and app-parented alert services.

## Impact

Clicking **Save autosave** immediately overwrites the source video's current autosave using the current `labkitProject` envelope. It opens no location dialog. The file remains easy to locate, copy, and load into Gait Analysis.

## Compatibility and limits

The filename and source-adjacent folder match the earlier Video Marker autosave convention. Generic Runtime recovery remains available independently.

### Remaining limits

The source folder must be writable. A write failure leaves the current project untouched and is shown to the user.

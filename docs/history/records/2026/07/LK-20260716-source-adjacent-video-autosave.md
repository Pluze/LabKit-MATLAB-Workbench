# Source-adjacent Video Marker autosave

```labkit-change
id: LK-20260716-source-adjacent-video-autosave
date: 2026-07-16
sequence: 69
type: fix
compatibility: compatible
component: `labkit.ui` | `6.0.3 -> 6.0.4`
component: `labkit_VideoMarker_app` | `1.4.0 -> 1.4.1`
scope: Runtime V2 project recovery
scope: Video Marker autosave location
```

## Context

The first explicit Runtime V2 autosave action wrote only the framework's hidden
recovery generation. Video Marker already had a product contract for a visible,
stable autosave beside the source video, and users select those MAT files
directly in downstream workflows such as Gait Analysis.

## Decision and rationale

Keep generic debounced recovery framework-owned, but let an app provide a
deterministic autosave destination when that location is part of its workflow.
Video Marker derives the destination from the source video and never asks the
user to choose it.

## Changes

- Added `services.project.saveAutosave(state,filepath)` without changing named
  project ownership or dirty status.
- Restored the visible `Video Marker Autosaves` folder and stable
  `<video>.video_marker.autosave.mat` filename.
- Enabled **Save autosave** only after a video is open and report write failures
  through the standard diagnostics and app-parented alert services.

## User and data impact

Clicking **Save autosave** immediately overwrites the source video's current
autosave using the current `labkitProject` envelope. It opens no location
dialog. The file remains easy to locate, copy, and load into Gait Analysis.

## Compatibility and migration

The filename and source-adjacent folder match the earlier Video Marker autosave
convention. Generic Runtime recovery remains available independently.

## Validation

The focused Video Marker GUI test opens a synthetic video, verifies the button
is enabled, writes the expected source-adjacent MAT, and confirms the runtime
still has no named project path.

## Evidence

- [Video Marker](../../../../apps/image-measurement/video-marker/README.md)
  documents the exact no-dialog destination.
- [Runtime and lifecycle](../../../../framework/guides/runtime.md) distinguishes
  generic recovery from an app-targeted autosave.

## Known limitations and follow-up

The source folder must be writable. A write failure leaves the current project
untouched and is shown to the user.

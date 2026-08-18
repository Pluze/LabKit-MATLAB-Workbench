# Video Marker renders complete annotated videos

```labkit-change
id: LK-20260818-video-marker-annotated-video
date: 2026-08-18
sequence: 181
type: feat
compatibility: compatible
component: `labkit_VideoMarker_app` | `1.7.3 -> 1.7.4`
scope: Video Marker annotated-video rendering
scope: Landmark and skeleton video export
```

## Context

Video Marker saved its portable MAT project and tabular marker coordinates, but users could not create a complete review video with the current annotations burned into each source frame.

## Decision and rationale

Add an App-owned rendered-video result beside the existing marker and coordinate exports. Render directly into source-frame pixels so the workflow retains frame count, frame rate, and dimensions without a graphics-window dependency or an optional MathWorks Toolbox.

## Changes

- Added **Render annotated video** to the Import + Export tab.
- The renderer writes every source frame and burns in finite landmark points plus skeleton connections from the current loaded project.
- Output uses only MP4 with H.264 encoding for ordinary-player compatibility.
- MATLAB supports MPEG-4 writing on macOS and Windows; Linux does not expose the render action.
- Rendering writes through a temporary file, reports durable progress, and creates a result manifest beside the completed video.
- Added the GUI-free `video_marker.resultFiles.writeAnnotatedVideo` API.
- Source resolution accepts runtime-generated video IDs when rendering or exporting CSV from a reopened named project or autosave.

## User and data impact

Users can produce a complete marked review video directly from the currently loaded MAT project and resolved source video. Empty frames remain visually unchanged. The source video and project annotations are never modified.

## Compatibility and migration

Existing Video Marker projects and exports require no migration. The new output is additive and retains the project's pixel-coordinate marker meaning.

## Validation

Focused result evidence renders a synthetic six-frame video, verifies retained frame count, frame rate, and dimensions, and confirms that annotations change rendered pixels. Workbench evidence restores a runtime-named source from autosave, predicts the next frame, exports marker CSV, coordinate CSV, and annotated video to source-adjacent defaults, saves a named MAT, restores it, and verifies the durable annotations. Presentation evidence verifies the button contract.

## Evidence

The renderer and workbench tests use only synthetic videos and landmarks. The generated MP4 is reopened through `VideoReader`, and progress start/completion events are asserted.

## Known limitations and follow-up

The burned-in overlay contains landmark circles and skeleton connections but not landmark-name text. MATLAB does not provide MPEG-4 writing on Linux, so annotated-video export is unavailable there.

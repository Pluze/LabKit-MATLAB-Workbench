# Video Marker startup validation

```labkit-change
id: CHG-20260714-video-marker-startup-fix
date: 2026-07-14
type: fix
compatibility: compatible
component: labkit_VideoMarker_app | 1.0.0 -> 1.0.1
```

## Why

Video Marker declared its preview axes as `video` but reset an empty preview through the nonexistent `raw` axes id. The runtime correctly converted that deferred startup exception into a visible failure status, but the structural GUI test continued because it checked controls before asserting that startup had completed successfully.

### Accepted choice

Use the declared `video` axes id in the app and make the shared standard workbench assertion wait for the startup lifecycle. A startup failure now fails the GUI test with the runtime diagnostic instead of leaving the test green after only verifying that the shell was constructed.

## What changed

- Corrected the empty-preview reset to target `videoAxes/video`.
- Added a shared startup-success assertion to standard workbench GUI checks.
- Added a synthetic regression proving deferred startup failures are rejected.

## Impact

Video Marker opens normally before a video is selected. This change does not alter marker projects, coordinate exports, annotations, or measurement data.

## Compatibility and limits

The fix is compatible with existing Video Marker projects and exported files. No user migration is required.

### Remaining limits

Automated startup checks validate lifecycle completion and diagnostics; they do not replace manual review of video rendering or point-drag interaction.

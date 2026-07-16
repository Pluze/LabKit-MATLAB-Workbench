# Video Marker startup validation

```labkit-change
schema: 1
id: LK-20260714-video-marker-startup-fix
date: 2026-07-14
type: fix
compatibility: compatible
component: `labkit_VideoMarker_app` | `1.0.0 -> 1.0.1`
scope: `tests/shared/guiTestHelpers.m`
```

## Context

Video Marker declared its preview axes as `video` but reset an empty preview
through the nonexistent `raw` axes id. The runtime correctly converted that
deferred startup exception into a visible failure status, but the structural
GUI test continued because it checked controls before asserting that startup
had completed successfully.

## Decision and rationale

Use the declared `video` axes id in the app and make the shared standard
workbench assertion wait for the startup lifecycle. A startup failure now
fails the GUI test with the runtime diagnostic instead of leaving the test
green after only verifying that the shell was constructed.

## Changes

- Corrected the empty-preview reset to target `videoAxes/video`.
- Added a shared startup-success assertion to standard workbench GUI checks.
- Added a synthetic regression proving deferred startup failures are rejected.

## User and data impact

Video Marker opens normally before a video is selected. This change does not
alter marker projects, coordinate exports, annotations, or measurement data.

## Compatibility and migration

The fix is compatible with existing Video Marker projects and exported files.
No user migration is required.

## Validation

The Video Marker hidden GUI test covers the corrected initial preview path.
The reusable declarative UI GUI test covers startup-failure detection in the
shared helper. Final changed-file and GUI validation are recorded in the
carrying commit and CI run.

## Evidence

The carrying commit is located by Change ID
`LK-20260714-video-marker-startup-fix`.

## Known limitations and follow-up

Automated startup checks validate lifecycle completion and diagnostics; they
do not replace manual review of video rendering or point-drag interaction.

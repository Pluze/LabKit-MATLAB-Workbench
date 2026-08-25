# Gait consumes the Video Marker file contract without a sibling App dependency

```labkit-change
id: CHG-20260717-gait-app-path-isolation
date: 2026-07-17
type: fix
compatibility: compatible
component: labkit_GaitAnalysis_app | 2.0.7 -> 2.0.8
```

## Why

Gait Analysis correctly parsed saved Video Marker MAT documents in production, but its synthetic debug writer created those documents by calling `video_marker.projectSpec`, `video_marker.skeletonDefinition`, and `video_marker.frameAnnotations`. Tests added every App root to the MATLAB path, while the launcher adds only the selected App root. Debug startup could therefore pass tests and fail in a real isolated launch.

### Accepted choice

Treat the saved `labkitProject` payload as the boundary between the producer and consumer. Gait owns its parser, diagnostics, and synthetic consumer fixture. Video Marker owns serialization and schema validation. One explicit integration test may load both Apps to prove their current file contracts agree, but neither Gait production nor debug code may call the Video Marker package.

## What changed

- Rebuilt the Gait debug sample from the documented payload fields without loading Video Marker source code.
- Split consumer parser tests from a producer-consumer integration test that constructs a current Video Marker project, validates it, saves it, and reads it through Gait.
- Added an isolated-path debug test using only the repository root and Gait App root.
- Added a repository guardrail that rejects executable calls from one App package into a sibling App package while allowing documentation references and integration tests.
- Documented the saved-data boundary in the App development guide and Gait manual.

## Impact

Gait debug startup and its packaged App behavior no longer depend on every public App being present on the MATLAB path. Users continue to open the same current Video Marker project and autosave MAT files; parsing, timing, calibration, gait calculations, and exports are unchanged.

Developers receive an immediate guardrail failure if a shared test path hides a new sibling-App runtime dependency.

## Compatibility and limits

No project or output migration is required. Video Marker payload version 2 remains the accepted input contract.

### Remaining limits

The integration test protects the current saved schema, not scientific validity of manually marked trajectories. Those data and workflow checks remain App-owned.

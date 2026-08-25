# Video Marker concentrates project history behind one contract

```labkit-change
id: CHG-20260716-video-marker-structure
date: 2026-07-16
type: refactor
compatibility: compatible
component: labkit_VideoMarker_app | 1.5.1 -> 1.5.2
component: labkit_GaitAnalysis_app | 2.0.2 -> 2.0.3
```

## Why

Video Marker had already separated skeleton, annotations, tracking, video IO, export, and UI capabilities, but its Runtime contract remained spread across seven generic lifecycle files plus separate requirement and version files. A path lookup wrapper also inspected the Runtime's nested portable-reference fields, and the legacy importer constructed that schema itself.

### Accepted choice

Keep the App's real persistence requirements—schema migration, old MAT import, and current-frame resume—but expose them together through one `projectSpec.m`. Keep decoded-video reconstruction in root `createSession.m`. Use the Runtime's source factory and accessor instead of App-owned reference adapters.

## What changed

- Consolidated product metadata, version, requirements, layout, actions, presentation, renderers, and debug capability in `definition.m`.
- Concentrated create, validate, migrate, legacy import, resume creation, and resume application behind one project-spec entry.
- Replaced the ordered migration-cell declaration with the Runtime's single migration callback.
- Replaced App-side source-reference construction and nested-field lookup with `sourceRecord` opaque import and `sourcePaths` semantic lookup.
- Removed the generic lifecycle package, source-path wrapper, and separate requirement/version files.
- Updated Gait's synthetic Video Marker fixture to construct the current payload through the project contract rather than a retired lifecycle file.

## Impact

Skeleton setup, continuous point marking, prediction, calibration, coordinate export, explicit autosave, save-before-new confirmation, recovery, source relinking, and old MAT upgrade retain their behavior. The saved current-frame resume remains navigation convenience; durable coordinates and provenance are unchanged.

Developers now find all project-history policy in one file and do not need to learn the Runtime's portable-reference representation.

## Compatibility and limits

Current schema version 2 and the recognized old `videoMarkerProject` variable are unchanged. Version-1 payloads still derive durable video metadata, and old portable references retain their relative path. New saves continue to use the current `labkitProject` envelope.

### Remaining limits

Automated GUI checks do not establish tracking validity for every recording or replace manual judgment of point placement and prediction quality. Remaining Apps with generic lifecycle packages will be reviewed independently.

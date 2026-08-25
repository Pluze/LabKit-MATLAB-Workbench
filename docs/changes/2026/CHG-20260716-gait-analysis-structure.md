# Gait Analysis keeps schema history in one project contract

```labkit-change
id: CHG-20260716-gait-analysis-structure
date: 2026-07-16
type: refactor
compatibility: compatible
component: labkit_GaitAnalysis_app | 2.0.3 -> 2.0.4
```

## Why

Gait Analysis spread creation, validation, session reconstruction, and two ordered schema upgrades through a generic lifecycle package. Its generic state package actually contained four analysis concepts: defaults, source-derived options, result construction, and duplicate-run fingerprints. Session and presentation code also inspected the Runtime's nested source-reference fields.

### Accepted choice

Concentrate project history behind one `projectSpec.m`, keep transient pose reconstruction in root `createSession.m`, and assign all former state helpers to `+analysisRun`. This preserves the real complexity—Video Marker parsing, step segmentation, kinematics, QC, and exports—while removing structural categories that did not explain the workflow.

## What changed

- Consolidated product metadata, version, requirements, layout, actions, presentation, renderer, and debug capability in `definition.m`.
- Replaced two public migration files with one migration callback that selects the version-1 or version-2 transformation from `fromVersion`.
- Moved default options, pose-derived option resolution, empty results, and deterministic task fingerprints from `+appState` to `+analysisRun`.
- Replaced direct portable-reference access with semantic `sourcePaths` lookup in session reconstruction and presentation.
- Removed generic lifecycle/state packages and separate requirement/version files, and updated GUI-free documentation calls to the owning package.

## Impact

Current Video Marker MAT loading, full-trajectory inspection, active-swing segmentation, one-step review, joint angles, translations, timing, QC, duplicate-run detection, CSV export, project save, and project reopen retain their behavior. The image-coordinate Y direction and time-series coordinate direction remain deliberately distinct.

Developers can now follow project history through one entry and find all analysis policy under the package that owns the scientific workflow.

## Compatibility and limits

Durable schema version 3 is unchanged. Version-1 option renames and result invalidation still run before the version-2 source collection upgrade. Runtime V2 now owns the loop and validates the resulting current payload.

### Remaining limits

Automated tests do not establish scientific validity for recordings outside the documented treadmill model or replace manual inspection of tracked points and segmented events. Neurophysiology and wearable Apps with generic lifecycle packages remain scheduled for the same review.

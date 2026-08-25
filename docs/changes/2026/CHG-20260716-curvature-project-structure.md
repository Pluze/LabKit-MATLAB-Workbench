# Curvature consolidates migration and analysis state

```labkit-change
id: CHG-20260716-curvature-project-structure
date: 2026-07-16
type: refactor
compatibility: compatible
component: labkit_CurvatureMeasurement_app | 1.4.2 -> 1.4.3
```

## Why

Curvature split static metadata across files, exposed four generic lifecycle functions including a filename-encoded migration, and stored five computation tasks/results under `+appState`. Session restoration also read the nested portable source path directly.

### Accepted choice

Use one project specification with a version-aware migration entry. Runtime V2 calls `Migrate(project,fromVersion)` for each missing version; Curvature keeps only the actual version-1 transformation. Put fit and length task/result shapes beside the analysis functions that consume them.

## What changed

- Consolidated product metadata and requirements in `definition.m`.
- Consolidated project creation, validation, and the v1 source migration in `projectSpec.m`.
- Moved decoded-image reconstruction to root `createSession.m`.
- Moved all five generic state helpers to `+analysisRun`.
- Removed separate metadata and lifecycle files.
- Replaced direct portable-reference access with the Runtime path accessor.
- Kept managed anchor editing, scale calibration, curve fitting, length measurement, overlay rendering, and exports unchanged.

## Impact

Opening current or version-1 projects, tracing/removing anchors, calibrating scale, fitting curvature, measuring length, and exporting results behave unchanged. Developers now find every durable-version rule in one file and every numerical result/task next to the numerical implementation.

## Compatibility and limits

The current payload stays at version 2. Version-1 `inputs.source` is still moved to `inputs.sources` exactly once. No new payload migration is introduced.

### Remaining limits

Other versioned Apps still use filename-per-step migrations and will move to one project entry during their own behavior audits.

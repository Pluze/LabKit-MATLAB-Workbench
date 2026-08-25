# Batch Crop assigns state to workflow capabilities

```labkit-change
id: CHG-20260716-batch-crop-structure
date: 2026-07-16
type: refactor
compatibility: compatible
component: labkit_BatchImageCrop_app | 1.7.2 -> 1.7.3
```

## Why

Batch Crop split static metadata across separate files, spread project creation, validation, migration, and session construction through a generic lifecycle package, and placed source decoding, crop-task operations, geometry, scale calibration, export planning, and transient caches together under `+appState`. The App also retained an unused scale-unit adapter and a startup callback whose only job duplicated the shared source-adjacent output-folder default.

### Accepted choice

Use the compact Runtime V2 definition and one project contract, then assign remaining helpers to the workflow capability that owns their meaning. Crop geometry, scale calibration, and export planning are real App complexity and remain App-owned; generic lifecycle and state buckets are structural debt and are removed.

## What changed

- Consolidated product metadata, version, requirements, layout, actions, presentation, renderers, and optional capabilities in `definition.m`.
- Concentrated durable creation, validation, and the version-1 upgrade in the single `projectSpec.m` entry; root `createSession.m` rebuilds transient state and lazily loads the selected source.
- Replaced embedded image data and direct path fields with canonical source records and `sourceId` task references.
- Assigned file reconstruction to `+sourceFiles`, task operations to `+cropTasks`, coordinate and cache behavior to `+cropGeometry`, calibration semantics to `+scaleCalibration`, and export state to `+resultFiles`.
- Removed the generic lifecycle/state packages, separate metadata files, redundant startup callback, and unused scale-unit wrapper.

## Impact

Multiple crop tasks per source, draggable and resizable ROIs, zoom-preserving preview edits, rotation, edge-continuous padding, pixel and physical crop modes, per-source calibration, scale bars, manifests, and exports keep their existing behavior. Empty launch no longer computes an output folder; importing sources still selects the source-adjacent default.

Developers can now find each calculation and state transition under its owning workflow concept without learning a generic App state package.

## Compatibility and limits

Version-1 saved projects upgrade automatically to schema version 2. The migration discards reconstructible embedded pixels, creates portable source records for legacy paths, and preserves crop-task settings. Runtime source reconciliation handles moved or missing required files.

### Remaining limits

Automated GUI tests do not replace manual judgment of ROI pointer feel, resampling quality, scale-reference placement, or export suitability for a particular quantitative workflow. Other Apps that still use generic lifecycle or state packages remain scheduled for the same ownership review.

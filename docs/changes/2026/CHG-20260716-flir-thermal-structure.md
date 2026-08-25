# FLIR Thermal separates durable annotations from decoded sources

```labkit-change
id: CHG-20260716-flir-thermal-structure
date: 2026-07-16
type: refactor
compatibility: compatible
component: labkit_FLIRThermal_app | 1.4.2 -> 1.4.3
```

## Why

FLIR Thermal split static metadata across files, spread a version-1 project over a generic lifecycle package, grouped decoded records, durable annotations, and numerical reading updates under `+appState`, and read nested portable reference fields in session, actions, and presentation. Its startup callback also selected an output directory before the user loaded a source.

### Accepted choice

Use the compact Runtime V2 contract while preserving the boundary between decoded radiometric data and the lightweight annotations safe to persist. Assign each remaining helper to the capability it describes instead of moving thermal semantics into the framework.

## What changed

- Consolidated product metadata, version, requirements, and optional capabilities in `definition.m`.
- Consolidated durable project creation and validation in `projectSpec.m` and moved selected-image reconstruction to root `createSession.m`.
- Moved decoded item shape to `+sourceFiles`, point/ROI updates to `+analysisRun`, and persistent per-image readings to `+thermalAnnotations`.
- Removed separate metadata files, generic lifecycle/state packages, and the redundant App startup callback.
- Replaced all direct portable-reference field access with the Runtime source path accessor.

## Impact

Radiometric decoding, Celsius conversion, range controls, point and ROI readings, viewport-preserving overlays, project reopen, and exports keep their existing behavior. Empty launch no longer chooses an output folder; adding sources still establishes the same source-adjacent default.

Developers can find transient decoded matrices, scientific readings, and durable annotations under their actual owners without learning a generic state layer.

## Compatibility and limits

The durable payload remains version 1 with identical fields and defaults. Existing projects require no migration. The removed App-specific debug line is replaced by the Runtime's standard debug-startup message.

### Remaining limits

Other Image Measurement Apps still use generic lifecycle/state packages and will be reviewed individually. Automated GUI tests do not replace manual judgment of pointer feel, visual calibration, or camera-specific accuracy.

# FLIR Thermal separates durable annotations from decoded sources

```labkit-change
schema: 2
id: LK-20260716-flir-thermal-structure
date: 2026-07-16
sequence: 98
type: refactor
compatibility: compatible
component: `labkit_FLIRThermal_app` | `1.4.2 -> 1.4.3`
scope: Image Measurement
scope: App structure
```

## Context

FLIR Thermal split static metadata across files, spread a version-1 project
over a generic lifecycle package, grouped decoded records, durable annotations,
and numerical reading updates under `+appState`, and read nested portable
reference fields in session, actions, and presentation. Its startup callback
also selected an output directory before the user loaded a source.

## Decision and rationale

Use the compact Runtime V2 contract while preserving the boundary between
decoded radiometric data and the lightweight annotations safe to persist.
Assign each remaining helper to the capability it describes instead of moving
thermal semantics into the framework.

## Changes

- Consolidated product metadata, version, requirements, and optional
  capabilities in `definition.m`.
- Consolidated durable project creation and validation in `projectSpec.m` and
  moved selected-image reconstruction to root `createSession.m`.
- Moved decoded item shape to `+sourceFiles`, point/ROI updates to
  `+analysisRun`, and persistent per-image readings to
  `+thermalAnnotations`.
- Removed separate metadata files, generic lifecycle/state packages, and the
  redundant App startup callback.
- Replaced all direct portable-reference field access with the Runtime source
  path accessor.

## User and developer impact

Radiometric decoding, Celsius conversion, range controls, point and ROI
readings, viewport-preserving overlays, project reopen, and exports keep their
existing behavior. Empty launch no longer chooses an output folder; adding
sources still establishes the same source-adjacent default.

Developers can find transient decoded matrices, scientific readings, and
durable annotations under their actual owners without learning a generic state
layer.

## Compatibility and migration

The durable payload remains version 1 with identical fields and defaults.
Existing projects require no migration. The removed App-specific debug line is
replaced by the Runtime's standard debug-startup message.

## Validation

Five unit methods cover radiometric import, thermal values, calibration
diagnostics, range controls, independent ROIs, rendering mappings, manifests,
and exported matrices. Two hidden GUI workflows cover multi-file selection,
session caching, managed region interaction, project save/load reconstruction,
shared ranges, and batch export.

## Evidence

- [FLIR Thermal](../../../../apps/image-measurement/flir-thermal/README.md)
- [Thermal Library](../../../../libraries/thermal/README.md)
- [Runtime and Lifecycle](../../../../framework/runtime.md)

## Known limitations and follow-up

Other Image Measurement Apps still use generic lifecycle/state packages and
will be reviewed individually. Automated GUI tests do not replace manual
judgment of pointer feel, visual calibration, or camera-specific accuracy.

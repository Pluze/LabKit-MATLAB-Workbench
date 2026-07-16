# Shared image facade

```labkit-change
schema: 1
id: LK-20260630-shared-image-facade
date: 2026-06-30
type: feat
compatibility: compatible
introduced: `labkit.image` | `1.0.0`
component: `labkit_BatchImageCrop_app` | `1.3.9 -> 1.4.0`
component: `labkit_CurvatureMeasurement_app` | `1.2.3 -> 1.2.4`
component: `labkit_FocusStack_app` | `1.2.5 -> 1.3.0`
component: `labkit_ImageEnhance_app` | `1.3.5 -> 1.4.0`
component: `labkit_ImageMatch_app` | `1.3.5 -> 1.4.0`
scope: historical project evolution
```

## Context

Batch Crop, Focus Stack, Image Enhance, and Image Match each carried similar
code for supported extensions, path normalization, image reads, preview sizing,
and basic enhancement. Small differences between those copies produced
inconsistent file and display behavior.

## Decision and rationale

Introduce `labkit.image` for GUI-free operations with neutral meaning, then
move the image apps to that shared API. Keep crop geometry, focus fusion,
matching, protected enhancement, and export schemas in their respective apps.

## Changes

- `labkit.image` `1.0.0`
- Batch Crop, Curvature, Focus Stack, Image Enhance, and Image Match advanced
  within their image-facade adoption lines.

- Added a GUI-free image facade for file input, display normalization, basic
  processing, and preview support.
- Adopted that facade across image-measurement apps.

## User and data impact

Supported image selection, display-name handling, preview normalization, and
common enhancement primitives became consistent across the migrated apps.
Scientific app outputs and source files did not change format.

## Compatibility and migration

Image apps kept their entry points and exports while adopting the shared
operations. App code that called the retired local helpers needed to use the
image facade or the owning app operation.

## Validation

Commit `7023e87e` added a dedicated `LabKitImageFacadeTest` suite and updated
app compatibility, package-boundary, public-surface, and focused image-app
tests.

## Evidence

- Main commit `7023e87e`.

## Known limitations and follow-up

The first facade release covered common MATLAB image formats and basic
processing only. Thermal decoding and workflow-specific algorithms remained
outside `labkit.image`.

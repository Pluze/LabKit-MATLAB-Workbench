# Image Enhance assigns state helpers to workflow capabilities

```labkit-change
id: CHG-20260716-image-enhance-structure
date: 2026-07-16
type: refactor
compatibility: compatible
component: labkit_ImageEnhance_app | 1.6.2 -> 1.6.3
```

## Why

Image Enhance split static product metadata across files, spread a version-1 project over a generic lifecycle package, and placed decoded items, durable annotations, numerical histories, preview scaling, UI normalization, and export fingerprints together under `+appState`. Source reconstruction and presentation also read nested portable-reference fields directly.

### Accepted choice

Use the compact Runtime V2 definition and project contracts, then assign each remaining concept to the workflow capability that owns its behavior. Preserve the important preview/export boundary: pixel-radius parameters scale for the downsampled preview while full-size export continues to use source coordinates.

## What changed

- Consolidated product metadata, version, requirements, and optional capabilities in `definition.m`.
- Consolidated durable creation and validation in `projectSpec.m` and moved transient reconstruction to root `createSession.m`.
- Assigned decoded items and lazy selected-image loading to `+sourceFiles`, histories and preview replay to `+analysisRun`, durable per-image data to `+enhancementAnnotations`, UI value clamping to `+userInterface`, and export fingerprints to `+resultFiles`.
- Removed separate metadata files, generic lifecycle/state packages, and the redundant App startup callback.
- Replaced direct portable-reference access with the Runtime path accessor.
- Corrected the GUI-free manual example to write the first returned image from the documented cell-array result.

## Impact

Shared and per-image histories, white ROI calibration, pending previews, preview-coordinate radius scaling, original-resolution processing, duplicate export detection, project reopen, and outputs keep their existing behavior. Empty launch no longer chooses an output folder; importing sources retains the source-adjacent default.

Developers can locate source decoding, calculations, durable annotations, and exports without learning one generic state package.

## Compatibility and limits

The durable payload remains version 1 with identical fields and defaults, so existing projects require no migration. The Runtime's standard debug-startup message replaces the removed App-specific line.

### Remaining limits

Other Apps still using generic lifecycle/state packages will be reviewed individually. Automated GUI tests do not replace manual judgment of visual quality, ROI pointer feel, or enhancement suitability for quantitative images.

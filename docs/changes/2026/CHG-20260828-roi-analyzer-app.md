# Reusable ROI pixel analysis

```labkit-change
id: CHG-20260828-roi-analyzer-app
date: 2026-08-28
type: feat
compatibility: compatible
component: labkit_ROIAnalyzer_app | new -> 1.0.0
component: labkit.app | 3.2.2 -> 3.3.0
```

## Why

LabKit image workflows could crop, enhance, match, calibrate, and measure specialized thermal or curve data, but did not provide a public general-purpose original-pixel ROI comparison workflow. A reusable public workflow needs scalar/RGB channel semantics, explicit project continuation, repeatable layouts, and geometry changes that do not destroy saved positions.

### Accepted choice

Create one Image Measurement App with shared geometry, ROI definitions, per-image centers, direct pixel statistics, an optional ROI mean-ratio denominator, project archive, parameter record, and result CSV. Keep geometry separate from placement so reopening a project can resize or reshape a shared set without moving centers. Use one managed pointer editor that distinguishes ROI hits from empty image space, allowing direct ROI dragging and marquee selection without competing plot interactions. Keep domain-specific processing, calibration, segmentation, and experiment management outside this product.

Embedding the capability in a specialized image product was rejected because a general ROI workflow needs its own image, calculation, archive, naming, and export semantics. Building a broad public ROI framework was also rejected because those scientific and workflow choices belong to this App.

## What changed

- Added ROI Analyzer for scalar-intensity and RGB images with shared rectangle, square, or circle geometry, named ROIs, per-image center placement, grouped copy/paste, placement shift, and apply-to-all actions.
- Extended the existing App SDK `pointSlots` editor with empty-space marquee selection, selected-group dragging, point hit regions, selection callbacks, and background-click placement while preserving existing single-point consumers.
- Added statistics over original-scale Intensity or R/G/B pixels and optional same-channel ratios calculated directly from ROI means.
- Added explicit MAT project save/open, path relocation, parameter-only JSON, complete current-result CSV, and an image-centered single-canvas presentation with image-by-image navigation.
- Added direct scientific oracles and a native two-image journey covering geometry separation, measurement, layout reuse, exports, and project restore.

## Impact

Users can define a repeatable intensity-measurement layout, drag ROI bodies or reliable numbered centers independently from shared geometry, marquee-select a group, and paste that group at a chosen point on the same or another image without losing its relative arrangement. Pasted names receive deterministic conflict-free suffixes. Parameter and result exports remain separate so an old table is not mistaken for a recalculation.

## Compatibility and limits

The App SDK addition is compatible within the existing version-3 range; Video Marker retains its existing single-point callback and behavior. ROI Analyzer does not implement freehand or polygon ROIs, segmentation, image registration, calibration, multispectral stacks, lanes, grids, concentration curves, or PDF experiment reports. Automated evidence uses synthetic PNGs and does not establish real-image scientific validity or visible pointer quality.

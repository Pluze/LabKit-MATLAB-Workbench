# Restore wheel zoom and context menus in image previews

```labkit-change
id: CHG-20261124-image-preview-navigation
date: 2026-11-24
type: fix
compatibility: compatible
component: labkit.app | 3.6.1 -> 3.6.2
component: labkit_ROIAnalyzer_app | 1.1.1 -> 1.1.2
component: labkit_CurvatureMeasurement_app | 1.7.3 -> 1.7.4
component: labkit_FLIRThermal_app | 1.7.3 -> 1.7.4
```

## Why

A preview can hide its axes decorations while its image remains visible. The wheel router skipped those axes, and image renderers that disabled image picking could leave users without a plot context menu over the image.

## What changed

Visible plotted children keep a decoration-free axes eligible for wheel input. ROI Analyzer, Curvature Measurement, and FLIR Thermal make their primary canvas images direct menu targets. Context clicks leave managed editing gestures idle.

## Impact

Image previews support zoom around the pointer and access to plot actions while retaining the App's existing ROI or annotation workflow.

## Compatibility and limits

Hidden workspace pages and empty hidden axes remain unavailable as wheel targets. Display overlays remain non-pickable.

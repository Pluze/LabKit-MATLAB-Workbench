# Image Measurement Apps

```labkit-page
id: apps-image-measurement
type: landing
audience: app-user
summary: Choose an image or video workflow for ROI intensity analysis, cropping, calibrated measurement, thermal analysis, fusion, enhancement, matching, or landmark annotation.
```

The Image Measurement family turns image and video data into ROI intensity statistics, repeatable crops, calibrated measurements, thermal readings, fused images, appearance pipelines, and landmark coordinates. Scientific and workflow-specific choices remain app-owned; generic image IO and primitives come from `labkit.image` and `labkit.thermal`.

## Choose An App

| Goal | App | Main result |
| --- | --- | --- |
| Compare original pixel values inside reusable regions | [ROI Analyzer](roi-analyzer/README.md) | ROI-by-channel statistics, project, parameter JSON |
| Apply repeatable crop geometry to many images | [Batch Image Crop](batch-crop/README.md) | same-size crop images and manifest |
| Measure a fitted circular arc and traced length | [Curvature Measurement](curvature/README.md) | radius, curvature, length, overlay |
| Decode and measure radiometric FLIR images | [FLIR Thermal](flir-thermal/README.md) | Celsius matrix, readings, rendered image |
| Fuse multiple focal planes | [Focus Stack](focus-stack/README.md) | all-in-focus image and depth index map |
| Apply an ordered enhancement pipeline | [Image Enhance](image-enhance/README.md) | enhanced images and processing history |
| Transfer appearance from a reference image | [Image Match](image-match/README.md) | matched images and match history |
| Mark ordered landmarks across video | [Video Marker](video-marker/README.md) | recoverable project and coordinate tables |

## Shared Interaction Conventions

Managed points, rectangles, scale references, and overlays remain editable without resetting the current zoom. A new source or project may start at a home view; ordinary marker placement, dragging, ROI resizing, and annotation refresh preserve the user's viewport. Canvas subtitles and action labels describe the active interaction mode.

Image coordinates use `[x y]` with `x` as column and `y` as row. Rectangle geometry uses `[x y width height]` unless a linked API states that it accepts two corners. Calibrated measurements always retain the pixel-domain source geometry needed for audit.

## Numeric And Display Boundaries

Display palettes, axes zoom, overlay opacity, marker appearance, and preview downsampling do not change scientific arrays. Crop geometry, scale calibration, thermal conversion, fusion parameters, enhancement steps, and coordinate transforms do affect output and remain App-owned runtime or export meaning.

## Related Modules

- [Image Library](../../../develop/libraries/image/README.md)
- [Thermal Library](../../../develop/libraries/thermal/README.md)
- [App Framework interactions](../../../develop/framework/README.md)
- [All Apps](../README.md)

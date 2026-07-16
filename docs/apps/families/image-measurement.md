# Image Measurement Apps

This family covers repeatable image preparation, calibrated measurement,
thermal inspection, appearance processing, focus fusion, and video landmark
annotation.

## Choose An App

| Task | App |
| --- | --- |
| Repeated fixed-size crops and physical scale normalization | [Batch Image Crop](../image-measurement/batch-crop.md) |
| Curve radius, curvature, and length | [Curvature Measurement](../image-measurement/curvature.md) |
| Radiometric temperature display and point/ROI measurements | [FLIR Thermal](../image-measurement/flir-thermal.md) |
| All-in-focus image fusion | [Focus Stack](../image-measurement/focus-stack.md) |
| Brightness, contrast, clarity, color, and white balance | [Image Enhance](../image-measurement/image-enhance.md) |
| Match appearance to a reference image | [Image Match](../image-measurement/image-match.md) |
| Ordered video landmarks and project/autosave recovery | [Video Marker](../image-measurement/video-marker.md) |

## Interaction Conventions

Interactive rectangles use the framework rectangle editor. Anchor and point
tools show an interaction-mode subtitle near the canvas. Adding or removing
markers, moving an ROI, or committing an overlay must preserve the user's zoom
unless the source image or explicit Fit command changes the viewport.

## Programmatic Entry Points

The [Image Library](../../api/image.md) owns reusable file and pixel operations.
Cataloged app APIs expose scientific or workflow-specific calculations such as
crop geometry, curve fitting, temperature readings, focus fusion, appearance
pipelines, coordinate export, and point tracking.

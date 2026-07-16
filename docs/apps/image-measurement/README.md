# Image Measurement Apps

This family covers repeatable image preparation, calibrated measurement,
thermal inspection, appearance processing, focus fusion, and video landmark
annotation.

## Choose An App

| Task | App |
| --- | --- |
| Repeated fixed-size crops and physical scale normalization | [Batch Image Crop](batch-crop/README.md) |
| Curve radius, curvature, and length | [Curvature Measurement](curvature/README.md) |
| Radiometric temperature display and point/ROI measurements | [FLIR Thermal](flir-thermal/README.md) |
| All-in-focus image fusion | [Focus Stack](focus-stack/README.md) |
| Brightness, contrast, clarity, color, and white balance | [Image Enhance](image-enhance/README.md) |
| Match appearance to a reference image | [Image Match](image-match/README.md) |
| Ordered video landmarks and project/autosave recovery | [Video Marker](video-marker/README.md) |

## Interaction Conventions

Interactive rectangles use the framework rectangle editor. Anchor and point
tools show an interaction-mode subtitle near the canvas. Adding or removing
markers, moving an ROI, or committing an overlay must preserve the user's zoom
unless the source image or explicit Fit command changes the viewport.

## Programmatic Entry Points

The [Image Library](../../libraries/image/README.md) owns reusable file and pixel operations.
Cataloged app APIs expose scientific or workflow-specific calculations such as
crop geometry, curve fitting, temperature readings, focus fusion, appearance
pipelines, coordinate export, and point tracking.

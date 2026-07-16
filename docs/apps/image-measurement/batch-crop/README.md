# Batch Image Crop

Batch Image Crop defines one crop task per image, previews rotation and
edge-continuous padding, and exports repeatable same-size crops in pixel or
physical-scale mode.

## Requirements And Launch

The app uses the LabKit UI framework and Image library.

```matlab
labkit_BatchImageCrop_app
```

## Inputs

Use **Add images or folder** to load supported image files. A folder selection
loads supported files from that folder. Each list row stores its own crop center,
rotation, padding, and optional scale calibration. **Duplicate image** creates
another task for the same source so multiple ROIs can be exported without
loading duplicate files.

## Basic Workflow

1. Load images and select a task.
2. Set crop width and height or switch to physical mode.
3. Drag the highlighted crop center/ROI in the preview or enter center X/Y.
4. Set rotation and padding.
5. Calibrate physical scale when required.
6. Duplicate tasks for additional ROIs.
7. Choose format and output folder, then export.

The preview rectangle remains draggable and resizable. Editing the ROI updates
the selected task immediately; switching tasks restores that task's geometry.
Marker and ROI refreshes preserve axes zoom.

## Pixel Mode

Default crop dimensions are 1024 by 1024 pixels. Rotation defaults to 0 degrees
and padding to 0%. Center controls use source-image coordinates. When crop
geometry crosses the rotated image boundary, edge-continuous padding supplies
pixels so every exported crop retains the requested dimensions.

## Physical Mode And Scale

Physical mode specifies width and height in the selected unit (default `um`).
Each source image requires a valid pixels-per-unit calibration. Measure a known
reference line, enter its physical length, and verify the displayed
pixels/unit. `targetPixelsPerUnit=0` selects an automatic common output scale;
a positive value requests an explicit scale.

The max-upsample warning defaults to 15%. It warns when a task would require
substantial interpolation; it does not silently change the requested physical
geometry. Crop and calibration units are converted explicitly.

## Scale Bar

The scale-bar length defaults to 100 selected units, at Bottom right, in Black.
Measure the reference first, then place the bar. The bar is an export overlay;
its placement does not change crop geometry or scale calculations.

## Outputs

Exports support PNG, TIFF, and JPEG. Each task produces one image at the
planned output dimensions. The crop manifest records source, task identity,
center, rotation, padding, source/output scale, requested physical geometry,
format, and output filename. A second LabKit result JSON records project-wide
parameters and identifies each output file.

## Use Without The GUI

<!-- labkit-runnable-example -->
```matlab
calibration = labkit.ui.interaction.scaleBarCalibration(20, 10, "um");
items = struct("scaleCalibration", calibration);
physicalOptions = struct( ...
    "physicalWidth", 5, "physicalHeight", 3, ...
    "scaleUnit", "um", "targetPixelsPerUnit", 4);
plan = batch_crop.cropGeometry.scalePlan(items, physicalOptions);

imageData = reshape(uint8(1:100), 10, 10);
cropOptions = struct("centerXY", [5 5]);
cropped = batch_crop.cropGeometry.cropScaledImage( ...
    imageData, cropOptions, plan);
```

For pixel-domain work use `batch_crop.cropGeometry.cropImage`. Open the linked
API pages for exact plan fields, interpolation, and padding behavior.

## Errors And Limitations

- Physical export requires a finite positive calibration for every task.
- Large upsampling cannot restore information absent from the source.
- Rotation and scale resampling can soften high-frequency detail.
- JPEG is lossy; use PNG or TIFF for quantitative downstream image analysis.

## Related Topics

- [Image Measurement family](../README.md)
- [Image Library](../../../libraries/image/README.md)
- [API Reference](../../../libraries/README.md)

## Framework Compatibility

This App uses the Runtime V2 lifecycle and requires `labkit.ui >=7 <8`. App code uses semantic actions and injected project services; busy-state and portable-reference serialization mechanics remain framework-private.

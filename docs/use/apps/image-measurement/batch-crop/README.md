# Batch Image Crop

```labkit-page
id: app-batch-crop
type: landing
audience: app-user
summary: Batch Image Crop defines one crop task per image, previews rotation and edge-continuous padding, and exports repeatable same-size crops in pixel or physical-scale mode.
```

Batch Image Crop defines one crop task per image, previews rotation and edge-continuous padding, and exports repeatable same-size crops in pixel or physical-scale mode.

Crop edits preserve the active preview viewport through the managed image interaction; the App does not keep a second private viewport snapshot.

## Requirements And Launch

```matlab
labkit_BatchImageCrop_app
```

## Inputs

Use **Add images** for selected files, **Add folder** for one directory, or **Add folder tree** for nested sources. Each list row stores its own crop center, rotation, padding, and optional scale calibration. **Duplicate image** creates another task for the same source so multiple ROIs can be exported without loading duplicate files. Duplicate tasks stay linked to the same source while each keeps its own crop and calibration settings.

Use **Restore manifest** to reopen the source images and task state recorded by a Batch Crop CSV manifest. Current manifests restore crop centers, rotation, padding, pixel or physical geometry, per-image scale, target scale, upsample warning threshold, output format, and an output folder beside the selected manifest. Only successfully saved rows from the current manifest format are restored. Restoration stops without replacing the current task if a source is missing, its pixel dimensions changed, or shared manifest settings conflict.

## Basic Workflow

1. Load images and select a task.
2. Set crop width and height or switch to physical mode.
3. Click anywhere in the preview to place the crop center. Drag the center marker or anywhere inside the highlighted ROI to move it, or enter center X/Y.
4. Set rotation and padding.
5. Calibrate physical scale when required.
6. Duplicate tasks for additional ROIs.
7. Choose format and output folder, then export. A later session can use **Restore manifest** to continue from that exported task state.

The preview rectangle remains draggable by either its center marker or its interior; a click without dragging sets its center at that preview location, including inside the rectangle. Change crop width and height with their controls. Editing the ROI updates the selected task immediately; switching tasks restores that task's geometry. ROI refreshes preserve axes zoom.

Center, rotation, and padding adjustments update the selected task and preview without recording a routine INFO message for each intermediate setting. Export milestones and actionable failures remain available in diagnostics.

## Pixel Mode

Default crop dimensions are 1024 by 1024 pixels. Rotation defaults to 0 degrees and padding to 0%. Center controls use source-image coordinates. When crop geometry crosses the rotated image boundary, edge-continuous padding supplies pixels so every exported crop retains the requested dimensions.

## Physical Mode And Scale

Physical mode specifies width and height in the selected unit (default `um`). Each source image requires a valid pixels-per-unit calibration. Measure a known reference line, enter its physical length, and verify the displayed pixels/unit. `targetPixelsPerUnit=0` selects an automatic common output scale; a positive value requests an explicit scale.

The max-upsample warning defaults to 15%. It warns when a task would require substantial interpolation; it does not silently change the requested physical geometry. Crop and calibration units are converted explicitly.

## Scale Bar

The scale-bar length defaults to 100 selected units, at Bottom right, in Black. Measure the reference first, then place the bar. The bar is an export overlay; its placement does not change crop geometry or scale calculations.

## Outputs

Exports support PNG, TIFF, and JPEG. Each task produces one image at the planned output dimensions. The crop manifest records source, task order, center, rotation, padding, source/output scale, requested physical geometry, upsample threshold, format, and output filename. These fields form the restorable operation snapshot. The manifest is one final snapshot; it does not retain intermediate adjustments or merge multiple export batches.

## Use Without The GUI

<!-- labkit-runnable-example -->
```matlab
calibration = labkit.app.interaction.scaleCalibration(20, 10, "um");
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

For pixel-domain work use `batch_crop.cropGeometry.cropImage`. Open the linked API pages for exact plan fields, interpolation, and padding behavior.

## Function Reference

The generated crop-geometry pages document pixel coordinates, rounding, padding, scaling plans, per-image option fields, defaults, output metadata, failure behavior, and related APIs. Start with [`cropScaledImage`](../../../../reference/api/batch_crop/cropGeometry/cropScaledImage.html) when reproducing a physical-scale export outside the GUI.

## Errors And Limitations

- Physical export requires a finite positive calibration for every task.
- Large upsampling cannot restore information absent from the source.
- Rotation and scale resampling can soften high-frequency detail.
- JPEG is lossy; use PNG or TIFF for quantitative downstream image analysis.
- Manifest restoration verifies source pixel dimensions but cannot prove that unchanged-size source pixels are identical to those used for the export.

## Related Topics

- [Image Measurement family](../README.md)
- [Image Library](../../../../develop/libraries/image/README.md)
- [API Reference](../../../../reference/README.md)

# Image Enhance

```labkit-page
id: app-image-enhance
type: landing
audience: app-user
summary: Image Enhance builds an ordered, reversible processing history for one image or a batch and exports the resulting images with a completion manifest.
```

Image Enhance builds an ordered, reversible processing history for one image or a batch and exports the resulting images with a completion manifest.

Preview and export use the current processing history directly, keeping one authoritative sequence for both outcomes.

## Requirements And Launch

All processing uses MATLAB and repository-owned code.

```matlab
labkit_ImageEnhance_app
```

## Inputs And Batch Mode

The batch accepts selected image files; directory actions can collect a flat or recursive image set. In **Batch shared processing** mode, one shared step history is applied to every source. When batch mode is off, each image keeps a separate history and optional white ROI. Selecting another image updates the preview without recalculating unrelated files.

## Basic Workflow

1. Load images and select a representative source.
2. Decide whether steps are shared across the batch.
3. Choose a tool and set its controls; the two adjustment labels update to show that tool's parameter names and units.
4. For White ROI calibration, turn off batch mode and draw the white-background ROI for the selected image.
5. Apply the tool to history and inspect Enhanced, Original, or Before | After.
6. Undo or reset history as needed.
7. Choose output format/folder and export.

Each **Apply tool** action saves one processing step. Panner changes preview the pending tool without changing the saved history until **Apply tool** is chosen. ROI creation, enhancement updates, and overlay refresh preserve the current zoom on the same canvas. Selecting another source, changing the displayed canvas size, or entering/leaving the side-by-side comparison fits the new preview composition.

## Tools And Defaults

| Tool | Primary control | Secondary control |
| --- | --- | --- |
| Brightness/contrast | Brightness 0% | Contrast 15% |
| Local contrast | Clarity 30% | Radius 12 px |
| Sharpen | Sharpen 35% | Radius 1.5 px |
| Hue/saturation | Hue 0 degrees | Saturation 10% |
| White balance | Strength 100% | Temperature 0% |
| White ROI calibration | Strength 100% | White target 92% |
| Subject-preserving enhance | Strength 70% | Background target 90% |

Processing converts input to RGB double in `[0,1]`, applies steps in table order, and clamps the final image. Brightness, local contrast, sharpening, hue/saturation, and gray-world white balance call the linked `labkit.image` primitives.

White ROI calibration is available only with batch mode off and requires a valid rectangle for the selected image. It builds a softened background mask from the rectangle and adjusts luminance toward the target while limiting subject changes. Subject-preserving enhance estimates a low-saturation bright background automatically and uses a whole image fallback only when no usable background support is found.

## History And Reproducibility

The history table records step kind and settings in execution order. **Undo history** removes the latest applied step; **Reset history** returns to the normalized original. Source images are not modified. Shared and per-image histories are stored separately in in-memory App state so switching batch mode does not ambiguously merge them.

## Outputs

Export supports PNG, TIFF, and JPEG. Each output is rendered from the source plus its effective stored pipeline, not from a downsampled preview. The CSV manifest records source and output paths, status, output dimensions, step count, and a message. Each explicit export reads the source files again and writes a new output set with unique filenames. The manifest does not store step settings or ROI geometry, and the App does not write a result JSON or a restorable task. Record those settings separately when reproducibility is required.

## Use Without The GUI

```matlab
steps = [ ...
    image_enhance.analysisRun.makeStep("Brightness/contrast", 0, 15), ...
    image_enhance.analysisRun.makeStep("Local contrast", 30, 12), ...
    image_enhance.analysisRun.makeStep("Sharpen", 35, 1.5)];
output = image_enhance.analysisRun.applyPipeline(imread("source.png"), steps);
imwrite(output{1}, "enhanced.png");
```

## Runtime State

The current task keeps source paths, shared and per-image step histories, white-reference ROIs, export settings, and compact result metadata while the App is open. Full-size pixels and downsampled previews remain reconstructible from the selected source files.

An empty launch does not choose an output directory. Adding images establishes the source-adjacent default; **Choose folder** remains available before export.

## Errors And Limitations

- Unknown step labels are rejected.
- An unreadable selected image reports the source problem.
- White ROI calibration fails when a required image has no valid ROI.
- Enhancement changes pixel values and can invalidate quantitative intensity analysis; retain the source, processing settings, and manifest.
- JPEG export adds lossy compression after processing.

Subject-preserving enhancement identifies bright, low-saturation backgrounds with a descending saturation mask. A saturated subject does not become the white-background reference merely because its saturation is higher.

## Related Topics

- [Image Match](../image-match/README.md)
- [Image Library](../../../../develop/libraries/image/README.md)
- [API Reference](../../../../reference/README.md)

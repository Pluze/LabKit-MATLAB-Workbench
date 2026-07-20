# Image Enhance

Image Enhance builds an ordered, reversible processing history for one image
or a batch and exports the resulting images with the exact step sequence.

## Requirements And Launch

The app uses the LabKit UI framework and Image library. All processing is implemented
with MATLAB and repository-owned code.

```matlab
labkit_ImageEnhance_app
```

## Inputs And Batch Mode

Add supported image files or a folder. In **Batch shared processing** mode, one
shared step history is applied to every source. When batch mode is off, each
image keeps a separate history and optional white ROI. Selecting another image
updates the preview without recalculating unrelated files.

## Basic Workflow

1. Load images and select a representative source.
2. Decide whether steps are shared across the batch.
3. Choose a tool and set its controls.
4. For White ROI calibration, draw the white-background ROI first.
5. Apply the tool to history and inspect Enhanced, Original, or Before | After.
6. Undo or reset history as needed.
7. Choose output format/folder and export.

Each **Apply tool** action saves one processing step. Panner changes preview the
pending tool without changing the saved history until **Apply tool** is chosen.
ROI creation and overlay refresh preserve the current zoom.

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

Processing converts input to RGB double in `[0,1]`, applies steps in table
order, and clamps the final image. Brightness, local contrast, sharpening,
hue/saturation, and gray-world white balance call the linked `labkit.image`
primitives.

White ROI calibration requires a valid rectangle for every affected image. It
builds a softened background mask from the rectangle and adjusts luminance
toward the target while limiting subject changes. Subject-preserving enhance
estimates a low-saturation bright background automatically and uses a whole
image fallback only when no usable background support is found.

## History And Reproducibility

The history table records step kind and settings in execution order. **Undo
history** removes the latest applied step; **Reset history** returns to the
normalized original. Source images are not modified. Shared and per-image
histories are stored separately in project state so switching batch mode does
not ambiguously merge them.

## Outputs

Export supports PNG, TIFF, and JPEG. Each output is rendered from the source
plus its effective stored pipeline, not from a downsampled preview. The export
manifest records source, ordered steps, ROI geometry, batch mode, format, and
output filename. A LabKit result JSON records the complete output set and the
project parameters used to create it.

## Use Without The GUI

```matlab
steps = [ ...
    image_enhance.analysisRun.makeStep("Brightness/contrast", 0, 15), ...
    image_enhance.analysisRun.makeStep("Local contrast", 30, 12), ...
    image_enhance.analysisRun.makeStep("Sharpen", 35, 1.5)];
output = image_enhance.analysisRun.applyPipeline(imread("source.png"), steps);
imwrite(output{1}, "enhanced.png");
```

## Project And State

Saved projects keep portable source references, shared and per-image step
histories, white-reference ROIs, export settings, and compact result metadata.
Decoded full-size pixels and downsampled previews remain transient. App SDK runtime
resolves source references first; `createSession.m` then rebuilds only the
selected source and its preview when a project opens.

An empty launch does not choose an output directory. Adding images establishes
the source-adjacent default; **Choose folder** remains available before export.

## Errors And Limitations

- Unknown step labels are rejected.
- Reopening a project with an existing unreadable image aborts restore and
  preserves the current document instead of displaying an empty preview.
- White ROI calibration fails when a required image has no valid ROI.
- Enhancement changes pixel values and can invalidate quantitative intensity
  analysis; retain the source and manifest.
- JPEG export adds lossy compression after processing.

## Related Topics

- [Image Match](../image-match/README.md)
- [Image Library](../../../libraries/image/README.md)
- [API Reference](../../../reference/README.md)

## Framework Compatibility

The single `definition.m` owns product metadata, requirements, layout, actions,
presentation, renderer, and debug-sample capability. `projectSpec.m` is the
only durable-project entry; the version-1 payload needs creation and validation
but no migration. Root `createSession.m` rebuilds the selected image cache after
App SDK runtime resolves sources.

The project validator requires the image-source collection and checks export,
shared-history, and per-image annotation relationships; Runtime validates
canonical buckets and each source record first.

Decoded items and lazy preview loading live with `+sourceFiles`; step shapes,
active histories, pipeline replay, and preview-coordinate scaling live with
`+analysisRun`; durable per-image histories live with
`+enhancementAnnotations`; export fingerprints live with `+resultFiles`.
There is no generic `+appState` package. The App requires
`labkit.app >=1 <2` and `labkit.image >=2 <3`; persistence, source-path access,
busy state, and managed ROI interaction remain framework-owned. Batch manifest
outputs use the framework's canonical empty output array, so export validation
applies only to real enhanced-image records.

Its session factory returns only App-specific selection, draft workflow, view,
and preview-cache fields. Runtime supplies absent canonical buckets and owns
workflow-log initialization.

The semantic layout follows the [Runtime callback contract](../../../framework/guides/runtime.md#layout-and-action-rules):
every control and plot names its concrete callback or renderer, and the
definition validates those bindings before creating a figure.

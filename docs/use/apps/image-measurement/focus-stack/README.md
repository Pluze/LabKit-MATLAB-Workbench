# Focus Stack

```labkit-page
id: app-focus-stack
type: landing
audience: app-user
summary: Focus Stack fuses at least two focal planes into one all-in-focus image using multilevel Laplacian focus evidence and exports a focus-depth index map.
```

Focus Stack fuses at least two focal planes into one all-in-focus image using multilevel Laplacian focus evidence and exports a focus-depth index map.

The preview is derived directly from the selected focal plane and current stack result; changing selection does not retain an independent preview copy.

## Requirements And Launch

Inputs should show the same field of view at different focus positions.

```matlab
labkit_FocusStack_app
```

## Inputs

Choose focal planes directly, or discover them from a flat or nested image directory. Remove blurred, displaced, or otherwise invalid frames before running. The first image defines working geometry; differently sized inputs are resized and the result records how many images required resizing.

Sources, fusion settings, and computed results remain in memory while the App is open. Reopen the source images to start another session; the App does not save or restore a stack project.

## Basic Workflow

1. Load at least two focal planes.
2. Remove frames that do not belong to the stack.
3. Start with the Balanced preset.
4. Enable auto-registration when the stack has small rigid camera motion.
5. Tune detail scale, blend radius, and uncertain blend only when artifacts are visible.
6. Run the stack and inspect the fused image, focus map, and confidence map side by side.
7. Export fused PNG, focus-map PNG, and summary CSV.

Selecting new focal-plane sources or completing a new fusion fits the result canvas. Status, table, and presentation-only redraws of the same result preserve the current zoom.

## Algorithm

Images are normalized to grayscale or RGB double data on common geometry. A Gaussian/Laplacian pyramid is built for each plane. Local squared Laplacian detail energy chooses the strongest plane at each level. Confidence is the relative separation between the best and second-best evidence.

High-confidence regions use the winning plane. Low-confidence regions blend normalized evidence weights; zero-evidence regions use equal weights. The weights are spatially smoothed by the level-scaled blend radius and the fused pyramid is reconstructed and clamped to `[0,1]`.

The confidence view displays the existing full-resolution score on a fixed 0–1 color scale. It measures relative separation between the best and second-best detail scores; it is not a calibrated probability, valid-registration mask, or physical depth measurement. Changing fusion parameters clears old quality views until the next run. Grayscale fused data is displayed as true grayscale independently of the quality color maps.

The focus index is the winning input plane at full resolution. Focus coverage is the fraction of pixels assigned to each plane. The algorithm does not correct parallax, deformation, moving objects, illumination changes, or severe registration error.

## Fusion Parameters

| Parameter | Default | Meaning |
| --- | ---: | --- |
| Preset | Balanced | coordinated starting values; Crisp favors fine detail, Smooth favors seam suppression, Noisy favors grain tolerance |
| Auto-register | off | register images to the middle image before fusion |
| Detail scale | 31 px | odd local window for focus-energy evidence |
| Blend radius | 4 px | smooth focus-selection weights across boundaries |
| Uncertain blend | 5% | blend competing planes where focus confidence is low |

The public calculation API also accepts `minConfidence` (default 0.05) and `pyramidLevels` (default 4, bounded by image geometry).

## Outputs

- fused all-in-focus image;
- integer focus-depth index map;
- confidence map and per-plane focus coverage in the run result;
- summary CSV with geometry, parameters, confidence, coverage, registration, and resize information.

## Use Without The GUI

```matlab
images = {imread("z01.png"), imread("z02.png"), imread("z03.png")};
options = struct("focusWindow", 31, "smoothRadius", 4, ...
    "minConfidence", 0.05, "pyramidLevels", 4);
result = focus_stack.analysisRun.computeFocusStack(images, options);
assert(result.ok, result.message);
imwrite(result.fused, "stacked.png");
```

Pyramid resampling supports small images and singleton rows or columns by treating the singleton axis as constant. A one-pixel image supplies intensity only, not spatial focus information.

## Errors And Limitations

- Fewer than two images is an error.
- An unreadable source reports a loading failure; correct or remove that source before fusion.
- `minConfidence` must be finite and between 0 and 1.
- Resizing changes sampling and should not substitute for consistent capture.
- Auto-registration should be reviewed; a wrong registration can create a sharp-looking but geometrically false composite.

## Related Topics

- [Image Measurement family](../README.md)
- [Image Library](../../../../develop/libraries/image/README.md)
- [API Reference](../../../../reference/README.md)

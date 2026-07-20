# Focus Stack

Focus Stack fuses at least two focal planes into one all-in-focus image using
multilevel Laplacian focus evidence and exports a focus-depth index map.

## Requirements And Launch

The app uses the LabKit UI framework and Image library. Inputs should show the same
field of view at different focus positions.

```matlab
labkit_FocusStack_app
```

## Inputs

Add selected image files or choose a folder. Remove blurred, displaced, or
otherwise invalid frames before running. The first image defines working
geometry; differently sized inputs are resized and the result records how many
images required resizing.

## Basic Workflow

1. Load at least two focal planes.
2. Remove frames that do not belong to the stack.
3. Start with the Balanced preset.
4. Enable auto-registration when the stack has small rigid camera motion.
5. Tune detail scale, blend radius, and uncertain blend only when artifacts
   are visible.
6. Run the stack and inspect both fused image and focus map.
7. Export fused PNG, focus-map PNG, and summary CSV.

## Fusion Parameters

| Parameter | Default | Meaning |
| --- | ---: | --- |
| Preset | Balanced | coordinated starting values; Crisp favors fine detail, Smooth favors seam suppression, Noisy favors grain tolerance |
| Auto-register | off | register images to the middle image before fusion |
| Detail scale | 31 px | odd local window for focus-energy evidence |
| Blend radius | 4 px | smooth focus-selection weights across boundaries |
| Uncertain blend | 5% | blend competing planes where focus confidence is low |

The public calculation API also accepts `minConfidence` (default 0.05) and
`pyramidLevels` (default 4, bounded by image geometry).

## Algorithm

Images are normalized to grayscale or RGB double data on common geometry. A
Gaussian/Laplacian pyramid is built for each plane. Local squared Laplacian
detail energy chooses the strongest plane at each level. Confidence is the
relative separation between the best and second-best evidence.

High-confidence regions use the winning plane. Low-confidence regions blend
normalized evidence weights; zero-evidence regions use equal weights. The
weights are spatially smoothed by the level-scaled blend radius and the fused
pyramid is reconstructed and clamped to `[0,1]`.

The focus index is the winning input plane at full resolution. Focus coverage
is the fraction of pixels assigned to each plane. The algorithm does not
correct parallax, deformation, moving objects, illumination changes, or severe
registration error.

## Outputs

- fused all-in-focus image;
- integer focus-depth index map;
- confidence map and per-plane focus coverage in the run result;
- summary CSV with geometry, parameters, confidence, coverage, registration,
  and resize information;
- result provenance manifest.

## Use Without The GUI

```matlab
images = {imread("z01.png"), imread("z02.png"), imread("z03.png")};
options = struct("focusWindow", 31, "smoothRadius", 4, ...
    "minConfidence", 0.05, "pyramidLevels", 4);
result = focus_stack.analysisRun.computeFocusStack(images, options);
assert(result.ok, result.message);
imwrite(result.fused, "stacked.png");
```

## Errors And Limitations

- Fewer than two images is an error.
- Reopening a saved stack is strict: an existing image that cannot be decoded
  aborts restore and leaves the current document unchanged.
- `minConfidence` must be finite and between 0 and 1.
- Resizing changes sampling and should not substitute for consistent capture.
- Auto-registration should be reviewed; a wrong registration can create a
  sharp-looking but geometrically false composite.

## Related Topics

- [Image Measurement family](../README.md)
- [Image Library](../../../libraries/image/README.md)
- [API Reference](../../../reference/README.md)

## Framework Compatibility

The single `definition.m` owns product metadata, requirements, layout, actions,
presentation, renderers, and debug-sample capability. `projectSpec.m` is the
only durable-project entry; the version-1 project needs creation and validation
but no migration. Root `createSession.m` rebuilds decoded images after the App
SDK runtime resolves sources.

The project validator requires the image-source collection and checks fusion
parameters; Runtime validates canonical buckets and each source record first.

Fusion result defaults, preset values, and deterministic run fingerprints live
with the computation under `+analysisRun`; there is no generic `+appState`
package. A new empty project performs no App-specific startup callback and
chooses an output location only after sources are added or the user exports.
The App requires `labkit.app >=1 <2` and `labkit.image >=2 <3`; source-path
access, persistence, busy state, and debug lifecycle remain framework-owned.

Its session factory returns only App-specific registration workflow and image
cache fields. Runtime supplies absent canonical buckets and owns workflow-log
initialization.

The semantic layout follows the [Runtime callback contract](../../../framework/guides/runtime.md#layout-and-action-rules):
every referenced action must be registered and resolves during layout construction.

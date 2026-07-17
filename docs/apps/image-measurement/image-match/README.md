# Image Match

Image Match transfers tone and color statistics from one reference image to
one or more source images while preserving each source image's geometry.

## Requirements And Launch

The app uses the LabKit UI framework and Image library. It performs appearance
matching only; it does not geometrically register images.

```matlab
labkit_ImageMatch_app
```

## Inputs

Choose one reference image and add source images or a source folder. The
reference supplies appearance statistics and is not exported as a matched
source. All images are normalized to RGB double data in `[0,1]`; output retains
the source height and width.

## Basic Workflow

1. Choose the reference and source images.
2. Select a matching method.
3. Set overall, tone, and color strength.
4. Apply the match to history.
5. Inspect Matched, Original, and Before | After views.
6. Undo/reset history or add another step.
7. Export matched images.

Changing method or strength previews the pending match; **Apply match** saves
the settings as the next step in the image's processing history.

## Matching Methods

| Method | Behavior |
| --- | --- |
| Balanced | robust white-point match followed by Lab-style tone/color transfer |
| White balance | match robust bright-neutral RGB white points |
| Tone only | quantile-match Lab lightness only |
| Protected tone | constrained luminance/background adjustment with shadow, highlight, and saturation guards |
| Lab style | quantile-match lightness and covariance-match Lab chroma |
| Histogram | independently quantile-match all three Lab channels |

Overall strength blends the matched result with the original. Tone and color
strength separately blend lightness and chroma behavior where the selected
method supports them. All three default to 100%.

Robust statistics and covariance regularization handle flat or nearly
single-color images, but a visually dissimilar reference can still produce an
unhelpful result. Matching reproduces distributions, not semantic lighting or
camera calibration.

## History And Outputs

Each source is recomputed from its original plus the ordered match history.
Undo removes the latest step and reset removes all steps. Export supports PNG,
TIFF, and JPEG and writes an image manifest containing reference/source
identity, method, strengths, history, format, and output filenames. Source and
reference files are never overwritten.

## Use Without The GUI

```matlab
source = imread("source.png");
reference = imread("reference.png");
step = image_match.analysisRun.makeStep("Balanced", 100, 100, 100);
matched = image_match.analysisRun.applyMatch(source, reference, step);

% Apply a stored sequence:
outputs = image_match.analysisRun.applyPipeline({source}, step, reference);
output = outputs{1};
```

## Errors And Limitations

- An empty reference returns normalized source data in the calculation API,
  but the app requires a reference before enabling match actions.
- Matching never corrects position, scale, rotation, perspective, or parallax.
- Histogram and Lab matching can shift scientifically meaningful pixel values;
  retain original images for quantitative analysis.
- JPEG export is lossy.

## Related Topics

- [Image Enhance](../image-enhance/README.md)
- [Image Library](../../../libraries/image/README.md)
- [API Reference](../../../libraries/README.md)

## Framework Compatibility

The single `definition.m` owns product metadata, requirements, layout, actions,
presentation, renderers, and debug-sample capability. `projectSpec.m` is the
only durable-project entry; the version-1 project needs creation and validation
but no migration. Root `createSession.m` reconstructs only the selected source,
reference, and preview caches after Runtime V2 resolves sources.

Source item records live in `+sourceFiles`, matching steps in `+analysisRun`,
and deterministic export tasks in `+resultFiles`; there is no generic
`+appState` package. A new empty project performs no App-specific startup
callback and chooses its output directory after source selection or explicit
user choice. The App requires `labkit.ui >=7 <8` and `labkit.image >=2 <3`;
source-path access, persistence, busy state, and debug lifecycle remain
framework-owned.

Matched-image manifest outputs use the framework's canonical empty output
array, so export validation applies only to real output records.

Its session factory returns only App-specific selection, draft workflow, view,
and matched-preview cache fields. Runtime supplies absent canonical buckets and
owns workflow-log initialization.

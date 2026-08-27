# Image Match

```labkit-page
id: app-image-match
type: landing
audience: app-user
summary: Image Match transfers tone and color statistics from one reference image to one or more source images while preserving each source image's geometry.
```

Image Match transfers tone and color statistics from one reference image to one or more source images while preserving each source image's geometry.

Preview details are derived from the selected source and its current matching history, rather than retained in a parallel presentation model.

## Requirements And Launch

The app performs appearance matching only; it does not geometrically register images.

```matlab
labkit_ImageMatch_app
```

## Inputs

Choose one reference image. Sources may be selected individually or discovered from a flat or nested directory; the reference remains a separate single-file role. It supplies appearance statistics and is not exported as a matched source. All images are normalized to RGB double data in `[0,1]`; output retains the source height and width.

## Basic Workflow

1. Choose the reference and source images.
2. Select a matching method.
3. Set overall, tone, and color strength.
4. Apply the match to history.
5. Inspect Matched, Original, and Before | After views.
6. Undo/reset history or add another step.
7. Export matched images.

Changing method or strength previews the pending match; **Apply match** saves the settings as the next step in the image's processing history.

Pending and applied matching updates preserve the current zoom while the selected source and preview composition stay the same. Selecting another source, changing the displayed canvas size, or entering/leaving the side-by-side comparison fits the new preview composition.

## Matching Methods

| Method | Behavior |
| --- | --- |
| Balanced | robust white-point match followed by Lab-style tone/color transfer |
| White balance | match robust bright-neutral RGB white points |
| Tone only | quantile-match Lab lightness only |
| Protected tone | constrained luminance/background adjustment with shadow, highlight, and saturation guards |
| Lab style | quantile-match lightness and covariance-match Lab chroma |
| Histogram | independently quantile-match all three Lab channels |

Overall strength blends the matched result with the original. Tone and color strength separately blend lightness and chroma behavior where the selected method supports them. All three default to 100%.

Robust statistics and covariance regularization handle flat or nearly single-color images, but a visually dissimilar reference can still produce an unhelpful result. Matching reproduces distributions, not semantic lighting or camera calibration.

## History And Outputs

Each source is recomputed from its original plus the ordered match history. Undo removes the latest step and reset removes all steps. Export supports PNG, TIFF, and JPEG and writes an image manifest containing reference/source identity, method, strengths, history, format, and output filenames. Source and reference files are never overwritten.

## Runtime State

The reference, source paths, ordered match histories, preview selection, and export choices remain in memory while the app is open. Image Match does not create or reopen a task archive; its manifest records completed outputs and the processing decisions used to produce them.

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

## Function Reference

The generated pages for [`applyMatch`](../../../../reference/api/image_match/analysisRun/applyMatch.html) and [`applyPipeline`](../../../../reference/api/image_match/analysisRun/applyPipeline.html) document supported step fields and defaults, normalization and output geometry, empty-input behavior, failures, examples, and related APIs.

## Errors And Limitations

- An empty reference returns normalized source data in the calculation API, but the app requires a reference before enabling match actions.
- Matching never corrects position, scale, rotation, perspective, or parallax.
- Histogram and Lab matching can shift scientifically meaningful pixel values; retain original images for quantitative analysis.
- JPEG export is lossy.

## Related Topics

- [Image Enhance](../image-enhance/README.md)
- [Image Library](../../../../develop/libraries/image/README.md)
- [API Reference](../../../../reference/README.md)

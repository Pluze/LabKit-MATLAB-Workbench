# Image API

[Public API index](../README.md) | [App guide](../../apps/README.md)

`labkit.image.*` provides GUI-free image file IO, conversion, preview sizing,
and common enhancement operations. App-specific registration, measurement,
ROI, matching, and export workflows build on these functions.

`labkit.image.version()` returns image-library version and compatibility
information used by App `definition.m` requirement declarations.

## Common Calls

```matlab
filter = labkit.image.fileDialogFilter("IncludeAll", true);
paths = labkit.image.normalizePaths(rawPaths);
records = labkit.image.readFiles(paths);

source = labkit.image.im2double(records(1).image);
preview = labkit.image.ensureRgb(source);
preview = min(max(preview, 0), 1);
luma = labkit.image.rgb2gray(preview);
[preview, scale] = labkit.image.resizeToFit(preview, "MaxHeight", 1500);
[preview, budget] = labkit.image.previewBudget(preview, "MaxPixels", 1.2e6);

blurred = labkit.image.meanFilter2(preview(:, :, 1), 7);
enhanced = labkit.image.adjustBrightnessContrast(preview, 10, 20);
enhanced = labkit.image.localContrast(enhanced, 50, 3);
enhanced = labkit.image.sharpen(enhanced, 30, 1.5);
enhanced = labkit.image.grayWorldWhiteBalance(enhanced, 80, 0);

labkit.image.writeFile(enhanced, outputPath);
```

## Normalization Helpers

`labkit.image.im2double` follows the MATLAB `im2double` call contract for
supported numeric image classes, including the optional `"indexed"` mode.

`labkit.image.rgb2gray` follows the MATLAB `rgb2gray` call contract for RGB
images and colormaps while using the documented Rec.601 luma transform.

`labkit.image.ensureRgb` changes channel shape only. It expands grayscale data
to three channels or drops channels after RGB without changing class or sample
values. Callers that need display-ready RGB data explicitly compose
`im2double`, `ensureRgb`, and `[0, 1]` clamping as shown above.

## Provided Operations

The module provides:

- supported source-image extension lists and file-dialog filters
- path normalization and display names
- `imread`/`imwrite` wrappers that normalize app-facing edge behavior
- MATLAB-compatible image conversion, explicit RGB shaping, preview-size fitting,
  and edge-normalized mean filtering
- display-pixel budget helpers for responsive previews while preserving a
  documented integer coordinate scale
- generic image enhancement primitives such as brightness/contrast, HSV
  hue/saturation, gray-world white balance, local contrast, and sharpening

Applications add:

- which filters or processing steps appear in the app UI
- parameter labels, defaults, validation ranges, and step history semantics
- reference matching, protected background/ROI behavior, scientific formulas,
  crop geometry, focus stacking, curvature, and DIC processing
- export manifests, result columns, filenames, failed-row policy, alerts, and
  log text

Use `labkit.image.readFiles` when an app needs generic source-image records.
Apps may copy the returned `path`, `name`, and `image` fields into their own
item structures. Specialized formats and result structures remain documented
by the app that uses them.

## Reference Contract

The generated Image API pages linked from the [public API index](../README.md)
document exact syntax, inputs, outputs, implemented options and defaults,
legal values, failure behavior, examples, and related functions. In
particular, [`resizeToFit`](../../reference/api/labkit/image/resizeToFit.html)
accepts only the documented `"bilinear"` and `"nearest"` methods and rejects
any other method instead of silently selecting an interpolation policy.

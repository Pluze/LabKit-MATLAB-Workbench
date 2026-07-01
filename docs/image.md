# Image Facade

`labkit.image.*` is the GUI-free facade for reusable image file IO and basic
image processing primitives. It is intentionally not an image-workflow engine:
apps still own tool lists, parameter presets, ROI policy, matching workflows,
crop/export schemas, result tables, alerts, and log wording.

`labkit.image.version()` returns the image facade contract version used by app
`requirements.m` declarations.

## Common Calls

```matlab
filter = labkit.image.fileDialogFilter("IncludeAll", true);
paths = labkit.image.normalizePaths(rawPaths);
records = labkit.image.readFiles(paths);

preview = labkit.image.toRgbDouble(records(1).image);
[preview, scale] = labkit.image.resizeToFit(preview, "MaxHeight", 1500);

blurred = labkit.image.meanFilter2(preview(:, :, 1), 7);
enhanced = labkit.image.adjustBrightnessContrast(preview, 10, 20);
enhanced = labkit.image.localContrast(enhanced, 50, 3);
enhanced = labkit.image.sharpen(enhanced, 30, 1.5);
enhanced = labkit.image.grayWorldWhiteBalance(enhanced, 80, 0);

labkit.image.writeFile(enhanced, outputPath);
```

## Ownership

The facade may own:

- supported source-image extension lists and file-dialog filters
- path normalization and display names
- `imread`/`imwrite` wrappers that normalize app-facing edge behavior
- RGB double conversion, preview-size fitting, and edge-normalized mean
  filtering
- generic image enhancement primitives such as brightness/contrast, HSV
  hue/saturation, gray-world white balance, local contrast, and sharpening

Apps own:

- which filters or processing steps appear in the app UI
- parameter labels, defaults, validation ranges, and step history semantics
- reference matching, protected background/ROI behavior, scientific formulas,
  crop geometry, focus stacking, curvature, and DIC processing
- export manifests, result columns, filenames, failed-row policy, alerts, and
  log text

Use `labkit.image.readFiles` when an app needs generic source-image records.
Apps may copy the returned `path`, `name`, and `image` fields into their own
item structs. Keep app-owned readers when the app item shape is part of its
state contract.

## Promotion Rule

Promote image behavior into `labkit.image` only when it is GUI-free, reusable
outside one workflow, independently testable, and has a neutral name. Do not
promote app-specific workflow semantics simply because two image apps both use
images.

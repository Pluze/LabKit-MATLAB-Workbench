# ROI Analyzer

```labkit-page
id: app-roi-analyzer
type: landing
audience: app-user
summary: ROI Analyzer places reusable rectangular, square, or circular regions on scalar or RGB images and compares statistics calculated directly from original pixel values.
```

ROI Analyzer measures and compares original pixel values inside reusable regions of interest. It supports scalar-intensity and RGB images, multiple named ROIs per image, shared geometry, repeatable layouts across images, explicit project continuation, and separate parameter and result exports.

## Requirements And Launch

ROI Analyzer uses Base MATLAB and the LabKit image reader. It does not require Image Processing Toolbox.

```matlab
labkit_ROIAnalyzer_app
```

## Shortest Workflow

1. Choose **Add images** and select one or more images.
2. Use **Previous image** and **Next image** to keep the active source visible in the single image workspace.
3. Choose **Add ROI**, rename it, and drag inside it to place it over the feature to measure.
4. Set the shared shape, width, and height beside the current-image ROI table.
5. Add more ROIs; drag empty image space to select a group when you need to move or copy several together.
6. Optionally choose a **Ratio denominator ROI** for direct ROI-to-ROI mean ratios.
7. Choose **Measure ROIs**, then review the overlay and ROI-by-channel table and export CSV when ready.

Measurements use the full-resolution source image. Preview downsampling, zoom, display scaling, and overlay appearance never change measurement values.

## ROI Geometry And Placement

Each ROI has three separate kinds of state:

- reusable geometry: rectangle, square, or circle plus width and height in pixels;
- definition: name and geometry identity;
- placement: center X and center Y for one image.

Dragging inside an ROI changes only its placement. The center handle remains usable even when the ROI is only a few pixels wide. Dragging from empty image space draws a selection box and highlights every enclosed ROI; dragging any highlighted ROI then moves the selected group together. Editing **Shared shape**, **Shared width**, or **Shared height** resizes or reshapes the ROI set without moving centers. Square and circle geometry keeps equal width and height.

The **Images + ROIs** page owns normal image-by-image measurement: source navigation, selection, copy/paste, shared shape and size, placement, and quantification. The **Layout Tools** page contains only explicit whole-image or all-image placement transforms.

There is one copy-and-paste workflow. Select one or more ROIs, press **Copy selected**, remain on the current image or navigate to another image, and press **Paste**. On the same image the App requests a 10-pixel right-and-down shift, reduced only as needed to keep the complete group inside the image. On another image the App preserves the source coordinates when the complete group fits; otherwise it centers the group while preserving every relative position. If the group cannot fit without changing its geometry or relative layout, the App reports the problem and does not paste a partial group. Pasted ROIs remain selected for immediate group dragging. Existing destination names are never reused: the App adds **copy**, **copy 2**, and later numeric suffixes as needed.

**Replace every image with this ROI set** remains a separate explicit batch operation because it replaces each complete destination set rather than adding a copied selection. Pixel offsets under **Move ROI placements** shift every ROI on the current image or every stored image.

When shared geometry or a shifted placement would extend beyond an image, ROI Analyzer clamps it into the valid pixel canvas. For strict between-image comparison, use images with matching dimensions and registration.

## Direct Pixel Measurements And Ratios

Every reported statistic is calculated directly from pixels inside the displayed ROI geometry. The App does not apply a calibration, color transform, or domain-specific correction.

When **Ratio denominator ROI** is **None**, `Ratio` is `NaN`. When a denominator is selected, each ROI mean is divided by that ROI's mean in the same original channel:

```text
Ratio = ROI Mean / Denominator ROI Mean
```

A missing, nonfinite, or zero denominator produces `NaN`. Selecting a denominator does not alter Mean, Total, standard deviation, quantiles, or any other raw statistic.

## Scalar And RGB Channels

A scalar image produces one **Intensity** result row per ROI. An RGB image produces three rows:

| Channel | Meaning |
| --- | --- |
| Red | original red-channel values |
| Green | original green-channel values |
| Blue | original blue-channel values |

Integer source values retain their stored numeric scale. ROI Analyzer does not silently normalize 8-bit, 16-bit, floating-point, fluorescence, or color values to `[0,1]`. Report uncalibrated intensity as arbitrary intensity units and identify whether Mean, Total, or a ROI-to-ROI ratio is used.

## Statistics

For every ROI and channel, finite included pixels produce:

- pixel count and integrated total;
- arithmetic mean and sample standard deviation;
- median and unscaled median absolute deviation;
- minimum, maximum, and linearly interpolated 25th and 75th percentiles;
- pixel-coordinate centroid and bounding geometry;
- an optional same-channel ROI mean ratio.

Rectangle and square masks include pixel centers inside their bounds. Circle masks include pixel centers inside the circle inscribed in the equal-sided bounding box. Nonfinite pixels are excluded independently by channel.

## Batch Measurement

Use **Measure all images** after placing or copying ROIs across the image list. The App reads each full-resolution source once and applies the same original-pixel calculation used by **Measure ROIs**. The current image, selection, and ROI placements remain unchanged. The batch table reports one source per row with measurement status and the number of ROI/channel rows.

**Export batch CSV** writes a long table: one row per image, ROI, and channel. `ImageIndex` disambiguates repeated basenames; `Image`, ROI identity, geometry, and channel accompany the raw statistics. `GeometryAdjusted` is 1 when the measured bounding geometry was clamped or resized to fit that image, 0 when unchanged, and `NaN` when no measurement exists. Compare this flag and the exported dimensions before treating ROIs as equivalent across differently sized images.

A source without ROIs or a readable image retains an explicit status row with missing numeric values. A measured channel with no finite pixels is marked **No finite pixels**. A repeated batch replaces previous results, including failures, so an old success cannot silently stand in for a failed read. CSV export uses the saved measurements and does not recalculate. Geometry or ratio changes invalidate affected measurements; rerun after externally changing source pixels. Batch processing logs start, bounded progress between images, per-source failures, and completion in Diagnostics. A large individual image read or calculation is synchronous.

## Project, Parameters, And Results

The three output types have deliberately different purposes:

| Output | Contains | Use |
| --- | --- | --- |
| **Save project** | source references, shared geometry, ROI definitions and placements for every image, ratio choice, current results, and selected ROI group | Continue the same analysis project later |
| **Export parameter JSON** | shared geometry, current layout, and optional ratio-denominator choice | Review or reuse the analysis setup without paths, pixels, or old results |
| **Export batch CSV** | all sources, ROI/channel measurements, geometry adjustments, and explicit missing/failure rows | Batch comparison and completeness review |
| **Export current CSV** | current image label and complete ROI-by-channel measurement table | Statistical analysis, plotting, and reporting |

The MAT project stores source references, not copied image pixels. When opened, the recorded path, an archive-relative path, and a same-folder filename are tried. A missing image stops the restore without partially replacing the live task. The current format is explicit and versioned; retired or unrelated MAT payloads are rejected.

Parameter JSON is provenance, not a result cache. It intentionally omits source paths, pixel arrays, preview state, calculated tables, and export destinations. CSV values should be regenerated after geometry or ratio-denominator changes. Use **Measure all images** to reread externally changed source pixels; **Measure ROIs** uses the currently loaded full-resolution image.

## Use Without The GUI

```matlab
roi = struct("id", "roi-1", "name", "ROI 1", ...
    "shape", "Circle", ...
    "position", [10 15 20 20]);
measured = roi_analyzer.analysisRun.measureImage(imread("image.tif"), roi);
summary = measured.summary;
```

## Errors And Limitations

- Supported inputs are scalar-intensity and RGB images readable by the LabKit image reader. Indexed colormaps, multispectral stacks, videos, and volumetric images are outside this App.
- Shapes are rectangle, square, and circle. Polygon, freehand, rotated ellipse, automatic segmentation, lane, grid, and particle workflows are outside the initial scope.
- Measurements use only the source image's original Intensity or R/G/B pixel values; the App does not own inferred, calibrated, or transformed image values.
- Image registration and spatial calibration are not performed. Align images before applying one layout when exact locations must correspond.
- Automated hidden-GUI tests do not establish pointer feel, visual quality, or suitability for real fluorescence, blot, microscopy, or color-science data. Inspect representative images and scientific assumptions before publication.

For standalone measurement, supply resolved ROI structures with `id`, `name`, `shape`, and `position`. The in-memory placement record returned by `emptyRoi` is not a resolved measurement geometry; see the executable [`measureImage` example](../../../../reference/api/roi_analyzer/analysisRun/measureImage.html).

## Related Topics

- [Image Measurement family](../README.md)
- [Batch Image Crop](../batch-crop/README.md)
- [Image Enhance](../image-enhance/README.md)
- [Image Library](../../../../develop/libraries/image/README.md)
- [API Reference](../../../../reference/README.md)

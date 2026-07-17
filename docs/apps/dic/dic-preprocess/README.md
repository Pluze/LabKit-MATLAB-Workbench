# DIC Preprocess

DIC Preprocess registers a moving optical image to a reference image, applies
repeatable crop operations to the pair, and creates a binary analysis mask.
Use it when camera motion or framing differences must be removed before an
external DIC solver is run.

## Requirements And Launch

The app uses the LabKit UI framework and Image library. Image IO and
registration run in MATLAB; no external registration package is installed.

```matlab
labkit_DICPreprocess_app
```

## Inputs

Choose one reference image and one moving image. Supported extensions are the
formats returned by `labkit.image.supportedExtensions`, including common PNG,
JPEG, TIFF, and BMP files. The reference and moving images may initially have
different dimensions; alignment produces a moving image on the reference
domain.

Choosing a new reference or moving file clears operations derived from the old
pair. Source files are read-only and are not overwritten.

## Basic Workflow

1. Choose the reference and moving images.
2. Select **Current pair** or **False-color overlay** to assess the initial
   displacement.
3. Run manual point matching or **Auto align current pair**.
4. Inspect the false-color result and undo or reset if necessary.
5. Start the crop ROI, drag or resize the square, and apply it to both images.
6. Start ROI editing, place a boundary, and add or subtract it from the mask.
7. Save the prepared images and ROI mask.

Alignment and crop actions form an ordered edit history. **Undo align/crop**
removes the most recent applied operation. **Reset to originals** discards the
derived working pair and replays no edits.

## Preview Modes

| Mode | Display |
| --- | --- |
| Current pair | current reference above the current moving image |
| Current moving image | moving image in the main comparison view |
| False-color overlay | red/green registration comparison of the current pair |
| Original pair | source images before applied edits |
| ROI mask | current binary mask over the image domain |

Changing preview mode does not change project data. Point placement, point
dragging, crop editing, mask editing, and applying an operation preserve the
current axes zoom. Use the plot **Fit** action when a full-image view is wanted.

## Manual Point Matching

Press **Start point matching**. Click a feature in the reference image, then
click the same feature in the moving image. Repeat this reference/moving order
for at least two complete pairs. Numbered markers show correspondence and the
preview subtitle states which image expects the next point.

Drag an existing marker to refine it. **Undo point pair** removes the newest
complete pair. **Cancel point matching** discards the pending point set without
changing the current images. **Apply point alignment** estimates and applies a
rigid two-dimensional transform.

Manual alignment uses all pairs in a least-squares rotation-and-translation
fit. It does not estimate scale or shear and prevents a reflected solution.
Choose points that are visually unambiguous and spread across the specimen;
clustered points provide weak rotational leverage.

## Automatic Alignment

**Auto align current pair** runs the app-owned base-MATLAB registration path.
It returns the same aligned image and transform fields as manual alignment.
Automatic alignment is a starting estimate, not a guarantee of DIC-quality
correspondence. Always inspect the false-color overlay and prefer manual points
when the image has repeated texture, large occlusion, or weak contrast.

## Crop ROI

**Start/reset crop ROI** creates a square rectangle constrained to the current
reference image. Drag the rectangle to move it and use its resize handles to
change its size. **Apply ROI crop** uses exactly the same integer image-domain
rectangle on the reference and aligned moving image. **Cancel ROI** exits the
editor without adding a crop step.

Applied crops change the coordinate domain for later operations. Undo the crop
before reusing point coordinates defined on the larger image.

## Mask ROI

Start ROI editing and choose **Curve** or **Straight lines**. Place boundary
anchors as instructed by the canvas subtitle; anchors remain draggable while
editing. **Undo point** removes the most recent boundary anchor and **Clear
boundary** removes the pending boundary only.

**Preview ROI mask** shows the rasterized boundary. **Add to mask** unions the
boundary interior with the current mask; **Subtract from mask** removes it.
**Undo mask edit** restores the previous mask snapshot. **Clear mask** removes
all included pixels. The mask is stored as a logical image in the current
reference domain.

## Outputs

**Save current images** writes two images to the selected folder using stable
reference and moving result names. **Save ROI mask** writes a binary image to
the selected file. LabKit result manifests record source references,
parameters, output roles, and generated filenames; the manifest JSON is
provenance metadata, not an additional scientific result.

The saved project stores portable source references, preview choices, edit
steps, crop and mask annotations, and result references. Decoded source images
and intermediate working images are loaded or recomputed when the project is
opened; they are not duplicated inside the project file.

## Use Without The GUI

```matlab
reference = imread("reference.png");
moving = imread("moving.png");
referencePoints = [120 80; 360 95; 230 310];
movingPoints = [128 88; 369 101; 239 318];

[aligned, transform] = ...
    dic_preprocess.analysisRun.alignMovingToReference( ...
        reference, moving, referencePoints, movingPoints);
overlay = dic_preprocess.analysisRun.makeFalseColorOverlay( ...
    reference, aligned);
cropped = dic_preprocess.analysisRun.cropImage(aligned, [80 60 300 300]);
```

Use the linked function pages below for exact coordinate, rectangle, return
shape, interpolation, and error contracts.

## Errors And Troubleshooting

- Point alignment remains unavailable until at least two complete pairs exist.
- A strong colored double edge in the overlay indicates residual geometric
  mismatch, not a palette defect.
- Automatic alignment can fail on nearly uniform images; use separated manual
  points or improve the source capture.
- Crop and mask geometry is constrained to the active image domain; an old
  project source that changed size cannot safely reuse its prior annotations.

## Related Topics

- [DIC Postprocess](../dic-postprocess/README.md)
- [DIC family](../README.md)
- [Image Library](../../../libraries/image/README.md)
- [API Reference](../../../libraries/README.md)

## Framework Compatibility

The single `definition.m` owns product metadata, requirements, layout, and
optional runtime capabilities. `projectSpec.m` keeps the complete durable
version-1 schema, creation defaults, and validation together. `createSession.m`
rebuilds decoded source images and replays applied alignment/crop steps because
those images are transient caches rather than project data. The App requires
`labkit.ui >=7 <8` and `labkit.image >=2 <3`; busy-state, managed interactions,
optional source-slot lookup, and portable-reference serialization remain
framework-owned.

The project validator requires the DIC image-source collection and checks
alignment, crop, mask, history, and preview fields; Runtime validates canonical
buckets and each source record first.

App-owned state operations are grouped by capability: `editHistory` owns
align/crop undo and reset semantics, `maskEditing` owns mask canvas and mask
undo semantics, and `sourceFiles.hasImagePair` reports whether the transient
image cache is ready. There is no generic app-state service or alternate
lifecycle layer.

Its session factory returns only App-specific editing workflow and decoded
cache fields. Runtime supplies absent canonical buckets and owns workflow-log
initialization.

The semantic layout follows the [Runtime callback contract](../../../framework/runtime.md#layout-and-action-rules):
every referenced action must be registered and resolves during layout construction.

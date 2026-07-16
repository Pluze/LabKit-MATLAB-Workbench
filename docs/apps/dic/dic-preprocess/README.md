# DIC Preprocess

Use DIC Preprocess to create geometrically consistent reference/moving image
pairs, shared crops, and masks before running a DIC solver.

## Launch

```matlab
labkit_DICPreprocess_app
```

## Inputs

- one reference image;
- one moving image;
- optional additional moving images processed against the reference.

Supported image formats follow `labkit.image.supportedExtensions`.

## Basic Workflow

1. Choose the reference and moving images.
2. Select the preview mode needed for comparison.
3. Use manual point matching or automatic alignment.
4. Review the false-color overlay.
5. Define a shared square crop if required.
6. Draw or edit the mask boundary.
7. Save the current prepared images and mask.

## Manual Point Matching

Press **Start point matching**. Select a feature in the reference image and
then the corresponding feature in the moving image. Repeat for at least two
complete pairs. Point numbers identify correspondence across the stacked
views. Existing points can be dragged for refinement, and **Undo point pair**
removes the newest complete pair.

The canvas subtitle states which image expects the next point. Applying the
alignment ends edit mode and shows the false-color result. Canceling discards
the pending pairs. Point placement, dragging, or applying the result preserves
the current zoom; use the plot Fit command when a full-image view is wanted.

## Crop And Mask Interaction

The crop editor uses a draggable and resizable square rectangle constrained to
the image. Applying the crop uses the same rectangle for the reference and
aligned moving image. The mask editor records a boundary curve and can add to
or subtract from the current mask. Its interaction subtitle explains point
placement and deletion while edit mode is active.

## Registration Semantics

Manual alignment estimates a 2-D rigid transform: rotation plus translation,
with no scale or shear. It solves the least-squares correspondence using all
provided point pairs and prevents a reflection solution. Automatic alignment
uses app-owned image registration and returns the same aligned-image contract.

## Outputs

- aligned moving image;
- reference and moving crop images;
- binary ROI mask;
- recoverable project state containing edit steps and source references.

Original input files are never overwritten.

## Use Without The GUI

```matlab
reference = imread("reference.png");
moving = imread("moving.png");
fixedPoints = [120 80; 360 95; 230 310];
movingPoints = [128 88; 369 101; 239 318];
[aligned, transform] = dic_preprocess.analysisRun.alignMovingToReference( ...
    reference, moving, fixedPoints, movingPoints);
overlay = dic_preprocess.analysisRun.makeFalseColorOverlay(reference, aligned);
```

See the API reference for
`dic_preprocess.analysisRun.alignMovingToReference`,
`dic_preprocess.analysisRun.applyRigidTransform`, and
`dic_preprocess.analysisRun.cropImage`.

## Troubleshooting

- Widely separated, clearly identifiable points give a better rotation fit
  than clustered points.
- Two points are the minimum; three or more allow visual detection of a poor
  correspondence.
- A false-color edge around the specimen indicates remaining misregistration,
  not a display-only color error.

## See Also

- [DIC Postprocess](../dic-postprocess/README.md)
- [Image Library](../../../libraries/image/README.md)

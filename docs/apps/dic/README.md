# Digital Image Correlation Apps

```labkit-page
id: apps-dic
type: landing
audience: app-user
summary: Prepare optical image pairs for an external DIC solver, then turn Ncorr strain results into presentation images and summary measurements.
```

The DIC family prepares optical image pairs before correlation and turns Ncorr strain results into presentation images and summary measurements afterward. LabKit does not implement the correlation solver itself.

## Apps In This Family

| Stage | App | Use it to | Main result |
| --- | --- | --- | --- |
| Before correlation | [DIC Preprocess](dic-preprocess/README.md) | register a moving image to a reference, apply identical crop geometry, and build a mask | prepared image pair and binary ROI mask |
| After correlation | [DIC Postprocess](dic-postprocess/README.md) | map EXX/EYY strain fields onto the reference image and summarize the valid ROI | overlay PNGs and strain summary CSV |

## End-To-End Workflow

1. Use DIC Preprocess to align each moving image with the reference.
2. Apply a shared crop and save the prepared pair.
3. Create and save the ROI mask.
4. Run correlation in Ncorr using the prepared images and mask.
5. Load the Ncorr MAT result, matching reference image, and mask into DIC Postprocess.
6. Generate overlays, inspect valid coverage, and export the summary.

The two apps deliberately exchange ordinary image and MAT files rather than a private in-memory object. This keeps the external solver boundary explicit and makes each stage independently repeatable.

## Coordinate And Image Conventions

Interactive points and rectangles use MATLAB image coordinates: `x` is the column coordinate and `y` is the row coordinate. Registration and crop operations preserve array class and color channels where the operation permits. Masks are logical images aligned with the displayed reference domain.

DIC Preprocess owns geometric edits. DIC Postprocess may resize strain and mask arrays to the reference-image domain for rendering, but it does not alter the original Ncorr MAT file.

## Related Modules

- [Image Library](../../develop/libraries/image/README.md)
- [App Framework interactions](../../develop/framework/README.md)
- [All Apps](../README.md)

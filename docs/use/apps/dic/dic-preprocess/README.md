# DIC Preprocess

```labkit-page
id: app-dic-preprocess
type: landing
audience: app-user
summary: Register and crop an optical image pair and create a binary analysis mask before running an external DIC solver.
```

DIC Preprocess registers a moving optical image to a reference image, applies repeatable crop operations to the pair, and creates a binary analysis mask. Use it when camera motion or framing differences must be removed before an external DIC solver is run.

Mask editing, source replacement, and result-folder selection update the current project directly; no additional compatibility file or helper setup is required.

## Requirements And Launch

Image IO and registration use MATLAB and repository-owned code; no external registration package is installed.

```matlab
labkit_DICPreprocess_app
```

## Inputs

Choose one reference image and one moving image. Supported extensions are the formats returned by `labkit.image.supportedExtensions`, including common PNG, JPEG, TIFF, and BMP files. The reference and moving images may initially have different dimensions; alignment produces a moving image on the reference domain.

Choosing a new reference or moving file clears operations derived from the old pair. Source files are read-only and are not overwritten.

## Basic Workflow

1. Choose the reference and moving images.
2. Select **Current pair** or **False-color overlay** to assess the initial displacement.
3. Run manual point matching or **Auto align current pair**.
4. Inspect the false-color result and undo or reset if necessary.
5. Start the crop ROI, drag or resize the square, and apply it to both images.
6. Start ROI editing, place a boundary, and add or subtract it from the mask.
7. Save the prepared images and ROI mask.

Alignment and crop actions form an ordered edit history. **Undo align/crop** removes the most recent applied operation. **Reset to originals** discards the derived working pair and replays no edits.

## Preview Modes

| Mode | Display |
| --- | --- |
| Current pair | current reference above the current moving image |
| False-color overlay | red/green registration comparison of the current pair |
| Original pair | source images before applied edits |
| ROI mask | current binary mask over the image domain |

Changing preview mode does not change project data. Point placement, point dragging, crop editing, mask editing, and alignment preserve the current axes zoom. Applying a crop fits both axes to the new pixel domain so the removed image area does not remain as white plot margins. Use the plot **Fit** action when a full-image view is otherwise wanted.

## Manual Point Matching

Press **Start point matching**. The preview switches to the current reference and current moving images. Click a feature in the reference image, then click the same feature in the moving image. Repeat this reference/moving order for at least two complete pairs. Numbered markers show correspondence and the preview subtitle states which image expects the next point.

Markers are displayed as numbered points without connecting lines. Drag an existing marker to refine it. **Undo point pair** removes the newest complete pair. **Cancel point matching** discards the pending point set without changing the current images. **Apply point alignment** estimates and applies a rigid two-dimensional transform.

Manual alignment uses all pairs in a least-squares rotation-and-translation fit. It does not estimate scale or shear and prevents a reflected solution. Choose points that are visually unambiguous and spread across the specimen; clustered points provide weak rotational leverage.

## Crop ROI

**Start/reset crop ROI** creates a square rectangle constrained to the current reference image and draws the same rectangle on the moving preview for direct comparison. Drag the reference rectangle to move it and use its resize handles to change its size. **Apply ROI crop** uses exactly the same integer image-domain rectangle on the reference and aligned moving image, then fits both axes to the cropped domain. **Cancel ROI** exits the editor without adding a crop step.

Applied crops change the coordinate domain for later operations. Undo the crop before reusing point coordinates defined on the larger image.

## Mask ROI

Start ROI editing and choose **Curve** or **Straight lines**. Place boundary anchors as instructed by the canvas subtitle; anchors remain draggable while editing. **Undo point** removes the most recent boundary anchor and **Clear boundary** removes the pending boundary only.

**Preview ROI mask** shows the rasterized boundary. **Add to mask** unions the boundary interior with the current mask; **Subtract from mask** removes it. **Undo mask edit** restores the previous mask snapshot. **Clear mask** removes all included pixels. The mask is stored as a logical image in the current reference domain.

## Automatic Alignment

**Auto align current pair** estimates a rigid rotation and translation without changing scale or shear. It can search large rotations and displacements, but the result is only a starting estimate, not a guarantee of DIC-quality correspondence. Always inspect the false-color overlay. Prefer manual points when the images have repeated texture, very little overlap, scale change, deformation, large occlusion, or weak contrast.

The session log records automatic alignment as one workflow result. Image-dependent method and quality details are not copied into durable diagnostic payloads.

## Outputs

**Save current images** writes two images to the selected folder using stable reference and moving result names. **Save ROI mask** writes a binary image to the selected file. The App has no task archive; source selections, preview choices, edits, crop state, and mask state last only for the open session.

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

Use the linked function pages below for exact coordinate, rectangle, return shape, interpolation, and error contracts.

## Function Reference

The generated pages for [`alignMovingToReference`](../../../../reference/api/dic_preprocess/analysisRun/alignMovingToReference.html), [`autoAlignMovingToReference`](../../../../reference/api/dic_preprocess/analysisRun/autoAlignMovingToReference.html), [`applyRigidTransform`](../../../../reference/api/dic_preprocess/analysisRun/applyRigidTransform.html), and the other cataloged DIC functions document coordinate conventions, assumptions, output shape, limitations, failure behavior, and related APIs.

## Errors And Troubleshooting

- Point alignment remains unavailable until at least two complete pairs exist.
- A strong colored double edge in the overlay indicates residual geometric mismatch, not a palette defect.
- Automatic alignment can fail on nearly uniform images; use separated manual points or improve the source capture.
- Crop and mask geometry is constrained to the active image domain; an old project source that changed size cannot safely reuse its prior annotations.

## Related Topics

- [DIC Postprocess](../dic-postprocess/README.md)
- [DIC family](../README.md)
- [Image Library](../../../../develop/libraries/image/README.md)
- [API Reference](../../../../reference/README.md)

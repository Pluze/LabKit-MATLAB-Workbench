# DIC preprocess restores interactive editing and rigid registration

```labkit-change
id: CHG-20260803-dic-preprocess-interaction-registration-repair
date: 2026-08-03
type: fix
compatibility: compatible
component: labkit_DICPreprocess_app | 1.7.1 -> 1.7.2
```

## Why

DIC Preprocess could leave manual matching on an overlay instead of the moving image, showed a crop rectangle only on the reference preview, retained stale plot limits after applying a crop, and failed to start mask editing because a variable anchor list was supplied to the fixed point-slot interaction. Its toolbox-free automatic path also estimated translation only, so ordinary camera rotation could make the starting alignment inaccurate.

### Accepted choice

Keep the repair App-local. Use the existing variable anchor-path interaction for mask boundaries, make matching and crop preview transitions explicit, and use the plot revision contract when the crop changes the image domain. Restore automatic rigid behavior with a bounded coarse-to-fine rotation search and amplitude-weighted, zero-padded phase correlation implemented in base MATLAB. Score candidate transforms at a finer structural resolution so DIC texture aliasing cannot select a plausible but wrong angle. Use anti-aliased previews, subpixel peak refinement, robust local scoring, and explicit overlap and ambiguity diagnostics to tolerate outliers and partial occlusion. Keep paired matching as a point interaction with no implied path between anchors, and remove the duplicate moving-image preview choice while migrating its saved value to the identical current-pair view. Extend the global search over the complete rotation circle and permit translations up to 75% of a preview axis, then retain fine angular resolution through two refinement stages.

## What changed

- Manual point matching now selects the current moving-image preview.
- The active crop rectangle is rendered on both images, and applying the crop fits both axes to the new pixel domain.
- Mask boundaries use a variable closed anchor path and can enter edit mode from an empty boundary.
- Paired match anchors render only numbered points and never a connecting line.
- The redundant Current moving image selector is removed; version-1 projects migrate that value to Current pair without changing displayed image data.
- Automatic alignment estimates translation on a response-limited preview, suppresses sampling aliasing and isolated intensity outliers, refines the correlation peak to subpixel precision, scores rotation candidates with robust overlap-aware oriented structure, applies the accepted transform at source resolution, and records numeric score and ambiguity details.

## Impact

Users can activate mask editing, compare the same crop on both images, see the cropped image without stale white margins, and inspect uncluttered matched points. Automatic alignment is more reliable for camera motion that includes rotation and high-frequency DIC texture. Existing project fields, saved images, masks, coordinate conventions, and export schemas are unchanged.

## Compatibility and limits

The change is compatible with version-1 DIC Preprocess projects. The project schema migrates the retired Current moving image value to Current pair; no image, annotation, edit, result, or coordinate data changes. Manual alignment remains a rigid rotation-and-translation fit, and automatic alignment continues to return the same three-by-three row-vector transform shape.

### Remaining limits

Automatic alignment does not estimate scale, shear, perspective, or deformation. Repeated texture, weak contrast, large occlusion, or very limited overlap can still require manual matched points. Native pointer feel and suitability for real DIC imagery remain manual review boundaries.

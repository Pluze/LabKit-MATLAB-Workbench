# DIC preprocess restores interactive editing and rigid registration

```labkit-change
id: LK-20260803-dic-preprocess-interaction-registration-repair
date: 2026-08-03
sequence: 167
type: fix
compatibility: compatible
component: `labkit_DICPreprocess_app` | `1.7.1 -> 1.7.2`
scope: DIC preprocess interaction repair
scope: Rigid image registration
```

## Context

DIC Preprocess could leave manual matching on an overlay instead of the moving
image, showed a crop rectangle only on the reference preview, retained stale
plot limits after applying a crop, and failed to start mask editing because a
variable anchor list was supplied to the fixed point-slot interaction. Its
toolbox-free automatic path also estimated translation only, so ordinary
camera rotation could make the starting alignment inaccurate.

## Decision and rationale

Keep the repair App-local. Use the existing variable anchor-path interaction
for mask boundaries, make matching and crop preview transitions explicit, and
use the plot revision contract when the crop changes the image domain. Restore
automatic rigid behavior with a bounded coarse-to-fine rotation search and
amplitude-weighted, zero-padded phase correlation implemented in base MATLAB.
Score candidate transforms at a finer structural resolution so DIC texture
aliasing cannot select a plausible but wrong angle. Keep paired matching as a
point interaction with no implied path between anchors.

## Changes

- Manual point matching now selects the current moving-image preview.
- The active crop rectangle is rendered on both images, and applying the crop
  fits both axes to the new pixel domain.
- Mask boundaries use a variable closed anchor path and can enter edit mode
  from an empty boundary.
- Paired match anchors render only numbered points and never a connecting line.
- Automatic alignment estimates translation on a response-limited preview,
  scores rotation candidates with finer oriented structure, applies the
  accepted transform at source resolution, and records its numeric decision
  details in the diagnostic event.

## User and data impact

Users can activate mask editing, compare the same crop on both images, see the
cropped image without stale white margins, and inspect uncluttered matched
points. Automatic alignment is more reliable for camera motion that includes
rotation and high-frequency DIC texture. Existing project fields,
saved images, masks, coordinate conventions, and export schemas are unchanged.

## Compatibility and migration

The change is compatible with version-1 DIC Preprocess projects. No project
migration is required. Manual alignment remains a rigid rotation-and-
translation fit, and automatic alignment continues to return the same
three-by-three row-vector transform shape.

## Validation

Focused scientific evidence covers existing integer translation, a controlled
rotation-plus-translation case, and finite transform-quality details without
optional Toolboxes. The hidden-GUI workflow covers moving-preview selection,
point-only paired anchors, numeric automatic-registration diagnostics, crop
overlays on both axes, fitted crop limits, successful mask activation, export,
and project restore. The supplied state/source pair confirmed the previous
automatic estimate disagreed materially with two stable manual fits and that
finer structural scoring recovered the same rotation neighborhood.

## Evidence

- `labkittest.run(Owner="apps/dic/dic_preprocess/analysisrun", Contract="scientific")`
- `labkittest.run(Owner="apps/dic/dic_preprocess/workbench", Contract="presentation")`
- The redacted diagnostic bundle reported
  `labkit:app:runtime:InvalidPointSlotsValue` from mask activation.

## Known limitations and follow-up

Automatic alignment searches rotations from -30 to +30 degrees and does not
estimate scale, shear, or deformation. Repeated texture, weak contrast, large
occlusion, or limited overlap can still require manual matched points. Native
pointer feel and suitability for real DIC imagery remain manual review
boundaries.

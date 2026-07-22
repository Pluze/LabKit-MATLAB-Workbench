# Figure Studio preserves overlays above source images

```labkit-change
id: LK-20260722-figure-studio-image-overlay-stacking
date: 2026-07-22
sequence: 156
type: fix
compatibility: compatible
component: `labkit_FigureStudio_app` | `0.6.4 -> 0.6.5`
scope: LabKit Core
```

## Context

Figure Studio copied every visible child from native MATLAB axes, but reversed
the source child vector before copying it into the interactive preview. Because
MATLAB stores axes children from front to back and `copyobj` preserves vector
order, an opaque image became the frontmost child and hid line, marker, and
text overlays that had been drawn above it.

## Decision and rationale

Pass the native axes child order through unchanged. The source axes remains the
authority for stacking, and Figure Studio must not infer a new order from
graphics classes or special-case images.

## Changes

- Preserved native front-to-back child order when copying an axes into the
  interactive preview.
- Added a synthetic image, line, and text stack regression at the renderer
  boundary.
- Added a hidden-GUI regression covering both FIG-file import and axes
  handoff.

## User and data impact

Image-backed plots now show their visible overlays in Figure Studio and in
preview-derived exports. Source files, scientific values, coordinates, object
styles, and project data are unchanged.

## Compatibility and migration

No project migration is required. Existing projects receive the corrected
stacking when their native source is rebuilt.

## Validation

- Exact source-axes stacking regression.
- Hidden-GUI FIG import and axes-handoff stacking regression.
- Visual inspection of an authorized local diagnostic FIG through both paths;
  the real file remains untracked and is not a test fixture.

## Evidence

Both real-source paths retained all 12 visible graphics children with the
opaque image last and the 11 overlay children in front. Temporary preview
rasters confirmed the overlays were visible.

## Known limitations and follow-up

Custom graphics classes still depend on MATLAB supporting their native parent
transition. The portable data package remains narrower than the native preview
and export path.

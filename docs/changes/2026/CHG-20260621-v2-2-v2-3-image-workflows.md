# v2.2 to v2.3.1: self-contained launch and image workflow refinement

```labkit-change
id: CHG-20260621-v2-2-v2-3-image-workflows
date: 2026-06-21
type: feat
compatibility: compatible
component: repository
```

## Why

The launcher and updater existed, but installation still assumed repository context. At the same time, ordinary image work exposed small but costly interaction problems: selecting several files, preserving zoom while placing a marker, padding a crop without shifting its source coordinates, or returning to duplicate-crop mode after editing scale.

### Accepted choice

Make the launcher usable as a self-contained entry artifact and refine the high-frequency image workflows in place. These releases favored fewer steps and stable spatial state over adding more general-purpose dialogs or toolbars.

## What changed

- Made the launcher self-contained and added an update button backed by the release updater.
- Appended file-panel selections and added multi-file choose-and-load behavior.
- Improved Image Match speed and separated its reference input from moving images.
- Preserved Batch Crop source coordinates when padding, reduced padding seams, and refined the padding workflow.
- Added physical scale mode to Batch Crop and restored scale and duplicate-task interactions after edits.
- Preserved image-tool zoom while placing or editing overlays.
- Hardened image-tool ownership and changed the README to present the launcher as the primary user entry.

## Impact

Users could begin from a compact launcher, select several files in one action, and edit image overlays without losing their current view. Batch Crop gained physical scaling while retaining the relationship between the visible crop and the source image.

Padding and scale metadata affected exported crop interpretation, so regression work explicitly protected source coordinates and resumed interaction modes.

## Compatibility and limits

The changes were compatible additions and fixes to the v2 workflows. Release tags identify the incremental baselines: `v2.2.0` at `c904baca`, `v2.3.0` at `f2ed23c2`, and `v2.3.1` at `83d03e7a`.

### Remaining limits

Some previews still repeated expensive processing, EIS log-axis navigation was fragile, and the release process did not yet prove that downloadable artifacts matched their tags. v2.3.2 and v2.3.3 addressed those issues.

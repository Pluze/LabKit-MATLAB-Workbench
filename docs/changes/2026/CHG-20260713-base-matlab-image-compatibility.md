# Base-MATLAB image compatibility

```labkit-change
id: CHG-20260713-base-matlab-image-compatibility
date: 2026-07-13
type: feat
compatibility: compatible
component: labkit.image | 1.1.0 -> 1.2.0
component: labkit_DICPostprocess_app | 1.3.4 -> 1.3.5
component: labkit_DICPreprocess_app | 1.3.5 -> 1.3.6
component: labkit_FocusStack_app | 1.4.7 -> 1.4.8
component: labkit_ImageEnhance_app | 1.5.6 -> 1.5.7
component: labkit_ImageMatch_app | 1.5.6 -> 1.5.7
```

## Why

Several image workflows appeared toolbox-optional but still called Image Processing Toolbox functions for conversion, grayscale luminance, resizing, smoothing, alignment, or warping. Development machines with the toolbox hid those calls, so a nominally supported Base MATLAB installation could fail only after the user entered a particular workflow.

### Accepted choice

Own the essential image operations used by LabKit and make their Base MATLAB paths the tested behavior. Optional toolbox acceleration could remain only when the call was explicit, a repository-owned fallback existed, and parity tests protected the app-consumed result.

## What changed

- Added `labkit.image.toDouble` and `labkit.image.toLuma`, and replaced hard Image Processing Toolbox calls in shared image facade code and image-app workflow paths with base-MATLAB implementations.
- DIC preprocessing now uses a toolbox-free phase-correlation translation path for automatic alignment and a base-MATLAB rigid warp for control-point alignment.
- DIC postprocessing, Focus Stack, Image Enhance, and Image Match now use app-local or facade-owned image normalization, resizing, smoothing, and luma helpers instead of requiring toolbox functions.
- Added a project hygiene guardrail that rejects unguarded toolbox image helper calls under `apps/` and `+labkit/`, while still allowing explicit optional toolbox paths with fallbacks.

## Impact

DIC alignment and overlays, Focus Stack, Image Enhance, and Image Match could run without Image Processing Toolbox. Users with the toolbox retained compatible workflows, while CI now exercised the installation that previously failed late and silently.

## Compatibility and limits

- Existing app workflows and exported schemas are preserved. Optional toolbox acceleration paths remain allowed only when a base-MATLAB fallback is present.

### Remaining limits

Base MATLAB compatibility does not mean every optional accelerated algorithm is numerically identical by construction. Where a toolbox branch affects scientific values, representative parity and idempotency tests remain required until the repository-owned implementation fully replaces it.

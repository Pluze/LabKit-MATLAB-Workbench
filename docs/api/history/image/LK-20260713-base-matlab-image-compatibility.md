# Base-MATLAB image compatibility

```labkit-change
schema: 1
id: LK-20260713-base-matlab-image-compatibility
date: 2026-07-13
type: feat
compatibility: compatible
component: `labkit.image` | `1.1.0 -> 1.2.0`
component: `labkit_DICPostprocess_app` | `1.3.4 -> 1.3.5`
component: `labkit_DICPreprocess_app` | `1.3.5 -> 1.3.6`
component: `labkit_FocusStack_app` | `1.4.7 -> 1.4.8`
component: `labkit_ImageEnhance_app` | `1.5.6 -> 1.5.7`
component: `labkit_ImageMatch_app` | `1.5.6 -> 1.5.7`
```

## Context

- CI now protects the base-MATLAB user path instead of passing only on
  machines that happen to have Image Processing Toolbox installed.

## Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

## Changes

- `labkit.image` `1.1.0 -> 1.2.0`
- `labkit_DICPreprocess_app` `1.3.5 -> 1.3.6`
- `labkit_DICPostprocess_app` `1.3.4 -> 1.3.5`
- `labkit_FocusStack_app` `1.4.7 -> 1.4.8`
- `labkit_ImageEnhance_app` `1.5.6 -> 1.5.7`
- `labkit_ImageMatch_app` `1.5.6 -> 1.5.7`

- Added `labkit.image.toDouble` and `labkit.image.toLuma`, and replaced hard
  Image Processing Toolbox calls in shared image facade code and image-app
  workflow paths with base-MATLAB implementations.
- DIC preprocessing now uses a toolbox-free phase-correlation translation
  path for automatic alignment and a base-MATLAB rigid warp for control-point
  alignment.
- DIC postprocessing, Focus Stack, Image Enhance, and Image Match now use
  app-local or facade-owned image normalization, resizing, smoothing, and luma
  helpers instead of requiring toolbox functions.
- Added a project hygiene guardrail that rejects unguarded toolbox image
  helper calls under `apps/` and `+labkit/`, while still allowing explicit
  optional toolbox paths with fallbacks.

## User and data impact

- CI now protects the base-MATLAB user path instead of passing only on
  machines that happen to have Image Processing Toolbox installed.

## Compatibility and migration

- Existing app workflows and exported schemas are preserved. Optional toolbox
  acceleration paths remain allowed only when a base-MATLAB fallback is present.

## Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

## Evidence

- Mainline commit `bcd5f51f`.

## Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

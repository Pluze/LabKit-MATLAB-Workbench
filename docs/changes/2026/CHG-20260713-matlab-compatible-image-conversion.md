# MATLAB-compatible image conversion API

```labkit-change
id: CHG-20260713-matlab-compatible-image-conversion
date: 2026-07-13
type: refactor
compatibility: breaking
component: labkit.image | 1.2.0 -> 2.0.0
component: labkit_DICPostprocess_app | 1.3.5 -> 1.3.6
component: labkit_BatchImageCrop_app | 1.6.7 -> 1.6.8
component: labkit_CurvatureMeasurement_app | 1.3.4 -> 1.3.5
component: labkit_FocusStack_app | 1.4.8 -> 1.4.9
component: labkit_ImageEnhance_app | 1.5.7 -> 1.5.8
component: labkit_ImageMatch_app | 1.5.7 -> 1.5.8
```

## Why

The `toDouble`, `toLuma`, and `toRgbDouble` names combined class conversion, channel shaping, and clipping in ways that differed from familiar MATLAB APIs.

### Accepted choice

Use MATLAB-compatible names and call contracts for replacement functions, and keep orthogonal RGB shaping explicit so users do not need to learn a composite LabKit normalization rule.

## What changed

- Added base-MATLAB `labkit.image.im2double` and `labkit.image.rgb2gray`.
- Kept channel shaping in `ensureRgb` and made clipping explicit at call sites.
- Removed the ambiguous conversion helpers and centralized Rec.601 ownership.

## Impact

Base-MATLAB users receive familiar image conversion behavior without hidden toolbox requirements. Existing app image results retain their intended ranges and channel shapes through explicit pipelines.

## Compatibility and limits

This is a breaking facade rename. External callers replace removed helper names with `im2double`, `rgb2gray`, and `ensureRgb` as separately needed.

### Remaining limits

The compatibility layer intentionally covers the LabKit-used MATLAB contracts, not every Image Processing Toolbox function.

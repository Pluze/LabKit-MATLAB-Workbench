# Protected image enhancement workflows

```labkit-change
id: CHG-20260629-protected-image-enhancement-workflows
date: 2026-06-29
type: feat
compatibility: compatible
component: labkit_ImageEnhance_app | 1.2.2 -> 1.3.0
component: labkit_ImageMatch_app | 1.2.1 -> 1.3.0
```

## Why

The existing appearance adjustments could change a subject together with its background. Image Enhance and Image Match needed modes that protected subject detail while correcting bright backgrounds and tone.

### Accepted choice

Add subject-preserving enhancement and protected tone matching as explicit methods with their own parameters, descriptions, and tests. Keep these methods inside the image apps because they encode workflow-specific decisions rather than generic image primitives.

## What changed

- Image Enhance `1.2.2 -> 1.3.0`
- Image Match `1.2.1 -> 1.3.0`

- Added Subject-preserving enhance to Image Enhance.
- Added Protected tone to Image Match.
- Added calculation and GUI coverage for both methods.

## Impact

Users could brighten or normalize a background with less change to the main subject. The new methods were optional; existing histories and other matching methods retained their previous behavior.

## Compatibility and limits

Existing enhancement steps and Image Match inputs remained valid. The new protected methods were additional choices and did not rewrite saved source images.

### Remaining limits

The protected methods reduce unwanted subject changes but cannot infer semantic foreground perfectly. Their result still requires visual review.

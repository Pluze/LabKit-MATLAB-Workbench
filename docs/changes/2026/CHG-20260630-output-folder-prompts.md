# Output folder prompts

```labkit-change
id: CHG-20260630-output-folder-prompts
date: 2026-06-30
type: feat
compatibility: compatible
component: labkit.ui | 3.2.5 -> 3.2.6
component: labkit_DICPostprocess_app | 1.2.0 -> 1.2.1
component: labkit_DICPreprocess_app | 1.2.0 -> 1.2.1
component: labkit_BatchImageCrop_app | 1.3.3 -> 1.3.4
component: labkit_FocusStack_app | 1.2.1 -> 1.2.2
component: labkit_ImageEnhance_app | 1.3.1 -> 1.3.2
component: labkit_ImageMatch_app | 1.3.1 -> 1.3.2
component: labkit_NerveResponseAnalysis_app | 1.2.1 -> 1.2.3
component: labkit_ResponseReviewStats_app | 1.2.1 -> 1.2.2
```

## Why

Exporting from different apps opened `uigetdir` directly, chose starting folders differently, and could not substitute a noninteractive chooser in a test. The repeated dialog code also made cancellation handling inconsistent.

### Accepted choice

Provide one output-folder prompt that selects a safe default, returns an explicit cancellation flag, remembers a successful folder, and accepts an injected chooser for tests. Apps would still decide when an output folder was needed and what they wrote there.

## What changed

- DIC apps, Batch Crop, Focus Stack, Image Enhance/Match, Nerve Response, and Response Review patch bumped.

- Added `promptOutputFolder`.
- Migrated output-folder prompts with chooser injection and safe defaults.

## Impact

Output dialogs began in a useful folder and cancellation returned cleanly to the app. The selected folder was remembered as a preference; no output was created until the owning app performed its export.

## Compatibility and limits

Existing output locations and exported file formats remained valid. Apps moved from direct folder dialogs to the shared prompt without changing what they wrote after selection.

### Remaining limits

Runtime V2 later moved dialog access into injected services, preserving the same separation between app decisions and platform dialog mechanics.

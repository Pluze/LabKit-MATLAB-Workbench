# Selector-aware slider labels

```labkit-change
id: CHG-20260827-dynamic-slider-labels
date: 2026-08-27
type: fix
compatibility: compatible
component: labkit.app | 3.2.1 -> 3.2.2
component: labkit_ImageEnhance_app | 1.9.1 -> 1.9.2
```

## Why

Image Enhance reused two sliders for tools whose parameters have different meanings and units, but their labels stayed at Brightness and Contrast after the Interaction choice changed. The App already owned the correct label for every tool, while the App SDK's declared slider text operation incorrectly targeted the numeric component instead of its cached visible label.

### Accepted choice

Keep tool names and units in Image Enhance and make the existing domain-neutral slider text operation update the native label. Creating separate controls for every tool was rejected because it would duplicate one editing workflow and require additional visibility state without adding user capability.

## What changed

- Image Enhance now presents the correct primary and secondary parameter labels for every Interaction choice.
- `Snapshot.text` now updates a slider's visible label without changing its numeric value.

## Impact

Users can identify whether a slider controls brightness, clarity, sharpening, hue, strength, radius, saturation, temperature, or a target percentage before applying an enhancement step. App authors can reuse one slider for selector-dependent parameters while keeping the label synchronized through the existing snapshot contract.

## Compatibility and limits

Enhancement formulas, defaults, valid ranges, processing history, exported images, manifests, and saved in-memory state are unchanged. The repository-wide App audit found no other public App that reuses one slider across selector-dependent parameter meanings; fixed-purpose sliders and presets therefore remain unchanged.

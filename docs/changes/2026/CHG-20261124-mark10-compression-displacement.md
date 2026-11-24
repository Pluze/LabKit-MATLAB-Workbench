# Reconstruct Mark-10 travel during loading and unloading

```labkit-change
id: CHG-20261124-mark10-compression-displacement
date: 2026-11-24
type: feat
compatibility: compatible
component: labkit_Mark10Monitor_app | 2.1.0 -> 2.2.0
```

## Why

The stand reports coarse travel steps during constant-speed compression. Different force gauge ranges have different increments, so a fixed absolute excursion threshold is unreliable across recordings.

## What changed

Live and replay plots show synchronized force against both measured and modeled travel. The App detects direction and reversals from measured travel and estimates a signed speed for each supported stroke or takes a speed magnitude from the user. Both plot legends report the latest visible speed in each direction. Holds and unresolved strokes use measured travel in analysis. Contact time is applied explicitly to set the surface reference. Stopped and loaded data can suggest a candidate for review. Stress–strain analysis uses the selected coordinate model. The glitch detector scales its threshold to observed increments and local noise.

## Impact

Automatic reconstruction applies to compression, tension, and cyclic tests. Choose Measured gap to use gauge positions throughout. Set an explicit surface time when comparing surface-relative compression. See [Travel Reconstruction](../../use/apps/force-gauges/mark10-monitor/README.md#travel-reconstruction).

## Compatibility and limits

Raw CSV, LOG, and MAT formats retain the original sample coordinates. Stress–strain CSV keeps its existing columns. Stroke boundaries and speeds are inferred from quantized observations, and a user-applied contact time does not measure specimen height or correct machine compliance.

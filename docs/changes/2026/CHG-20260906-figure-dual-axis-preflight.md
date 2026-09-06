# Check Figure Studio series against their assigned Y axis

```labkit-change
id: CHG-20260906-figure-dual-axis-preflight
date: 2026-09-06
type: fix
compatibility: compatible
component: labkit_FigureStudio_app | 0.10.0 -> 0.10.1
```

## Why

Publication preflight compared every series with the left Y-axis limits and log scale, even when the document assigned a series to the right axis. This could falsely block a valid mixed-scale figure or miss invalid right-axis log data.

## What changed

Preflight partitions Y data by each object's recorded axis assignment and checks both Y axes independently. Out-of-range warnings use the assigned axis limits.

## Impact

Dual-Y figures receive accurate blocking and range diagnostics before export. Single-axis checks, source values, object geometry, and rendered styles remain unchanged.

## Compatibility and limits

An incorrect or ambiguous imported axis assignment still requires review. Preflight checks the recorded document; it cannot infer the intended scientific mapping.

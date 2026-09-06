# Use normalized force polarity in cyclic analysis

```labkit-change
id: CHG-20260906-cyclic-force-labels
date: 2026-09-06
type: fix
compatibility: compatible
component: labkit_Mark10Monitor_app | 1.1.1 -> 1.1.2
```

## Why

Mark-10 acquisition and exported recordings use tension-positive force. Cyclic analysis applied the opposite convention when naming branches, causing its phase labels to disagree with the measurements being analyzed.

## What changed

Cyclic branch labels now interpret nonnegative median corrected force as tension and negative median corrected force as compression. The manual describes the same convention and separates recording, branch, and manual fit-point requirements. It lists the three files actually written by recording export.

## Impact

Analysis tables and modulus CSV exports identify cyclic phases consistently with their force values. Explicit Tension and Compression experiment labels, fitted slopes, modulus, stiffness, and recording values remain unchanged.

## Compatibility and limits

Previously exported cyclic phase labels are not rewritten. Recalculate a cyclic analysis to obtain corrected labels. Branch labeling still uses the applied force-zero level and does not infer specimen mechanics from the waveform.

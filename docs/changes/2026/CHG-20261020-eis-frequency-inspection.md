# EIS frequency inspection workspace

```labkit-change
id: CHG-20261020-eis-frequency-inspection
date: 2026-10-20
type: feat
compatibility: compatible
component: labkit_EIS_app | 1.10.0 -> 1.11.0
```

## Why

The Nyquist display recommendation could miss a clearly resolved arc when the measured high-frequency boundary was already elevated: requiring a twofold rise rejected an otherwise substantial peak-to-valley descent followed by a dominant tail. Scientific notation also made frequency controls harder to read, and the overview used a large side control strip, inconsistent panel borders, unused equal-aspect space, and an unfiltered Bode comparison.

## What changed

- Require the high-frequency boundary and following valley each to be at least 30% below the candidate peak, retaining the existing sample, descent-span, and dominant-tail requirements.
- Show frequency captions and the Nyquist range title in decimal Hz, kHz, MHz, or larger units with four significant digits.
- Use a compact shared frequency toolbar above two balanced plot rows, remove the Nyquist panel border, and place its legend to the right with wrapped long labels.
- Expand Nyquist coordinate ranges to fill the available plot area with equal X/Y data units.
- Apply the selected frequency window to Nyquist and both Bode plots, including their group error bars; retain complete data in custom plots and exports.

## Impact

[EIS](../../use/apps/electrochemistry/eis/README.md) can recommend a useful display window for arcs with an elevated high-frequency boundary. Full range remains available and spectra without supporting shape evidence retain their complete range.

## Compatibility and limits

Overview display selection and presentation change. Source measurements, custom plots, group statistics, numerical exports, and scientific formulas are unchanged. The recommendation remains a display heuristic rather than circuit fitting or electrochemical identification.

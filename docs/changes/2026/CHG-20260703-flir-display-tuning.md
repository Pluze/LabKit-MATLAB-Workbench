# FLIR display tuning

```labkit-change
id: CHG-20260703-flir-display-tuning
date: 2026-07-03
type: feat
compatibility: compatible
component: labkit_CSC_app | 1.3.6 -> 1.3.7
component: labkit_FLIRThermal_app | 1.2.4 -> 1.2.7
```

## Why

The initial FLIR renderer used a fixed color transfer. Images with a narrow or skewed temperature distribution could therefore hide useful contrast even when the numeric range was correct. CSC voltage/current CSV output also needed clearer cycle organization for direct downstream use.

### Accepted choice

Separate the displayed color mapping from the temperature values. Apply gamma only while rendering the normalized image and expose it as a user control; keep the temperature matrix, point readings, ROI means, and exports numerically unchanged. Refine CSC CSV structure at its result writer rather than in the UI.

## What changed

- Refined CSC CV export.
- Added FLIR gamma color mapping and made gamma adjustable.

## Impact

FLIR users could reveal contrast in hotter or cooler parts of an image without changing the underlying temperatures. The same gamma was used in displayed and exported color renderings. CSC users received a more directly usable voltage/current table.

## Compatibility and limits

Existing FLIR inputs remained valid, and gamma affected rendered color only. Temperature matrices and measurement values did not require conversion.

### Remaining limits

Gamma changes visual contrast only. Quantitative interpretation must use the temperature values and scale, not colors sampled from the rendered image.

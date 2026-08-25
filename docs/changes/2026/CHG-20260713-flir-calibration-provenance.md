# Traceable FLIR temperature calibration

```labkit-change
id: CHG-20260713-flir-calibration-provenance
date: 2026-07-13
type: feat
compatibility: compatible
component: labkit.thermal | 1.0.0 -> 1.1.0
component: labkit_FLIRThermal_app | 1.2.8 -> 1.3.0
```

## Why

A successful Celsius conversion did not reveal whether emissivity and environmental values came from the file or from model defaults, which could make an absolute temperature appear more certain than its metadata justified.

### Accepted choice

Preserve conversion provenance with the thermal record and show fallback use in the app, rather than silently treating every parameter as measured.

## What changed

- Added optional conversion diagnostics with correction mode, defaulted fields, parameter sources, and fallback status.
- Stored diagnostics in thermal record metadata and surfaced warnings in FLIR file status and details.
- Documented embedded calibration requirements and environmental fallbacks.

## Impact

Users can distinguish radiometric values based entirely on embedded metadata from values affected by fallback assumptions before interpreting temperatures.

## Compatibility and limits

Existing one-output conversion calls remain valid. The diagnostics output and record metadata are additive; app workflows need no migration.

### Remaining limits

Diagnostics describe source and fallback use; they do not estimate a physical uncertainty interval for a particular camera, surface, or environment.

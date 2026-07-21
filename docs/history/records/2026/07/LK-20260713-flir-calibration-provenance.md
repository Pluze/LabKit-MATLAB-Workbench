# Traceable FLIR temperature calibration

```labkit-change
id: LK-20260713-flir-calibration-provenance
date: 2026-07-13
sequence: 49
type: feat
compatibility: compatible
component: `labkit.thermal` | `1.0.0 -> 1.1.0`
component: `labkit_FLIRThermal_app` | `1.2.8 -> 1.3.0`
scope: Traceable FLIR temperature calibration
```

## Context

A successful Celsius conversion did not reveal whether emissivity and
environmental values came from the file or from model defaults, which could
make an absolute temperature appear more certain than its metadata justified.

## Decision and rationale

Preserve conversion provenance with the thermal record and show fallback use
in the app, rather than silently treating every parameter as measured.

## Changes

- Added optional conversion diagnostics with correction mode, defaulted fields,
  parameter sources, and fallback status.
- Stored diagnostics in thermal record metadata and surfaced warnings in FLIR
  file status and details.
- Documented embedded calibration requirements and environmental fallbacks.

## User and data impact

Users can distinguish radiometric values based entirely on embedded metadata
from values affected by fallback assumptions before interpreting temperatures.

## Compatibility and migration

Existing one-output conversion calls remain valid. The diagnostics output and
record metadata are additive; app workflows need no migration.

## Validation

Thermal facade and FLIR app tests cover metadata sources, fallback reporting,
and one-output compatibility.

## Evidence

The model and provenance contract are documented in `docs/api/thermal.md`; branch
checkpoint `7391e293` carries the implementation before the final squash merge.

## Known limitations and follow-up

Diagnostics describe source and fallback use; they do not estimate a physical
uncertainty interval for a particular camera, surface, or environment.

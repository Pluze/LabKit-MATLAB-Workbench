# EIS selects impedance display units

```labkit-change
id: LK-20260725-eis-impedance-display-units
date: 2026-07-25
sequence: 163
type: feat
compatibility: compatible
component: `labkit_EIS_app` | `1.5.3 -> 1.6.0`
scope: EIS impedance units
scope: EIS project migration
```

## Context

EIS previously plotted and exported every impedance quantity in ohms. Large
spectra were inconvenient to read, and the axis choices embedded the old unit
instead of separating the selected quantity from its display scale.

## Decision and rationale

The App now owns one impedance-unit catalog for mΩ, Ω, kΩ, and MΩ. New
projects default to kΩ. Plot values, labels, and exported impedance columns
use the selected unit while parsed DTA items remain in base ohms.

## Changes

- Added a bound impedance-unit choice to Plot Options.
- Made impedance axis names unit-neutral and rendered the selected unit in
  axis labels.
- Applied the same conversion to CSV values and unit-bearing column names.
- Added EIS project-schema persistence evidence and a version-1 migration.

## User and data impact

New EIS projects open with kΩ impedance axes. Users may switch units without
reloading files or changing source data. Exported impedance values now match
the selected display unit and name that unit in their columns.

## Compatibility and migration

Version-1 EIS projects migrate their old `(... ohm)` axis names to the
unit-neutral choices and select Ω, preserving their previous numeric display
and export meaning. Current saves write project schema version 2.

## Validation

Focused persistence, scientific conversion, result schema, headless
presentation, and hidden-GUI workflow specifications passed. The GUI workflow
changes the real unit control and verifies the native plot label.

## Evidence

- [EIS](../../../../apps/electrochemistry/eis/README.md)
- [DTA Library](../../../../libraries/dta/README.md)

## Known limitations and follow-up

The unit selector is a display/export scale only; it does not perform
electrode-area normalization.

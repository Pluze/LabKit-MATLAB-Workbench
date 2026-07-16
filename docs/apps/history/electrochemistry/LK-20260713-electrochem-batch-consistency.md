# Consistent electrochemistry batch analysis

```labkit-change
schema: 1
id: LK-20260713-electrochem-batch-consistency
date: 2026-07-13
type: fix
compatibility: additive
component: `labkit_CIC_app` | `1.3.7 -> 1.3.8`
component: `labkit_VTResistance_app` | `1.3.7 -> 1.3.8`
```

## Context

CIC and VT Resistance could retain per-file derived values from different
control settings, and CIC could sample outside the recorded time range while
displaying a delay without units.

## Decision and rationale

Treat analysis controls as one batch contract and recompute every file before
display/export so rows cannot silently mix stale and current parameters.

## Changes

- Recompute all loaded files when shared controls change and once more before
  CSV export.
- Label CIC delay in microseconds, reject out-of-range sampling, and export the
  area and delay used for each result.
- Added family regression coverage and audited sibling electrochem apps.

## User and data impact

Batch rows now represent one consistent area, delay, pulse-detection,
resistance-window, and voltage-mode configuration. Invalid delay choices fail
instead of extrapolating a misleading value.

## Compatibility and migration

CIC CSV adds trailing `Area_cm2` and `Delay_us` columns. Existing columns keep
their names and order; VT Resistance exports remain schema-compatible.

## Validation

Electrochem unit and GUI tests cover batch recomputation, display units,
out-of-range handling, and export-time refresh.

## Evidence

The guarded calculations and export builders are app-owned; branch checkpoint
`67ea2286` carries the fix before the final squash merge.

## Known limitations and follow-up

The fix enforces internal batch consistency but does not choose scientifically
appropriate area, delay, or resistance windows for the user.

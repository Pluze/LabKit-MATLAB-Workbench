# Consistent electrochemistry batch analysis

```labkit-change
id: CHG-20260713-electrochem-batch-consistency
date: 2026-07-13
type: fix
compatibility: compatible
component: labkit_CIC_app | 1.3.7 -> 1.3.8
component: labkit_VTResistance_app | 1.3.7 -> 1.3.8
```

## Why

CIC and VT Resistance could retain per-file derived values from different control settings, and CIC could sample outside the recorded time range while displaying a delay without units.

### Accepted choice

Treat analysis controls as one batch contract and recompute every file before display/export so rows cannot silently mix stale and current parameters.

## What changed

- Recompute all loaded files when shared controls change and once more before CSV export.
- Label CIC delay in microseconds, reject out-of-range sampling, and export the area and delay used for each result.
- Added family regression coverage and audited sibling electrochem apps.

## Impact

Batch rows now represent one consistent area, delay, pulse-detection, resistance-window, and voltage-mode configuration. Invalid delay choices fail instead of extrapolating a misleading value.

## Compatibility and limits

CIC CSV adds trailing `Area_cm2` and `Delay_us` columns. Existing columns keep their names and order; VT Resistance exports remain schema-compatible.

### Remaining limits

The fix enforces internal batch consistency but does not choose scientifically appropriate area, delay, or resistance windows for the user.

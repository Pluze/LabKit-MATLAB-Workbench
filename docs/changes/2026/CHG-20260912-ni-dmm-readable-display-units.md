# Readable NI-DMM display units

```labkit-change
id: CHG-20260912-ni-dmm-readable-display-units
date: 2026-09-12
type: fix
compatibility: compatible
component: labkit_NIDMMRecorder_app | 1.1.0 -> 1.1.1
```

## Why

Small currents and large resistances were shown only in the device's base unit, making live values and plot ticks difficult to read. The instrument range and recorded values must retain their existing meaning.

## What changed

The live reading, recent plot, and recent-data table now use one automatically selected engineering unit for voltage, current, or resistance. The choice is based on the current reading and visible sample window; changing the unit refits the plot.

## Impact

Operators can read values such as microamps and kilohms directly without manually counting decimal places. The instrument's Automatic range setting is unaffected.

## Compatibility and limits

CSV and MAT recordings keep unscaled device values and base units. Unknown measurement units are displayed without conversion. A changing sample window can cross an engineering-unit boundary and update the visible unit.

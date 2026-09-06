# Preserve every overlay trace in CSV exports

```labkit-change
id: CHG-20260906-preserve-overlay-export-traces
date: 2026-09-06
type: fix
compatibility: compatible
component: labkit_EIS_app | 1.8.0 -> 1.8.1
component: labkit_ChronoOverlay_app | 1.7.1 -> 1.7.2
```

## Why

Different source files can have the same basename or names that become identical after conversion to MATLAB table identifiers. Assigning export columns by that name replaced earlier curve data silently. Rejecting those files would prevent valid multi-source comparisons, so the existing exporters now assign distinct column names.

## What changed

EIS and Chrono Overlay shorten final column names to MATLAB's supported length and add numeric suffixes for collisions in source order. Every selected source retains its paired coordinate columns. EIS documentation also states the existing finite-value and logarithmic-coordinate filtering performed before export.

## Impact

Exports retain curves whose names collide, and long source names no longer make Chrono Overlay exceed the table column-name limit. Existing noncolliding column names and numerical processing remain unchanged.

## Compatibility and limits

Scripts consuming ambiguous names must select the newly disambiguated columns. EIS still pads independently filtered curves by row index, and Chrono Overlay still interpolates onto the merged aligned-time axis. Column naming does not establish scientific correspondence between different recordings.

# Preserve gait coordinate rows and point columns

```labkit-change
id: CHG-20260906-gait-coordinate-integrity
date: 2026-09-06
type: fix
compatibility: compatible
component: labkit_GaitAnalysis_app | 3.0.1 -> 3.0.2
```

## Why

A supported single-frame pose lost its frame dimension during vector calculations, preventing table construction. Distinct point names could also become the same table identifier and silently replace earlier coordinates.

## What changed

Joint and segment calculations retain explicit frame-by-coordinate shapes. Frame and coordinate exports assign distinct legal column names in point order, including after sanitization or shortening.

## Impact

One-frame inputs retain their kinematics without inventing swing events. Exports keep every point's coordinates. Existing noncolliding names, multi-frame calculations, units, smoothing, and event detection remain unchanged.

## Compatibility and limits

Consumers of ambiguous column names must select the newly disambiguated columns. A single frame cannot establish gait timing or a completed swing. Naming and shape validation do not establish anatomical role accuracy or tracking quality.

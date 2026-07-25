# DTA uses one unit-explicit item and pulse model

```labkit-change
id: LK-20260725-dta-unit-explicit-model
date: 2026-07-25
sequence: 162
type: refactor
compatibility: breaking
component: `labkit.dta` | `2.0.3 -> 3.0.0`
component: `labkit_ChronoOverlay_app` | `1.5.1 -> 1.5.2`
component: `labkit_CIC_app` | `1.5.1 -> 1.5.2`
component: `labkit_CSC_app` | `1.5.1 -> 1.5.2`
component: `labkit_EIS_app` | `1.5.2 -> 1.5.3`
component: `labkit_VTResistance_app` | `1.5.1 -> 1.5.2`
scope: DTA item fields
scope: Electrochemistry Apps
```

## Context

The DTA facade emitted unit-ambiguous legacy fields beside its documented
unit-explicit fields. Pulse results likewise duplicated every phase boundary
as both flat and nested fields. Apps and tests consequently carried fallback
branches even though all production consumers are released together.

## Decision and rationale

The facade now returns one model whose field names state physical units.
Pulse pre, cathodic, gap, anodic, and post windows are nested consistently.
Eliminating parallel representations prevents callers from observing
conflicting values and makes unit conversion an App display concern.

## Changes

- Removed legacy chrono, EIS, alignment, and flat pulse aliases.
- Added canonical pre- and post-pulse window structures.
- Migrated all electrochemistry consumers and tests to the canonical fields.
- Raised the DTA facade major version and updated every dependent App
  requirement.

## User and data impact

App calculations, source DTA files, saved projects, and numerical exports are
unchanged. MATLAB scripts that read the removed DTA aliases must use the
documented unit-explicit fields.

## Compatibility and migration

This is a deliberate DTA facade breaking change. Replace `t`, `Vf`, and `Im`
with `t_s`, `Vf_V`, and `Im_A`; replace EIS vendor-style aliases with the
documented unit-explicit fields; and replace flat pulse windows with
`pulse.<phase>.start_s` and `end_s`.

## Validation

Focused DTA facade and pulse contracts passed together with affected Chrono
Overlay, CIC, EIS, and VT Resistance source, scientific, result, presentation,
and bounded workflow evidence.

## Evidence

- [DTA Library](../../../../libraries/dta/README.md)
- [Electrochemistry Apps](../../../../apps/electrochemistry/README.md)

## Known limitations and follow-up

No known compatibility aliases remain in the DTA item or pulse model.

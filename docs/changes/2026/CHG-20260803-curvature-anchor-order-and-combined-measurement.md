# Curvature editing follows visible path order and measures once

```labkit-change
id: CHG-20260803-curvature-anchor-order-and-combined-measurement
date: 2026-08-03
type: fix
compatibility: compatible
component: labkit_CurvatureMeasurement_app | 1.6.1 -> 1.6.2
```

## Why

The open anchor editor mixed viewport-sized distance thresholds with an append-at-end fallback. A point intended before the first anchor could therefore appear at the end, and points away from the existing path could change insertion behavior after zooming. Curvature Measurement also rendered its inactive static curve beneath the managed editor, leaving an old curve visible while a point was dragged or added. Its separate length and curvature buttons duplicated work because a successful curvature fit already computed and stored the traced length.

### Accepted choice

Order open-path additions by their nearest location on the complete visible path. Extend the nearest global endpoint and insert every interior addition after the owning visible segment, independent of zoom. Keep this policy in the existing App SDK interaction runtime without adding a public API. In Curvature Measurement, let the managed editor exclusively own the curve overlay while editing and expose one measurement action that writes both existing results.

## What changed

- Replaced threshold-driven open-path insertion with visible-path location ordering, including reliable prepend and append behavior.
- Suppressed the inactive Curvature curve and anchors while the managed editor is active, then restored them when editing finishes.
- Replaced the separate fit and length buttons with **Measure length + curvature** while retaining the existing fit action identity.
- Updated workflow text, public interaction help, and focused behavioral specifications for the new ordering and overlay ownership.

## Impact

New anchors appear before the first point, after the last point, or inside the nearest visible curve segment as their spatial placement implies. Dragging and adding no longer leaves an old static curve beneath the editor. One button now produces both traced length and curvature. Existing points, calibration, formulas, units, project fields, CSV columns, and overlay export meaning are unchanged.

## Compatibility and limits

The change is compatible with version-2 App SDK requirements and existing Curvature projects. No project or result migration is required. The former length-only callback remains callable internally, but it is no longer exposed as a separate control.

### Remaining limits

Automated tests prove deterministic ordering and native overlay structure but do not reproduce physical double-click and drag feel on every platform. Manual pointer feel remains an interactive validation boundary.

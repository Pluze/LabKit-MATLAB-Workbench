# EIS uses explicit plot-view actions

```labkit-change
id: CHG-20260721-eis-explicit-plot-views
date: 2026-07-21
type: fix
compatibility: compatible
component: labkit_EIS_app | 1.5.1 -> 1.5.2
```

## Why

EIS inferred an equal X/Y aspect ratio from specific Nyquist axis selections. That implicit choice could shrink the usable plotting area and make a redraw look unlike the user's current view.

### Accepted choice

Keep plot semantics in EIS, but use the App framework's viewport revision and data-fitting capability for view behavior. Equal data units are now an explicit one-time view reset rather than a rule tied to axis labels or a constraint on later zooming.

## What changed

- Removed the EIS axis-label rule that automatically selected `axis equal`.
- Added **Fit X/Y limits** for independent data-fitted limits.
- Added **Use equal X/Y scale** for an explicit equal-data-unit view without changing the plot size allocated by the App layout.
- Kept ordinary zoom and wheel viewports under the framework-managed viewport preservation path.

## Impact

Nyquist plots now begin with independent limits and a stable plot area. Equal scaling preserves the App layout's plot size. The new view buttons change only transient presentation; EIS sources, projects, calculations, and exports are unchanged.

## Compatibility and limits

Existing saved projects remain valid. The selected axes and Log X/Y options keep their existing meaning; the equal-aspect choice is intentionally not saved with the project.

### Remaining limits

Automated GUI coverage cannot assess visual balance on every monitor and MATLAB release. Verify the Nyquist layout interactively before a release.

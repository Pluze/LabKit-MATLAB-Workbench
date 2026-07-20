# T-Test plots gain truthful limits and an explicit view reset

```labkit-change
schema: 2
id: LK-20260720-ttest-plot-viewport-and-density
date: 2026-07-20
sequence: 143
type: feat
compatibility: compatible
component: `labkit_TTestWizard_app` | `1.1.1 -> 1.2.0`
scope: Statistics Apps
scope: App Framework
```

## Context

T-Test Wizard used the absolute data magnitude as a minimum padding span, so
box plots with a narrow nonzero range could receive excessive empty space.
Bar-chart zoom could move the zero baseline away from the y-axis edge, and
the App had no visible action for returning to the fitted view. Two short
status summaries also occupied detail-panel height.

## Decision and rationale

Fit limits from the graphics that carry statistical meaning: distribution or
bar extents, optional observations, standard-deviation error bars, and
significance brackets. Keep zero at the appropriate edge for one-sided bar
data because truncated bar baselines distort magnitude; mixed-sign data must
instead show zero inside the axis. Keep box plots distribution-fitted.

Expose an App-owned reset action backed by the framework's general transient
plot-view revision. Use the framework's line-count hint for short summaries
rather than adding T-Test-specific pixel sizes.

## Changes

- Corrected the fitted span and padding used by bar, box, and annotation
  geometry.
- Kept zero at the lower or upper y-limit for positive or negative bar plots
  across programmatic, toolbar, and wheel-driven limit changes.
- Added **Reset plot view** without recalculating tests or changing project
  data.
- Refined box fill, outlines, whiskers, observation overlays, bar opacity,
  error-bar caps, and outward ticks.
- Reduced **What will run** and **Result family** to two-line summary panels
  with the framework's summary reading size.

## Compatibility and user impact

Project schema 2, completed comparison values, CSV outputs, formulas, and test
choices are unchanged. T-Test Wizard 1.2.0 requires `labkit.app` 1.2 or later
for compact summaries and one-shot plot viewport revisions. Existing projects
open without migration.

## Validation and evidence

- The T-Test hidden-GUI workflow checks fitted limits, zero-edge persistence,
  box-plot independence, compact summary sizing, and explicit view reset.
- Framework contract tests cover plot viewport preservation and revision
  resets.
- Documentation rendering and history consistency cover the versioned change.

## Follow-up

Developer-led visual review should compare box, bar, error-bar, and bracket
appearance at typical desktop sizes and with real scientific label lengths.

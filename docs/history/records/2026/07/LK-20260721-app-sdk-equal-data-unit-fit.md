# App SDK supports equal-data-unit plot fitting

```labkit-change
id: LK-20260721-app-sdk-equal-data-unit-fit
date: 2026-07-21
sequence: 148
type: fix
compatibility: compatible
component: `labkit.app` | `1.2.1 -> 1.2.2`
scope: App Framework
scope: EIS Overlay
```

## Context

Apps needed an equal X/Y data-unit view for plots such as Nyquist diagrams,
but setting an axes aspect mode directly also changed the allocated drawing
area and persisted into later wheel and zoom interactions.

## Decision and rationale

Keep viewport geometry in the framework fitter. An App can request equal data
units while fitting the current plotted data, after which ordinary framework
viewport preservation continues without an aspect lock.

## Changes

- Added the public `EqualDataUnits` option to
  `labkit.app.plot.fitAxesToGraphics`.
- Fit equal data units by expanding the smaller data span for the current axes
  pixel geometry, including logarithmic dimensions in log space.
- Removed the retired EIS axis-label rule; EIS now exposes explicit fit and
  equal-scale view actions.

## User and data impact

The new option is additive. Existing fit calls keep independent X/Y limits.
EIS projects and exports are unchanged; equal scaling is a transient view
action and does not alter later zoom or wheel behavior.

## Compatibility and migration

No project or result migration is required. Existing callers retain their
independent fit behavior unless they opt into `EqualDataUnits=true`.

## Validation

- EIS GUI coverage exercises independent fitting, explicit equal scaling, and
  later viewport preservation.
- The App SDK plot helper tests cover finite data, logarithmic axes, and the
  public option contract.

## Evidence

The fitting helper applies limits from finite plotted data and expands only the
smaller working-space span for the axes pixel geometry. The EIS workflow test
then verifies that a later framework redraw preserves the chosen viewport.

## Known limitations and follow-up

Developer-led visual validation remains responsible for assessing layout
balance on target displays and MATLAB releases.

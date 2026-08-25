# App SDK supports equal-data-unit plot fitting

```labkit-change
id: CHG-20260721-app-sdk-equal-data-unit-fit
date: 2026-07-21
type: fix
compatibility: compatible
component: labkit.app | 1.2.1 -> 1.2.2
```

## Why

Apps needed an equal X/Y data-unit view for plots such as Nyquist diagrams, but setting an axes aspect mode directly also changed the allocated drawing area and persisted into later wheel and zoom interactions.

### Accepted choice

Keep viewport geometry in the framework fitter. An App can request equal data units while fitting the current plotted data, after which ordinary framework viewport preservation continues without an aspect lock.

## What changed

- Added the public `EqualDataUnits` option to `labkit.app.plot.fitAxesToGraphics`.
- Fit equal data units by expanding the smaller data span for the current axes pixel geometry, including logarithmic dimensions in log space.
- Removed the retired EIS axis-label rule; EIS now exposes explicit fit and equal-scale view actions.

## Impact

The new option is additive. Existing fit calls keep independent X/Y limits. EIS projects and exports are unchanged; equal scaling is a transient view action and does not alter later zoom or wheel behavior.

## Compatibility and limits

No project or result migration is required. Existing callers retain their independent fit behavior unless they opt into `EqualDataUnits=true`.

### Remaining limits

Developer-led visual validation remains responsible for assessing layout balance on target displays and MATLAB releases.

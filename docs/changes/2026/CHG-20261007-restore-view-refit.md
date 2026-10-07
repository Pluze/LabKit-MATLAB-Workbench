# Restore View fits current plot data

```labkit-change
id: CHG-20261007-restore-view-refit
date: 2026-10-07
type: fix
compatibility: compatible
component: labkit.app | 3.5.0 -> 3.5.1
```

## Why

Custom wheel navigation changes axes limits without necessarily creating MATLAB's native restore history, so Restore View can leave a zoomed plot unchanged. Fitting current data provides a predictable recovery without storing another default viewport or zoom history.

## What changed

Restore View now returns X and all Y rulers to automatic limits in App plots, auxiliary plot windows, and editable plot popouts.

## Impact

Users can recover the full current data range after custom zoom, including both sides of dual-Y plots. Other plots keep their viewports.

## Compatibility and limits

Restoration fits current data rather than recovering an earlier App-specified range. This changes no scientific values or public API and does not change the ownership of native zoom or pan modes.

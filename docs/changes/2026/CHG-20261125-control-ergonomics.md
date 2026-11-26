# Adjust parameters and select sources in the native workbench

```labkit-change
id: CHG-20261125-control-ergonomics
date: 2026-11-25
type: fix
compatibility: compatible
component: labkit.app | 3.7.0 -> 3.7.1
component: labkit_DICPostprocess_app | 1.8.0 -> 1.9.0
component: labkit_EIS_app | 1.12.0 -> 1.12.1
component: labkit_Mark10Monitor_app | 2.3.0 -> 2.3.1
component: labkit_CIC_app | 1.8.0 -> 1.9.0
component: labkit_CSC_app | 1.8.0 -> 1.9.0
component: labkit_VTResistance_app | 1.8.0 -> 1.9.0
```

## Why

Side-by-side number fields and sliders left little room for dragging. A file chooser could also crowd the selected filename out of view.

## What changed

The native workbench places paired sliders below their number fields and single filenames below their choosers. DIC Postprocess separates source selection, display settings and results. CIC, CSC and VT Resistance put plot settings on their own task page. EIS gives frequency sliders their own row and separates group creation from file assignment. Mark-10 gives both time-range endpoints equal space.

## Impact

Operators can enter exact values, inspect filenames and switch between analysis and display settings within the same workbench.

## Compatibility and limits

Existing project data and scientific parameters retain their meanings.

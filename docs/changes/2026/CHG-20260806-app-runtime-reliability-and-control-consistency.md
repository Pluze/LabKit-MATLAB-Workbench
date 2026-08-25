# App runtime reliability and native control consistency

```labkit-change
id: CHG-20260806-app-runtime-reliability-and-control-consistency
date: 2026-08-06
type: feat
compatibility: compatible
component: labkit.app | 2.2.0 -> 2.3.0
component: labkit_launcher | 1.8.3 -> 1.8.4
```

## Why

An App session that encountered an error could close before its diagnostic bundle was exported. Some bound controls and file selections also entered the runtime through paths that did not share the ordinary callback transaction, and native controls could acquire inconsistent height or divider treatment. Installation repair could meanwhile begin while a LabKit App was still open.

### Accepted choice

Treat diagnostics, semantic input handling, native presentation, and safe installation replacement as one App-runtime reliability boundary. Persist a compact bundle after closing an errored session, give every editable surface one declared behavior owner, and process bindings and callbacks through the same validated transaction. Keep actions single-line, let readonly text adapt to available width, and refuse installation replacement while an App remains open.

## What changed

- Closing a session after an ERROR or CRITICAL event automatically writes one compact diagnostic bundle; manual export also defaults to compact state.
- `CallbackContext.inform` presents successful or neutral information without error styling.
- Editable controls, file lists, plot modes, tables, and workspace pages must declare the binding or callback that owns their behavior.
- Bound values and App callbacks commit or roll back together through the shared runtime transaction.
- Native action rows use a consistent single-line rhythm, readonly text adapts to its content and width, and dividers appear only between resizable sections.
- Launcher repair and version updates refuse to replace LabKit while an App is open.

## Impact

Users receive a recoverable diagnostic ZIP after an errored session closes, and successful notices use information styling. Input failures retain the last valid project and presentation together. Buttons and status text remain easier to scan across Apps, and installation updates cannot disrupt a running App. Scientific calculations, project formats, result files, and source data are unchanged. Diagnostic bundles may contain sensitive paths and values and must be reviewed before sharing.

## Compatibility and limits

The additions remain within the version-2 App SDK compatibility range. Existing tracked Apps already declare owners for editable controls and need no source or saved-data migration. A previously accepted custom definition with an inert editable surface must add the documented binding or callback, or make that surface read-only. Existing Launcher commands and installations remain compatible.

### Remaining limits

Automated hidden-GUI evidence does not prove pointer feel, text rendering at every display scale, or visual quality on every supported MATLAB release. Final subjective App inspection remains a manual boundary. A process termination that bypasses Runtime close cannot create the close-time bundle.

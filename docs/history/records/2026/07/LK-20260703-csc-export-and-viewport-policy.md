# CSC export and viewport policy

```labkit-change
id: LK-20260703-csc-export-and-viewport-policy
date: 2026-07-03
sequence: 35
type: feat
compatibility: compatible
component: `labkit.ui` | `4.0.0 -> 4.1.0`
component: `labkit_DICPostprocess_app` | `1.3.2 -> 1.3.3`
component: `labkit_DICPreprocess_app` | `1.3.2 -> 1.3.3`
component: `labkit_ChronoOverlay_app` | `1.3.2 -> 1.3.3`
component: `labkit_CIC_app` | `1.3.4 -> 1.3.5`
component: `labkit_CSC_app` | `1.3.4 -> 1.3.6`
component: `labkit_EIS_app` | `1.3.2 -> 1.3.3`
component: `labkit_VTResistance_app` | `1.3.4 -> 1.3.5`
component: `labkit_BatchImageCrop_app` | `1.6.4 -> 1.6.5`
component: `labkit_CurvatureMeasurement_app` | `1.3.2 -> 1.3.3`
component: `labkit_FLIRThermal_app` | `1.2.3 -> 1.2.4`
component: `labkit_FocusStack_app` | `1.4.3 -> 1.4.4`
component: `labkit_ImageEnhance_app` | `1.5.3 -> 1.5.4`
component: `labkit_ImageMatch_app` | `1.5.3 -> 1.5.4`
component: `labkit_NerveResponseAnalysis_app` | `1.3.2 -> 1.3.3`
component: `labkit_ResponseReviewStats_app` | `1.3.2 -> 1.3.3`
component: `labkit_RHSPreview_app` | `1.3.2 -> 1.3.3`
component: `labkit_ECGPrint_app` | `1.3.3 -> 1.3.4`
scope: CSC export and viewport policy
```

## Context

CSC could export the selected cycle, but comparing activation and stability
across a recording required all cycles in one dataset. In parallel, app layouts
made their own assumptions about minimum window size and scrollable content,
so the same control panel could behave differently in a small viewport.

## Decision and rationale

Add an explicit all-cycle CSC export without changing the existing selected-
cycle result. Define viewport behavior in the UI contract so each app declares
its content needs while the framework decides when scrolling or minimum sizing
is necessary.

## Changes

- `labkit.ui` `4.0.0 -> 4.1.0`
- All supported apps received aligned patch bumps.

- Added CSC all-cycle export.
- Added viewport policy support and aligned app contracts with the UI 4.x line.

## User and data impact

CSC users could export every cycle for downstream comparison while retaining
the existing focused export. Across the workbench, small windows followed one
scrolling and sizing policy instead of clipping controls according to the app
that happened to create them.

## Compatibility and migration

The selected-cycle CSC export remained available and the all-cycle table was a
new option. Existing app definitions inherited the default viewport behavior
until they declared more specific needs.

## Validation

Commit `a69829c6` added a dedicated CSC export suite, extended the CSC GUI
layout test, and added workbench viewport coverage.

## Evidence

- Main commit `a69829c6`.

## Known limitations and follow-up

All-cycle CSV output was a separate export choice rather than a new session
format. Later CSC work refined column naming and voltage/current organization.

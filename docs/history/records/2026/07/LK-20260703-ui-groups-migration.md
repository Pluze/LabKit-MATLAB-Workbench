# UI groups migration

```labkit-change
id: LK-20260703-ui-groups-migration
date: 2026-07-03
sequence: 34
type: refactor
compatibility: compatible
component: `labkit.ui` | `3.4.5 -> 4.0.0`
component: `labkit_DICPostprocess_app` | `1.3.1 -> 1.3.2`
component: `labkit_DICPreprocess_app` | `1.3.1 -> 1.3.2`
component: `labkit_ChronoOverlay_app` | `1.3.1 -> 1.3.2`
component: `labkit_CIC_app` | `1.3.3 -> 1.3.4`
component: `labkit_CSC_app` | `1.3.3 -> 1.3.4`
component: `labkit_EIS_app` | `1.3.1 -> 1.3.2`
component: `labkit_VTResistance_app` | `1.3.3 -> 1.3.4`
component: `labkit_BatchImageCrop_app` | `1.6.3 -> 1.6.4`
component: `labkit_CurvatureMeasurement_app` | `1.3.1 -> 1.3.2`
component: `labkit_FLIRThermal_app` | `1.2.2 -> 1.2.3`
component: `labkit_FocusStack_app` | `1.4.2 -> 1.4.3`
component: `labkit_ImageEnhance_app` | `1.5.2 -> 1.5.3`
component: `labkit_ImageMatch_app` | `1.5.2 -> 1.5.3`
component: `labkit_NerveResponseAnalysis_app` | `1.3.1 -> 1.3.2`
component: `labkit_ResponseReviewStats_app` | `1.3.1 -> 1.3.2`
component: `labkit_RHSPreview_app` | `1.3.1 -> 1.3.2`
component: `labkit_ECGPrint_app` | `1.3.2 -> 1.3.3`
scope: UI groups migration
```

## Context

The declarative runtime described actions as a mostly flat list with optional
group hints. Apps with several phases could not reliably express which controls
belonged together, and layout code had to infer more structure than the app had
actually declared.

## Decision and rationale

Make groups the primary unit of control layout. Each group would carry its
title and controls, giving the runtime enough structure to render related
actions together without learning app-specific labels or workflow rules.

## Changes

- `labkit.ui` `3.4.5 -> 4.0.0`
- All supported apps received patch bumps.

- Replaced action groups with UI groups.
- Moved the reusable UI contract into the 4.x line.

## User and data impact

Apps retained their actions, but related controls appeared in explicit visual
sections. App definitions became easier to scan because their grouping matched
the panels users saw.

## Compatibility and migration

- App workflow definitions had to align with the new grouped UI contract.

## Validation

The migration updated UI specification tests, basic-control and workbench GUI
tests, app package structure checks, and all supported app definitions. The
exact historical command was not recorded.

## Evidence

- Main commit `e81243a3`.

## Known limitations and follow-up

This was a breaking definition-format change and established the UI 4.x line.
UI 5 later renamed facade packages by responsibility but retained explicit
groups as the layout model.

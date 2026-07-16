# UI 5 facade redesign, app migration, and plot refresh

```labkit-change
schema: 1
id: LK-20260706-ui-5-facade-redesign-app-migration-and-plot-refresh
date: 2026-07-06
type: refactor
compatibility: breaking
component: `labkit_launcher` | `1.2.3 -> 1.2.4`
component: `labkit.ui` | `4.2.0 -> 4.2.1`
component: `labkit.ui` | `4.2.1 -> 5.0.0`
component: `labkit_DICPostprocess_app` | `1.3.3 -> 1.3.4`
component: `labkit_DICPreprocess_app` | `1.3.3 -> 1.3.4`
component: `labkit_ChronoOverlay_app` | `1.3.3 -> 1.3.5`
component: `labkit_CIC_app` | `1.3.5 -> 1.3.7`
component: `labkit_CSC_app` | `1.3.7 -> 1.3.9`
component: `labkit_EIS_app` | `1.3.3 -> 1.3.4`
component: `labkit_VTResistance_app` | `1.3.5 -> 1.3.7`
component: `labkit_BatchImageCrop_app` | `1.6.5 -> 1.6.6`
component: `labkit_CurvatureMeasurement_app` | `1.3.3 -> 1.3.4`
component: `labkit_FLIRThermal_app` | `1.2.7 -> 1.2.8`
component: `labkit_FocusStack_app` | `1.4.4 -> 1.4.5`
component: `labkit_ImageEnhance_app` | `1.5.4 -> 1.5.5`
component: `labkit_ImageMatch_app` | `1.5.4 -> 1.5.5`
introduced: `labkit_FigureStudio_app` | `0.1.0`
component: `labkit_FigureStudio_app` | `0.1.0 -> 0.1.1`
component: `labkit_FigureStudio_app` | `0.1.1 -> 0.1.2`
component: `labkit_FigureStudio_app` | `0.1.2 -> 0.1.4`
component: `labkit_NerveResponseAnalysis_app` | `1.3.3 -> 1.3.4`
component: `labkit_ResponseReviewStats_app` | `1.3.3 -> 1.3.4`
component: `labkit_RHSPreview_app` | `1.3.3 -> 1.3.4`
component: `labkit_ECGPrint_app` | `1.3.4 -> 1.3.5`
```

## Context

- App authors now use a smaller set of responsibility-named UI packages instead
  of learning old mixed app/spec/view/tool/diag buckets.
- Shared plot-area mechanics live in the framework, so app code can focus on
  domain plotting while the framework handles stale axes state, fitted ranges,
  empty previews, coordinate offsets, and registered preview utilities.
- Electrochem apps now match the active file selection after add/remove/clear
  workflows, and CIC keeps the critical Emc/Ema readout visible on dense plots.
- Users can distinguish long launcher work from a frozen MATLAB session.
- Multi-plot apps expose utility actions in a clearer, less repetitive flow.
- Figure cleanup and data/script export move into a dedicated reusable workflow
  instead of crowding every popout plot window.

## Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

## Changes

- `labkit_launcher` `1.2.3 -> 1.2.4`
- `labkit.ui` `4.2.0 -> 5.0.0`
- `labkit_FigureStudio_app` `0.1.0 -> 0.1.4`
- `labkit_ChronoOverlay_app` `1.3.3 -> 1.3.5`
- `labkit_CIC_app` `1.3.5 -> 1.3.7`
- `labkit_CSC_app` `1.3.7 -> 1.3.9`
- `labkit_EIS_app` `1.3.3 -> 1.3.4`
- `labkit_VTResistance_app` `1.3.5 -> 1.3.7`
- `labkit_DICPreprocess_app` `1.3.3 -> 1.3.4`
- `labkit_DICPostprocess_app` `1.3.3 -> 1.3.4`
- `labkit_BatchImageCrop_app` `1.6.5 -> 1.6.6`
- `labkit_CurvatureMeasurement_app` `1.3.3 -> 1.3.4`
- `labkit_FLIRThermal_app` `1.2.7 -> 1.2.8`
- `labkit_FocusStack_app` `1.4.4 -> 1.4.5`
- `labkit_ImageEnhance_app` `1.5.4 -> 1.5.5`
- `labkit_ImageMatch_app` `1.5.4 -> 1.5.5`
- `labkit_RHSPreview_app` `1.3.3 -> 1.3.4`
- `labkit_NerveResponseAnalysis_app` `1.3.3 -> 1.3.4`
- `labkit_ResponseReviewStats_app` `1.3.3 -> 1.3.4`
- `labkit_ECGPrint_app` `1.3.4 -> 1.3.5`

- Reorganized the UI facade into `labkit.ui.runtime`, `layout`, `control`,
  `plot`, `interaction`, and `debug` so app authors can find lifecycle,
  data-only layout, control update, plot-area, pointer/tooling, and diagnostic
  APIs by responsibility.
- Replaced the old app/spec/view/tool/diag UI paths with UI 5 names and moved
  every app to `definition(..., "Layout", @buildWorkbenchLayout)` plus
  `labkit.ui.layout.*`, `labkit.ui.control.*`, `labkit.ui.plot.*`,
  `labkit.ui.interaction.*`, and `labkit.ui.debug.*`.
- Added framework-owned plot helpers for registered axes lookup, clearing,
  empty-state messages, fitted limits, canvas framing, image preview redraw,
  and data/fraction coordinate conversion.
- Reset electrochem plot axes and legends when files are cleared, removed, or
  redrawn so old ranges, markers, shaded windows, and annotations do not remain
  after the file list changes.
- Refit CIC, Chrono Overlay, CSC all-cycle, and VT Resistance redraws to the
  current plotted data instead of preserving stale manual zoom limits.
- Staggered CIC Emc/Ema marker labels with readable white backgrounds so key
  extrema labels are less likely to be hidden by voltage-step or window
  annotations.
- Added visible busy/progress feedback for launcher actions that can wait on
  file scans, artifact cleanup, app startup, profiling, GitHub version lookup,
  or update/install work.
- Added launcher and version-manager busy gates so repeated clicks do not start
  overlapping synchronous operations.
- Replaced top workbench utility buttons with native window utility menus.
- Changed workbench plot popout/copy/save actions to operate on every
  registered preview axes in a multi-axes app.
- Replaced icon-only popout figure tools with visible text buttons for font,
  plotted-line, axes, grid, and Studio handoff controls.
- Added the LabKit Core Figure Studio app for opening MATLAB `.fig` files,
  switching between the measured LabKit single-panel style and the imported
  FIG defaults, tuning font/line/grid parameters, and exporting visible
  graphics data packages with reconstruction scripts.
- Normalized imported FIG axes before applying Studio canvas and style
  constraints so source layout/aspect metadata and file-selection titles cannot
  collapse the preview.
- Centered the managed preview canvas in the app preview grid so styled FIG
  labels and plot content render in the visible canvas instead of the corner
  cell.
- Added a `labkit.ui.plot.fitCanvas` canvas-frame helper so fixed-size preview
  axes use the framework-owned preview grid policy instead of app-owned
  row/column layout code.

## User and data impact

- App authors now use a smaller set of responsibility-named UI packages instead
  of learning old mixed app/spec/view/tool/diag buckets.
- Shared plot-area mechanics live in the framework, so app code can focus on
  domain plotting while the framework handles stale axes state, fitted ranges,
  empty previews, coordinate offsets, and registered preview utilities.
- Electrochem apps now match the active file selection after add/remove/clear
  workflows, and CIC keeps the critical Emc/Ema readout visible on dense plots.
- Users can distinguish long launcher work from a frozen MATLAB session.
- Multi-plot apps expose utility actions in a clearer, less repetitive flow.
- Figure cleanup and data/script export move into a dedicated reusable workflow
  instead of crowding every popout plot window.

## Compatibility and migration

- Breaking UI facade migration: app code must use the UI 5 package paths and
  require `labkit.ui >=5 <6`.

## Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

## Evidence

- Main UI 5 squash commit.

## Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

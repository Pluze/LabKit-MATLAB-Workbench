# UI 5 facade redesign, app migration, and plot refresh

```labkit-change
schema: 2
id: LK-20260706-ui-5-facade-redesign-app-migration-and-plot-refresh
date: 2026-07-06
sequence: 38
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

The declarative runtime had made app structure more consistent, but its public
packages still reflected the order in which features had been extracted:
`app`, `spec`, `view`, `tool`, and `diag` mixed lifecycle, layout, plotting,
interaction, and diagnostics. App authors often had to know implementation
history to guess where an operation belonged.

Plot behavior exposed the cost of that ambiguity. Apps independently cleared
axes, fitted limits, translated image coordinates, registered previews, and
handled empty states. After removing or changing a file, an electrochem plot
could retain limits, legends, or annotations from the previous selection.

Launcher operations also needed visible progress, and the growing collection
of popout-figure actions no longer fit comfortably in every app. Figure
cleanup, style adjustment, data export, and reconstruction were substantial
enough to justify their own workflow.

## Decision and rationale

Name the UI facade by responsibility: runtime, layout, controls, plots,
interactions, and debugging. Move reusable axes mechanics into the plot layer,
then migrate every supported app in one breaking version so old and new package
names cannot coexist indefinitely. Give long launcher operations one busy and
progress model, and move advanced figure work into Figure Studio rather than
expanding the app shell further.

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

App plots now followed the current file selection: clearing or changing data
also cleared stale ranges, legends, markers, and annotations. CIC kept Emc and
Ema labels readable on dense traces, and multi-axes apps offered one consistent
set of plot utilities. Launcher progress distinguished a long synchronous
operation from a frozen MATLAB session and rejected repeated clicks while that
operation was active.

Figure Studio added a separate place to open a `.fig`, compare the imported
style with a LabKit single-panel style, adjust visible graphics, and export the
axes data with a reconstruction script. These operations worked on figure
presentation and visible graphics; they did not replace the scientific export
owned by the source app.

For app authors, the breaking rename made API discovery more direct. Lifecycle
code used `labkit.ui.runtime`, layout descriptions used `labkit.ui.layout`, and
plot or interaction code no longer depended on a broad historical bucket.

## Compatibility and migration

- Breaking UI facade migration: app code must use the UI 5 package paths and
  require `labkit.ui >=5 <6`.

## Validation

Commit `78f4827e` migrated 383 source and test files and added focused plot-
helper and neurophysiology layout coverage. Launcher progress received its own
GUI suite in `edbc79d8`. Figure Studio added GUI and result-export suites in
`4c841d6f`, followed by source-axes import tests in `7edd619f`. Exact local
commands for the combined release were not recorded.

## Evidence

- UI 5 facade and app migration `78f4827e`.
- Launcher progress and plot utilities `edbc79d8`.
- Figure Studio `4c841d6f` and source-axes cleanup `8aeee1f1`.
- FIG import normalization `7edd619f`.

## Known limitations and follow-up

UI 5 clarified package ownership, but app code still performed much of its own
lifecycle and rendering coordination. Runtime V2 later took explicit ownership
of startup, callbacks, presenters, injected services, and serializable state.

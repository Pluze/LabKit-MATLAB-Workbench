# Apps

Apps are the owning layer for domain-specific workflows. They are first-class deliverables, not examples for a hidden platform. Each app should remain independently launchable and useful for a concrete experimental task.

Apps compose `labkit.ui.*` and, when needed, data facades such as `labkit.dta.*` or `labkit.biosignal.*`, while keeping calculations, plotting decisions, displayed result fields, and export schemas local to the app file. Apps may evolve faster than the reusable library because they track real lab needs.

## Startup

From MATLAB:

```matlab
startup_labkit
```

This adds the repository root, `apps/`, and normal nested app category folders to the MATLAB path.

## Current Electrochemistry Apps

```text
labkit_CIC_app
labkit_VTResistance_app
labkit_CSC_app
labkit_EIS_app
labkit_ChronoOverlay_app
```

The current electrochemistry app bodies live under `apps/electrochem/`.

## Current DIC Apps

```text
labkit_DICPreprocess_app
labkit_DICPostprocess_app
```

The current DIC app bodies live under `apps/dic/`. They use `labkit.ui.*` for the shared GUI shell and keep image registration, crop geometry, Ncorr MAT extraction, strain overlays, summaries, and exports local to the owning app files.

## Current Image Measurement Apps

```text
labkit_CurvatureMeasurement_app
```

The current image measurement app bodies live under `apps/image_measurement/`. They use `labkit.ui.*` for the shared GUI shell and keep image-point picking, scale measurement, curvature fitting, overlays, summaries, and exports local to the owning app files. These apps are separate from DIC because their workflows are general image measurements rather than DIC preprocessing or strain postprocessing.

## Current Wearable Biosignal Apps

```text
labkit_ECGPrint_app
```

The current wearable app bodies live under `apps/wearable/`. They use `labkit.ui.*` for the shared GUI shell and `labkit.biosignal.*` for GUI-free recording loading, channel extraction, time ROI, filtering, event/segment handling, template-residual SNR measurements, and group comparisons. The app owns ECG-specific workflow wording, SNR-over-time display, class labels, plot layout, and export choices.

## App Status

Status labels are intentionally lightweight and should not overclaim maturity:

| Status | Meaning |
| --- | --- |
| `routine` | Current daily-use workflow with established behavior. |
| `active` | Current workflow still being refined through real use. |
| `experimental` | Newer utility or workflow under evaluation. |
| `archived` | Kept for reference, not part of normal use. |

Current app-family status:

| App family | Status | Notes |
| --- | --- | --- |
| Electrochemistry | routine | Current DTA-backed workflows used through the DTA facade. |
| DIC | active | Current image workflows under direct manual GUI validation. |
| Image measurement | experimental | Newer general measurement utilities separated from DIC. |
| Wearable biosignal | experimental | Exploratory ECG signal quality, SNR, and print/export workflow built on the biosignal facade. |

## App Ownership

The app owns:

- accepted input kind and parser requirements
- option defaults and controls
- domain logic and result fields
- plot labels, annotations, and interaction choices
- summary text
- result table columns and export formatting
- failed-row behavior
- callback ordering, alerts, and log wording

Move code into `+labkit` only when it is reusable without app vocabulary, testable independently, and useful beyond one workflow.

## App File Layout

Keep new lab apps as explicit single files, organized roughly in this order:

```text
1. Entry validation and optional test hook
2. App state and GUI construction
3. Nested callbacks for file/session actions
4. Nested refresh/render/export callbacks that touch UI handles
5. End of the public app function
6. App-local domain functions
7. App-local table/export functions
8. App-local plotting annotation helpers
9. Small formatting, parsing, interpolation, and numeric utilities
```

Nested functions may read and update GUI handles or app state. Local functions after the app `end` should be GUI-free when practical so tests can call them through narrow app test hooks.

The preferred public shape is one launchable app entry point per workflow. That does not require every implementation detail to stay in one giant function forever. If an app becomes too large, app-owned private helpers are acceptable when they stay under the app family, are not public reusable APIs, and do not reintroduce experiment-specific helper packages as a library surface.

## New App Starting Pattern

Do not start new apps from long copy-only template files. Start from the current app that is closest in scope, then reduce it to the needed workflow while preserving these boundaries:

- GUI-only apps call `labkit.ui.createWorkbench`, define app-specific controls inside left tabs, and render prepared data on the right.
- DTA-backed apps keep file discovery/loading/session operations behind `labkit.dta.*` and keep analysis, plotting, result tables, and exports app-local.
- Biosignal-backed apps keep recording loading, channel extraction, signal processing, events, segments, and generic measurements behind `labkit.biosignal.*` while keeping workflow interpretation, plots, labels, and exports app-local.
- Apps should declare custom left tabs with `labkit.ui.tabSpec` when the standard three-section tab is not enough; use `resizeRows` in the tab spec for user-adjustable section heights.
- New app files belong under `apps/<category>/` and should remain explicit public entry points. Split app-owned private helpers only when that improves maintainability without making app-specific decisions look reusable.

## New App Checklist

Define these before adding controls or helpers:

```text
1. Accepted input kind and parser/data requirements
2. Session or loaded item shape
3. Domain options and defaults
4. Domain result fields
5. Plot axes, labels, and annotations
6. Summary fields shown in the GUI
7. Result table columns and units
8. Export format and failed-row behavior
9. Validation fixture or synthetic test case
10. GUI shell type and file-selection mode
```

Prefer `labkit.ui.createWorkbench` even when the app has only one small control page. This keeps daily app interaction consistent as `apps/<category>/` grows while leaving domain-specific tab content under app ownership.

## Extraction Checklist

Before moving app code into `+labkit`, check that the helper:

- can be named without experiment-specific vocabulary
- does not encode domain units, thresholds, result columns, or paper-specific logic
- does not read or mutate app state directly
- can be tested independently
- is used by at least two real apps, or clearly belongs to a broad app family facade
- reduces duplication without making the public API harder to understand

If those conditions are not met, keep the code app-local. Adding apps is expected; expanding public library API should be conservative.

## App Validation

Pure app calculations, export table construction, and plotting helpers belong in the automated `apps` suite and run in the default GitHub Actions workflow. GUI launch/layout contracts are checked by focused local GUI profiles:

```bash
scripts/run_matlab_tests.sh --profile electrochem
scripts/run_matlab_tests.sh --profile dic
scripts/run_matlab_tests.sh --profile image_measurement
scripts/run_matlab_tests.sh --profile wearable
```

Interactive GUI workflows, including manual file selection and visual inspection, are intentionally validated manually during app work.

## Current App-Specific Notes

Chrono overlay pulse-gap alignment, overlay plotting, and overlay export table construction live as local functions in `apps/electrochem/labkit_ChronoOverlay_app.m`.

EIS overlay axis-value generation, plotting, and plot-export table construction are local functions in `apps/electrochem/labkit_EIS_app.m`.

CSC CT/CV charge integration is a local detail of `apps/electrochem/labkit_CSC_app.m`; it is not a separate reusable library API.

VT steady-window selection and baseline estimation are local details of `apps/electrochem/labkit_VTResistance_app.m`.

Current VT CSV column order:

```text
File,Ic_A,Ia_A,Vc_ss_V,Va_ss_V,Vc_baseline_V,Va_baseline_V,dVc_V,dVa_V,Rc_bc_ohm,Ra_bc_ohm,Ravg_bc_ohm,WindowMode,Detection,Status
```

Current CIC CSV column order uses one of:

```text
File,Amp_A,Emc_V,Ema_V,Qc_C,Qa_C,Qt_C,CICc_mCcm2,CICa_mCcm2,CICt_mCcm2,Safe,Detection
File,Amp_A,Emc_V,Ema_V,Qc_C,Qa_C,Qt_C,CICc_uCcm2,CICa_uCcm2,CICt_uCcm2,Safe,Detection
```

The current CV/CSC app has no CSV export workflow.

DIC preprocess image registration, inline right-preview ROI selection, paired-crop geometry, and editable ROI mask drawing are local details of `apps/dic/labkit_DICPreprocess_app.m`. The app keeps original loaded images plus a current working pair, so manual/automatic alignment and crop operations can be applied repeatedly in either order and undone. False-color preview compares the current pair even before alignment, and one save action exports the current reference/current moving images. The mask workflow uses the reusable UI anchor-curve editor for curve or straight-line boundaries, double-click add/insert point ordering, drag-to-move anchors, double-click anchor deletion, and preview zoom; app-local logic still owns boundary preview, add/subtract operations on a white/black mask canvas, and separate undo for canvas edits. ROI masks are saved as white-inside / black-outside binary PNG images.

DIC postprocess Ncorr MAT extraction, EXX/EYY overlay generation, ROI summary statistics, optical reference-image enhancement, strain colorbar/level export, and PNG/CSV export are local details of `apps/dic/labkit_DICPostprocess_app.m`. The current overlay path extends valid strain values from the ROI before smoothing/resizing, then clips display back to the ROI/mask to avoid zero-filled edge leakage. The current ROI summary reports mean, standard deviation, median, minimum, and maximum for EXX and EYY.

Image curvature measurement point editing, scale-bar measurement, Kasa initialization, geometric circle fitting, curvature conversion, and result/overlay export are local details of `apps/image_measurement/labkit_CurvatureMeasurement_app.m`. The app replaces the old script-style point MAT handoff with the same reusable UI anchor-curve editor used by DIC ROI: double-click blank image space to add or insert anchors, drag anchors to move them, double-click anchors to delete them, then fit and export directly. Scale-bar measurement reuses the same anchor editor constrained to two endpoints, and the app uses a single large image preview instead of a separate residual plot. After fitting, the preview keeps the curve anchors visible, optionally shows the densified points used for fitting, and draws each anchor's radial residual distance to the fitted circle.

ECG print and SNR exploration lives in `apps/wearable/labkit_ECGPrint_app.m`. The app loads MAT timetable or delimited table recordings through `labkit.biosignal.readRecording`, lets the user choose a numeric channel and time ROI, runs generic filtering/peak detection/segmentation/template/SNR helpers, plots waveform peaks and SNR over time, accumulates per-segment SNR values into user-labeled classes, and exports segment or class-level CSV files plus a waveform PNG. The app intentionally replaces script-style file IO and plotting handoff with GUI controls and live previews.

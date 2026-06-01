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

The current wearable app bodies live under `apps/wearable/`. They use `labkit.ui.*` for the shared GUI shell and `labkit.biosignal.*` for GUI-free recording loading, channel extraction, time ROI, filtering, event/segment handling, and template-residual SNR measurements. Wearable apps own workflow wording, plot layout, import controls, and export choices.

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

Use the shared internal hook convention for app-local pure functions:

```matlab
appName("__labkit_test__", "commandName", arg1, arg2, ...)
[fig, debug] = appName("__labkit_debug__", opts)
```

Test handlers stay in the owning app file and expose only app-owned, GUI-free helpers unless a command explicitly exists to verify GUI state such as a load/layout diagnostic. Debug mode should launch the normal app, return the figure plus a debug log struct, and mirror each app-local `addLog` message to `debug.append`. These hooks are maintainer/test contracts, not user-facing app APIs.

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

Pure app calculations, export table construction, and plotting helpers belong in the app-family suites and run in the default GitHub Actions workflow when they do not require GUI graphics. Add `--gui` to the same suite when checking noninteractive launch/layout contracts:

```bash
scripts/run_matlab_tests.sh --suite apps/electrochem --gui
scripts/run_matlab_tests.sh --suite apps/dic --gui
scripts/run_matlab_tests.sh --suite apps/image_measurement --gui
scripts/run_matlab_tests.sh --suite apps/wearable --gui
```

Interactive GUI workflows, including manual file selection and visual inspection, are intentionally validated manually during app work.

## Current App Notes

Keep current app behavior summarized here instead of turning this document into a historical changelog. Use source tests for exact numeric schemas when possible.

| App | App-owned behavior | Export notes |
| --- | --- | --- |
| `labkit_ChronoOverlay_app` | Pulse-gap alignment, overlay plotting, and overlay export table construction. | Overlay CSV/plot exports stay app-local. |
| `labkit_EIS_app` | Axis-value generation, overlay plotting, and plot-export table construction. | Export table construction stays app-local. |
| `labkit_CSC_app` | CT/CV charge integration and comparison display. | No CSV export workflow currently. |
| `labkit_VTResistance_app` | Steady-window selection, baseline estimation, and resistance result tables. | VT CSV columns are guarded by app tests. |
| `labkit_CIC_app` | CIC, voltage-transient metrics, water-window status, and batch display tables. | CIC CSV columns are guarded by app tests. |
| `labkit_DICPreprocess_app` | Registration, repeated crop/align workflow, false-color preview, inline crop ROI, and binary ROI mask drawing. | Exports current image pair, crop PNGs, and white-inside/black-outside ROI masks. |
| `labkit_DICPostprocess_app` | Ncorr MAT extraction, EXX/EYY overlays, ROI summary, optical enhancement controls, and strain colorbar levels. | Exports overlays, summary CSV, and colorbar/level files. |
| `labkit_CurvatureMeasurement_app` | Image anchor editing, scale-bar measurement, circle fitting, curvature conversion, dense-point display, and residual annotations. | Exports overlay PNG and curvature CSV. |
| `labkit_ECGPrint_app` | CSV/MAT import parsing, channel/ROI selection, padded filtering before ROI crop, ECG peak detection, segments, template, and SNR-over-time plots. | Exports per-segment SNR CSV and waveform PNG. Multi-file/class statistics belong in a separate wearable stats app. |

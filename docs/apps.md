# Apps

LabKit apps are independent MATLAB GUI tools for concrete lab workflows. Each app should remain directly launchable and useful on its own. Shared UI, DTA, and biosignal helpers reduce boilerplate, but the scientific workflow belongs to the app that presents it.

## Startup

From MATLAB:

```matlab
startup_labkit
```

This adds the repository root, `apps/`, and nested app category folders to the MATLAB path.

## Current Apps

| App | Status | Purpose | Input | Typical output |
| --- | --- | --- | --- | --- |
| `labkit_CIC_app` | routine | CIC and voltage-transient metrics. | Chrono DTA | Results table and CSV. |
| `labkit_VTResistance_app` | routine | Steady resistance estimates from voltage transients. | Chrono DTA | Resistance table and CSV. |
| `labkit_CSC_app` | routine | CV/CT charge integration and CSC comparison. | CV/CT DTA | Plots and comparison values. |
| `labkit_EIS_app` | routine | EIS curve overlay and export. | EIS ZCURVE DTA | Plot and CSV. |
| `labkit_ChronoOverlay_app` | routine | Chrono voltage/current overlay. | Chrono DTA | Overlay plots and CSV. |
| `labkit_DICPreprocess_app` | active | Image registration, paired crop preparation, and ROI mask drawing. | Reference/current images | Aligned images, crop PNGs, ROI mask. |
| `labkit_DICPostprocess_app` | active | Ncorr strain overlay, ROI summary, and colorbar export. | Ncorr MAT, reference image, mask | EXX/EYY overlays, summary CSV, colorbar/level table. |
| `labkit_CurvatureMeasurement_app` | experimental | Editable image-curve circle fit for radius and curvature. | Image | Overlay PNG and curvature CSV. |
| `labkit_FocusStack_app` | experimental | Microscope focus-stack fusion into one all-in-focus image. | Focus image folder | Fused PNG, focus map PNG, summary CSV. |
| `labkit_ECGPrint_app` | experimental | ECG waveform preview, ROI filtering, peak/segment SNR, and SNR-over-time display. | MAT timetable or CSV/TSV table | Segment SNR CSV and waveform PNG. |

Status labels:

| Status | Meaning |
| --- | --- |
| `routine` | Current daily-use workflow with established behavior. |
| `active` | Current workflow still being refined through real use. |
| `experimental` | Newer utility or workflow under evaluation. |
| `archived` | Kept for reference, not part of normal use. |

## App Families

Electrochemistry apps live under `apps/electrochem/` and use the DTA facade for Gamry file discovery, loading, sessions, parsed curve access, and pulse detection.

DIC apps live under `apps/dic/`. They use the shared GUI shell while keeping registration, crop geometry, Ncorr MAT extraction, strain overlays, summaries, and exports in the owning app files.

Image measurement apps live under `apps/image_measurement/`. They are separate from DIC because their workflows are general image measurements or image-processing utilities rather than DIC preprocessing or strain postprocessing.

Wearable biosignal apps live under `apps/wearable/`. They use the biosignal facade for recording loading, channel extraction, time ROI, filtering, events, segments, templates, and measurements, while the app owns workflow wording, plot layout, import controls, and export choices.

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

## App File Shape

New lab apps should start as explicit public entry points under `apps/<category>/`. A typical file order is:

```text
1. Entry validation and optional internal test/debug hook
2. App state and GUI construction
3. Nested callbacks for file/session actions
4. Nested refresh/render/export callbacks that touch UI handles
5. End of the public app function
6. App-local domain functions
7. App-local table/export functions
8. App-local plotting annotation helpers
9. Small formatting, parsing, interpolation, and numeric utilities
```

Nested functions may read and update GUI handles or app state. Local functions after the app `end` should be GUI-free when practical so focused tests can exercise them through narrow internal app hooks.

The preferred public shape is one launchable app entry point per workflow. If an app becomes too large, app-owned private helpers are acceptable when they stay under the app family and do not become public reusable APIs.

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

Start from the closest existing app, reduce it to the needed workflow, and preserve ownership boundaries. Prefer `labkit.ui.createWorkbench` even for small apps so daily interaction stays consistent across app families.

## Validation

Pure app calculations, export table construction, and plotting helpers belong in the app-family suites and run in the default non-GUI workflow when they do not require graphics. Add `--gui` for noninteractive launch/layout checks:

```bash
scripts/run_matlab_tests.sh --suite apps/electrochem --gui
scripts/run_matlab_tests.sh --suite apps/dic --gui
scripts/run_matlab_tests.sh --suite apps/image_measurement --gui
scripts/run_matlab_tests.sh --suite apps/wearable --gui
```

Interactive file selection, drawing, visual inspection, and full workflow feel are validated manually in MATLAB app windows.

## Current App Notes

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
| `labkit_FocusStack_app` | Folder-based focus sequence loading, optional registration to the middle image, Laplacian-pyramid focus fusion, smoothed detail-level decision weights, and focus-depth preview. | Exports fused PNG, colorized focus map PNG, and per-source focus coverage CSV. |
| `labkit_ECGPrint_app` | CSV/MAT import parsing, channel/ROI selection, padded filtering before ROI crop, ECG peak detection, segments, template, and SNR-over-time plots. | Exports per-segment SNR CSV and waveform PNG. Multi-file/class statistics belong in a separate wearable stats app. |

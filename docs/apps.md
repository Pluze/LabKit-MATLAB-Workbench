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
| `labkit_CurvatureMeasurement_app` | experimental | Editable image-curve circle fit, calibrated real-unit scale-bar placement, and curve length measurement. | Image | Overlay PNG and curvature/length CSV. |
| `labkit_FocusStack_app` | experimental | Microscope focus-stack fusion into one all-in-focus image. | Focus image folder or selected image files | Fused PNG, focus map PNG, summary CSV. |
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

DIC apps live under `apps/dic/`. They use the shared GUI shell and interaction runtime while keeping registration, crop geometry, Ncorr MAT extraction, strain overlays, summaries, and exports in the owning app files.

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

Every public app entry point should preserve its launch name, route debug launch requests through `labkit.ui.app.dispatchRequest`, build the GUI with `labkit.ui.app.createShell`, and keep visible debug trace wired into the Log tab during debug launches. Image apps with drawing, scale bars, ROI, or preview scroll should pass a `labkit.ui.tool.createRuntime` result into reusable tools instead of owning figure pointer callbacks directly.

Move code into `+labkit` only when it is reusable without app vocabulary, testable independently, and useful beyond one workflow. When a documented UI tool owns app-neutral interaction mechanics, the app should consume that tool and keep workflow meaning, summaries, and exports app-local.

## App File Shape

New lab apps should start as explicit public entry points under `apps/<category>/` or `apps/<category>/<app_slug>/` when the app needs private helpers. A typical single-file order is:

```text
1. Entry validation and optional debug launch hook
2. App state and GUI construction
3. Nested callbacks for file/session actions
4. Nested refresh/render/export callbacks that touch UI handles
5. End of the public app function
6. App-local domain functions
7. App-local table/export functions
8. App-local plotting annotation helpers
9. Small formatting, parsing, interpolation, and numeric utilities
```

Nested functions may read and update GUI handles or app state. Local functions after the app `end` should be GUI-free when practical; extracted app-owned workflow helpers can give focused tests direct access without adding reusable `+labkit` APIs.

The preferred public shape is one launchable app entry point per workflow. If an app becomes too large, app-owned private helpers are acceptable when they stay under the owning app tree and do not become public reusable APIs. Move GUI-free calculations, export builders, deterministic image/signal transforms, and formatting utilities to `apps/<family>/<app_slug>/private/` when that makes the public app file easier to scan. Use `apps/<family>/private/` only for helpers that are genuinely shared by multiple apps in that family. Keep GUI state, callbacks, user alerts, workflow ordering, and debug launch routing in the public app file.

For callback-heavy migrated apps, the public launcher may delegate the app body to an app-private runner under the same app tree when that is the smallest behavior-preserving way to keep the launch contract clear. The runner remains app-owned production code; it is not a reusable facade and should not move app-specific workflow decisions into `+labkit`.

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
10. GUI shell spec, debug trace behavior, and file-selection mode
```

Start from the closest existing app, reduce it to the needed workflow, and preserve ownership boundaries. Prefer `labkit.ui.app.createShell` even for small apps so daily interaction stays consistent across app families.

## Validation

Pure app calculations, export table construction, and plotting helpers belong
in app-family build tasks. Use the GUI tasks for noninteractive launch/layout
checks:

```bash
buildtool testAppsElectrochem testAppsElectrochemGui
buildtool testAppsDicGui
buildtool testAppsImageMeasurement testAppsImageMeasurementGui
buildtool testAppsWearableGui
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
| `labkit_CurvatureMeasurement_app` | Curve-point workflow, circle fitting, curvature conversion, curve length measurement, dense-point display, residual annotations, result summaries, and CSV/overlay export schemas. It consumes reusable UI tools for generic anchor editing and scale-bar mechanics. | Exports overlay PNG and curvature/length CSV. |
| `labkit_FocusStack_app` | Folder or selected-file focus sequence loading, optional registration to the middle image, preset-guided Laplacian-pyramid focus fusion, user-facing detail/blend controls, and focus-depth preview. | Exports fused PNG, colorized focus map PNG, and per-source focus coverage CSV. |
| `labkit_ECGPrint_app` | CSV/MAT import parsing, channel/ROI selection, padded filtering before ROI crop, ECG peak detection, segments, template, and SNR-over-time plots. | Exports per-segment SNR CSV and waveform PNG. Multi-file/class statistics belong in a separate wearable stats app. |

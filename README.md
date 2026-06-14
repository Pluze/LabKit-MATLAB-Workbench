# LabKit MATLAB Workbench

[![Release](https://img.shields.io/github/v/release/Pluze/LabKit-MATLAB-Workbench?label=release)](https://github.com/Pluze/LabKit-MATLAB-Workbench/releases)
[![MATLAB Tests](https://github.com/Pluze/LabKit-MATLAB-Workbench/actions/workflows/matlab-tests.yml/badge.svg)](https://github.com/Pluze/LabKit-MATLAB-Workbench/actions/workflows/matlab-tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![MATLAB](https://img.shields.io/badge/MATLAB-apps-orange.svg)](https://www.mathworks.com/products/matlab.html)

Focused MATLAB GUI apps for lab workflows in electrochemistry, DIC, image
measurement, microscopy focus stacking, image enhancement, batch image
cropping, wearable biosignal review, and a starter template app for new
LabKit app development.

LabKit MATLAB Workbench is an app-first research workbench. Each workflow keeps
its own launch command, app-owned calculations, plots, summaries, and exports.
Shared code stays behind a small reusable foundation for GUI layout,
interaction tools, Gamry DTA parsing/session handling, and biosignal
processing.

## Highlights

| Capability | What it provides |
| --- | --- |
| App-first workflows | Independent MATLAB GUI apps for daily lab tasks instead of one monolithic analysis launcher. |
| Electrochemistry support | Gamry DTA loading, chrono overlays, CIC, CSC, VT resistance, EIS plotting, pulse handling, and CSV export paths. |
| Image and DIC workflows | DIC preprocessing/postprocessing, curve measurement, calibrated scale bars, focus-stack fusion, paper image enhancement, and batch microscope image crops. |
| Wearable biosignals | ECG/table import, filtering, peak detection, event segments, templates, and SNR-style measurement summaries. |
| Reusable foundation | Layered `labkit.ui`, GUI-free `labkit.dta`, and GUI-free `labkit.biosignal` facades. |
| Guarded behavior | MATLAB build tasks, synthetic fixtures, architecture guardrails, and GitHub Actions CI. |

## Quick Start

Open MATLAB at the repository root and launch the app selector:

```matlab
labkit_launcher
```

The selector initializes the workbench path, scans the current app entry points,
and opens the selected app. Apps remain directly launchable when a workflow has
a known command:

```matlab
% Electrochemistry
labkit_ChronoOverlay_app
labkit_CIC_app
labkit_VTResistance_app
labkit_CSC_app
labkit_EIS_app

% DIC image workflows
labkit_DICPreprocess_app
labkit_DICPostprocess_app

% Image measurement and microscopy utilities
labkit_CurvatureMeasurement_app
labkit_FocusStack_app
labkit_ImageEnhance_app
labkit_ImageMatch_app
labkit_BatchImageCrop_app

% Wearable biosignal review
labkit_ECGPrint_app

% App development template
labkit_TemplateApp_app
```

Use the app window to load files, inspect plots or measurements, tune workflow
options, and export outputs when the selected app provides an export action.

## App Catalog

| Command | Workflow | Inputs | Typical outputs |
| --- | --- | --- | --- |
| `labkit_ChronoOverlay_app` | Chrono voltage/current overlay | Chrono Gamry DTA files | Overlay plots and CSV tables |
| `labkit_CIC_app` | Charge injection capacity and voltage-transient metrics | Chrono Gamry DTA files | CIC result table and CSV |
| `labkit_VTResistance_app` | Steady resistance estimates from voltage transients | Chrono Gamry DTA files | Resistance table and CSV |
| `labkit_CSC_app` | CV/CT charge and CSC comparison | CV/CT Gamry DTA files | Plots and comparison values |
| `labkit_EIS_app` | EIS curve overlay and export | EIS ZCURVE Gamry DTA files | EIS plots and CSV export |
| `labkit_DICPreprocess_app` | Registration, paired crop preparation, and ROI mask drawing | Reference/current image pairs | Aligned images, crop PNGs, ROI masks |
| `labkit_DICPostprocess_app` | Ncorr strain overlays, ROI summary, and colorbar export | Ncorr MAT, reference image, ROI mask | EXX/EYY overlays, summary CSV, colorbar files |
| `labkit_CurvatureMeasurement_app` | Editable curve tracing, calibrated scale, length, and circle-fit curvature | Image files | Overlay PNG and curvature/length CSV |
| `labkit_FocusStack_app` | Microscope focus-stack fusion into an all-in-focus image | Focus image folder or selected image files | Fused PNG, focus map PNG, summary CSV |
| `labkit_ImageEnhance_app` | Stepwise brightness, contrast, clarity, color, and white-balance enhancement for figures | Image files | Enhanced images and processing manifest CSV |
| `labkit_ImageMatch_app` | Reference-based white-balance, tone, and color-style matching for figure images | Image files | Matched images and processing manifest CSV |
| `labkit_BatchImageCrop_app` | Fixed-size batch microscope crops with per-image center and rotation | Microscope image files | Cropped images and crop manifest CSV |
| `labkit_ECGPrint_app` | ECG waveform preview, filtering, peak/segment SNR, and SNR-over-time display | MAT timetable, CSV, or TSV recordings | Segment SNR CSV and waveform PNG |
| `labkit_TemplateApp_app` | Starter canvas showing the current UI 2.0 app structure | Synthetic placeholder state | Example controls, preview, summary, and log |

## Reusable Foundation

The reusable library is intentionally small and app-facing:

| Facade | Scope |
| --- | --- |
| `labkit.ui.app` | Declarative app creation, request dispatch, and busy-state feedback. |
| `labkit.ui.spec` | Data-only UI 2.0 workbench specs for tabs, sections, fields, actions, paths, previews, results, logs, and status panels. |
| `labkit.ui.view` | Semantic registry updates, list state, logs, preview image drawing, axes reset, and axes clearing. |
| `labkit.ui.tool` | Interaction runtime, anchor editing, scale-bar placement, and calibration helpers. |
| `labkit.ui.diag` | Debug context, trace logging, callback instrumentation, and visible log mirroring. |
| `labkit.dta` | Gamry DTA file discovery, type detection, loading, sessions, parsed curves, and pulse helpers. |
| `labkit.biosignal` | Recording import, channel extraction, filtering, ECG peaks, event segments, templates, and measurements. |

Workflow-specific formulas, thresholds, result schemas, plots, and exports stay
under the owning app in `apps/`.

## Validation

Run the default non-GUI MATLAB build task:

```bash
buildtool test
```

If MATLAB is not on `PATH`, use the thin MATLAB locator:

```bash
scripts/matlab_batch.sh "buildtool test"
```

Additional build tasks cover project guardrails, broad reusable-library checks,
broad app-owned checks, GUI structural checks, gesture checks, coverage,
optional local MATLAB Project checks, and package dry runs. Use the
`runLabKitTests` suite and tag selectors documented in `docs/testing.md` for
component or app-family iteration.

## Repository Layout

```text
+labkit/                Reusable UI, DTA, and biosignal facades
apps/                   App entry points and app-specific workflow code
apps/electrochem/       Electrochemistry apps
apps/dic/               DIC image workflow apps
apps/image_measurement/ General image measurement and microscopy apps
apps/wearable/          Wearable biosignal apps
apps/templates/         Starter app template for new LabKit apps
tests/                  MATLAB tests, GUI structural checks, and fixtures
scripts/                MATLAB locator, project setup, and reporting helpers
docs/                   Human-readable architecture, API, app, and testing docs
```

## Optional MATLAB Project

The repository does not track MATLAB Project metadata. Users who want MATLAB
Project features such as dependency analysis and Project Issues can create a
local project file:

```matlab
run("scripts/create_local_matlab_project.m")
```

The generated `LabKit.prj` and `resources/project/` files are local IDE state
and are ignored by git. The workbench remains runnable through
`labkit_launcher` without opening a MATLAB Project.

## Documentation

- `docs/README.md`: documentation map.
- `docs/apps.md`: app entry points, app purposes, and workflow ownership.
- `docs/ui.md`: reusable GUI shell, view, tool, and diagnostics contracts.
- `docs/dta.md`: Gamry DTA facade, item/session shapes, and pulse behavior.
- `docs/biosignal.md`: biosignal facade and ECG workflow boundary.
- `docs/architecture.md`: package boundaries and reusable-library extraction rules.
- `docs/testing.md`: validation matrix, CI scope, fixtures, and GUI validation limits.

## Release

Version `v1.0` is the first stable baseline after the app-owned package
migration and reusable LabKit UI API cleanup.

## License

This project is open source under the MIT License. See `LICENSE`.

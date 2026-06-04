# LabKit MATLAB Workbench

[![MATLAB Tests](https://github.com/Pluze/LabKit-MATLAB-Workbench/actions/workflows/matlab-tests.yml/badge.svg)](https://github.com/Pluze/LabKit-MATLAB-Workbench/actions/workflows/matlab-tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![MATLAB](https://img.shields.io/badge/MATLAB-apps-orange.svg)](https://www.mathworks.com/products/matlab.html)

MATLAB GUI workbench for lab workflows in electrochemistry, wearable biosignals, DIC, and image measurement.

LabKit MATLAB Workbench is an internal app workbench for scientific GUI tools. It gives each experiment workflow its own focused MATLAB app while sharing a small reusable foundation for layout, loading, parsing, signal processing, and testable infrastructure.

Current app families cover electrochemistry, DIC image workflows, image measurement, and wearable biosignal review. Reusable code is organized behind three app-facing facades:

- `labkit.ui.*`: shared GUI shells, panels, controls, axes, logs, and image/plot helpers.
- `labkit.dta.*`: GUI-free Gamry DTA loading, sessions, parsed curve access, and pulse helpers.
- `labkit.biosignal.*`: GUI-free recording loading, filtering, ECG peak detection, segments, templates, and SNR-style measurements.

Workflow-specific calculations, plot choices, summaries, and exports stay in the owning app under `apps/`.

## At A Glance

| Area | Current scope |
| --- | --- |
| Electrochemistry | Gamry DTA review, chrono overlays, CIC, CSC, VT resistance, and EIS export workflows |
| DIC | Image registration, paired crop preparation, ROI masks, Ncorr strain overlays, and summary export |
| Image measurement | Interactive curve tracing, calibrated scale/length measurement, curvature/radius measurement, and microscope focus stacking |
| Wearable biosignals | ECG preview, filtering, peak detection, segments, templates, and SNR-style measurements |
| Reusable foundation | MATLAB UI helpers plus DTA and biosignal facades for app-facing workflows |
| Validation | Focused MATLAB suites, architecture guardrails, synthetic fixtures, and GitHub Actions CI |

## Quick Start

From the repository root in MATLAB:

```matlab
startup_labkit

% Electrochemistry
labkit_ChronoOverlay_app
labkit_CIC_app
labkit_VTResistance_app
labkit_CSC_app
labkit_EIS_app

% DIC
labkit_DICPreprocess_app
labkit_DICPostprocess_app

% Image measurement
labkit_CurvatureMeasurement_app
labkit_FocusStack_app

% Wearable biosignal
labkit_ECGPrint_app
```

Then use the app window to load files, inspect plots or results, and export outputs when the app provides an export action.

## Apps

| Command | Status | Purpose | Input | Typical output |
| --- | --- | --- | --- | --- |
| `labkit_CIC_app` | routine | Charge injection capacity and voltage-transient metrics | Chrono DTA | Results table and CSV |
| `labkit_VTResistance_app` | routine | Steady resistance estimates from voltage transients | Chrono DTA | Resistance table and CSV |
| `labkit_CSC_app` | routine | CV/CT charge and CSC comparison | CV/CT DTA | Plots and comparison values |
| `labkit_EIS_app` | routine | EIS curve overlay and export | EIS ZCURVE DTA | Plot and CSV |
| `labkit_ChronoOverlay_app` | routine | Chrono voltage/current overlay | Chrono DTA | Overlay plots and CSV |
| `labkit_DICPreprocess_app` | active | Image registration, paired crop preparation, and ROI mask drawing | Reference/current images | Aligned images, crop PNGs, ROI mask |
| `labkit_DICPostprocess_app` | active | Ncorr strain overlay, ROI summary, and colorbar export | Ncorr MAT, reference image, mask | EXX/EYY overlays, summary CSV, colorbar/level table |
| `labkit_CurvatureMeasurement_app` | experimental | Editable image-curve circle fit, calibrated real-unit scale-bar placement, and curve length measurement | Image | Overlay PNG and curvature/length CSV |
| `labkit_FocusStack_app` | experimental | Microscope focus-stack fusion into one all-in-focus image | Focus image folder or selected image files | Fused PNG, focus map PNG, summary CSV |
| `labkit_ECGPrint_app` | experimental | ECG waveform preview, ROI filtering, peak/segment SNR, and SNR-over-time display | MAT timetable or CSV/TSV table | Segment SNR CSV and waveform PNG |

Status labels:

| Status | Meaning |
| --- | --- |
| `routine` | Current daily-use workflow with established behavior. |
| `active` | Current workflow still being refined through real use. |
| `experimental` | Newer utility or workflow under evaluation. |

## Tests

Run the default non-GUI MATLAB suite:

```bash
scripts/run_matlab_tests.sh
```

On Windows PowerShell:

```powershell
.\scripts\run_matlab_tests.ps1
```

Focused checks are available during development:

```bash
scripts/run_matlab_tests.sh --suite labkit/dta
scripts/run_matlab_tests.sh --suite labkit/biosignal
scripts/run_matlab_tests.sh --suite apps/wearable --gui
scripts/run_matlab_tests.sh --suite labkit/ui --suite apps --gui
```

The Windows script accepts the same `--suite`, `--test`, and `--gui` options. GitHub Actions runs the default non-GUI suite on pushes and pull requests to `main`.

## Repository Layout

```text
+labkit/                Reusable UI, DTA, and biosignal facades
apps/                   App entry points and app-specific workflow code
apps/electrochem/       Electrochemistry apps
apps/dic/               DIC image workflow apps
apps/image_measurement/ General image measurement apps
apps/wearable/          Wearable biosignal apps
tests/                  MATLAB tests and fixtures
scripts/                Test runner scripts
docs/                   Human-readable architecture, API, app, and testing docs
```

## More Documentation

- `docs/README.md`: documentation map.
- `docs/apps.md`: app entry points, app purposes, and app ownership guidance.
- `docs/ui.md`: reusable GUI shell and helper contracts.
- `docs/dta.md`: Gamry DTA facade and data shapes.
- `docs/biosignal.md`: biosignal facade and ECG workflow boundary.
- `docs/architecture.md`: package boundaries and extraction rules.
- `docs/testing.md`: validation and CI guidance.

## License

This project is open source under the MIT License. See `LICENSE`.

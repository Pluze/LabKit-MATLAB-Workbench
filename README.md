# LabKit MATLAB Workbench

[![MATLAB Tests](https://github.com/Pluze/LabKit-MATLAB-Workbench/actions/workflows/matlab-tests.yml/badge.svg)](https://github.com/Pluze/LabKit-MATLAB-Workbench/actions/workflows/matlab-tests.yml)

LabKit MATLAB Workbench is an internal MATLAB app workbench for lab GUI tools. It provides a shared GUI foundation so independent scientific workflow apps can use the same left-control/right-output structure without becoming one monolithic analysis program.

The repository currently includes electrochemistry, DIC image, image-measurement, and wearable biosignal apps. Reusable code lives behind three app-facing facades:

- `labkit.ui.*`: shared GUI workbench shells, panels, controls, axes, logs, and image/plot helpers.
- `labkit.dta.*`: GUI-free Gamry DTA loading, sessions, parsed curve access, and pulse helpers.
- `labkit.biosignal.*`: GUI-free wearable/physiological recording loading, filtering, ECG peak detection, segments, templates, and SNR-style measurements.

Workflow-specific calculations, plot choices, summaries, and exports stay in the owning app under `apps/`.

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

% Wearable biosignal
labkit_ECGPrint_app
```

Then use the app window to load files, inspect plots/results, and export when the app provides an export action.

## Apps

| Command | Status | Purpose | Input | Typical output |
| --- | --- | --- | --- | --- |
| `labkit_CIC_app` | routine | Charge injection capacity / voltage-transient metrics | Chrono DTA | Results table and CSV |
| `labkit_VTResistance_app` | routine | Steady resistance estimates from voltage transients | Chrono DTA | Resistance table and CSV |
| `labkit_CSC_app` | routine | CV/CT charge and CSC comparison | CV/CT DTA | Plots and comparison values |
| `labkit_EIS_app` | routine | EIS curve overlay and export | EIS ZCURVE DTA | Plot and CSV |
| `labkit_ChronoOverlay_app` | routine | Chrono voltage/current overlay | Chrono DTA | Overlay plots and CSV |
| `labkit_DICPreprocess_app` | active | Image registration, paired crop preparation, and ROI mask drawing | Reference/current images | Aligned images, crop PNGs, ROI mask |
| `labkit_DICPostprocess_app` | active | Ncorr strain overlay, ROI summary, and colorbar export | Ncorr MAT, reference image, mask | EXX/EYY overlays, summary CSV, colorbar/level table |
| `labkit_CurvatureMeasurement_app` | experimental | Editable image-curve circle fit for radius and curvature | Image | Overlay PNG and curvature CSV |
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

Focused checks are available during development:

```bash
scripts/run_matlab_tests.sh --suite labkit/dta
scripts/run_matlab_tests.sh --suite labkit/biosignal
scripts/run_matlab_tests.sh --suite apps/wearable --gui
scripts/run_matlab_tests.sh --suite labkit/ui --suite apps --gui
```

GitHub Actions runs the default non-GUI suite on pushes and pull requests to `main`. Public repositories can use MathWorks automatic licensing for supported MATLAB Actions; private repositories need a GitHub secret named `MLM_LICENSE_TOKEN`.

## Repository Layout

```text
+labkit/               Reusable UI, DTA, and biosignal facades
apps/                  App entry points and app-specific workflow code
apps/electrochem/      Electrochemistry apps
apps/dic/              DIC image workflow apps
apps/image_measurement/ General image measurement apps
apps/wearable/         Wearable biosignal apps
tests/                 MATLAB tests and fixtures
scripts/               Test runner scripts
docs/                  Architecture, UI, DTA, biosignal, app, and testing docs
```

## More Documentation

- `docs/README.md`: documentation map.
- `docs/apps.md`: app entry points and app-owned workflow guidance.
- `docs/ui.md`: reusable GUI shell and helper contracts.
- `docs/dta.md`: Gamry DTA facade and data shapes.
- `docs/biosignal.md`: biosignal facade and ECG workflow boundary.
- `docs/architecture.md`: package boundaries and extraction rules.
- `docs/testing.md`: validation and CI guidance.
- `AGENTS.md`: agent and maintainer operating rules.

## License

This project is open source under the MIT License. See `LICENSE`.

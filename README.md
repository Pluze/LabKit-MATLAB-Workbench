# LabKit MATLAB Workbench

[![MATLAB Tests](https://github.com/Pluze/LabKit-MATLAB-Workbench/actions/workflows/matlab-tests.yml/badge.svg)](https://github.com/Pluze/LabKit-MATLAB-Workbench/actions/workflows/matlab-tests.yml)

LabKit MATLAB Workbench is an internal MATLAB lab app workbench for daily research utilities. It is intended to make small MATLAB GUI apps easier to build, maintain, and keep consistent across different workflows without turning the repository into a monolithic analysis platform.

The core idea is a shared app shell: configurable tabs and controls on the left, live plots or primary outputs on the right, and app-specific behavior kept in the owning app file. Small utilities and larger tools start from the same GUI structure instead of each rebuilding its own MATLAB interface.

The current app implementations include Gamry electrochemistry workflows, DIC image workflows, image measurement tools, and an experimental wearable biosignal workflow built on this GUI foundation. Electrochemistry support uses the reusable DTA facade; wearable signal support uses the reusable biosignal facade. DIC registration, crop, Ncorr strain extraction, overlays, summaries, and exports stay in the DIC app files. Image measurement apps are separate from DIC and keep measurement-specific logic app-local.

## Project Philosophy

- Apps are independent workflow components for specific experimental needs.
- Apps may evolve quickly as lab workflows change.
- The reusable `labkit` library should remain small, stable, and organized around clear app-facing facades.
- Shared code is extracted only after repeated real app use proves the pattern.
- App-specific analysis, result fields, plot labels, export schemas, callbacks, alerts, and logs stay in the owning app.

## What It Provides

- A reusable MATLAB GUI workbench structure for lab tools.
- Shared UI building blocks for tabs, control panels, file panels, logs, plots, and result tables.
- A pattern where each app owns its domain logic, plotting choices, and exports.
- Current app implementations for Gamry electrochemistry workflows, DIC image workflows, image measurement tools, and exploratory wearable biosignal workflows.

App status is intentionally lightweight:

| Status | Meaning |
| --- | --- |
| `routine` | Current daily-use workflow with established behavior. |
| `active` | Current workflow still being refined through real use. |
| `experimental` | Newer utility or workflow under evaluation. |
| `archived` | Kept for reference, not part of normal use. |

## Current Electrochemistry Apps

| Command | Status | Use | Input | Typical output |
| --- | --- | --- | --- | --- |
| `labkit_CIC_app` | routine | Charge injection capacity / voltage-transient metrics | Chrono DTA | Results table and CSV |
| `labkit_VTResistance_app` | routine | Steady resistance estimates from voltage transients | Chrono DTA | Resistance table and CSV |
| `labkit_CSC_app` | routine | CV/CT charge and CSC comparison | CV/CT DTA | Plots and comparison values |
| `labkit_EIS_app` | routine | EIS curve overlay and export | EIS ZCURVE DTA | Plot and CSV |
| `labkit_ChronoOverlay_app` | routine | Chrono voltage/current overlay | Chrono DTA | Overlay plots and CSV |

## Current DIC Apps

| Command | Status | Use | Input | Typical output |
| --- | --- | --- | --- | --- |
| `labkit_DICPreprocess_app` | active | Image registration, paired crop preparation, and ROI mask drawing | Reference/current images | Aligned image, crop PNGs, and binary ROI mask |
| `labkit_DICPostprocess_app` | active | Ncorr strain overlay, ROI summary, and colorbar export | Ncorr MAT, reference image, mask | EXX/EYY overlays, summary CSV, and colorbar/level table |

## Current Image Measurement Apps

| Command | Status | Use | Input | Typical output |
| --- | --- | --- | --- | --- |
| `labkit_CurvatureMeasurement_app` | experimental | Editable curve-point circle fit for radius and curvature measurement | Image | Overlay PNG and curvature CSV |

## Current Wearable Biosignal Apps

| Command | Status | Use | Input | Typical output |
| --- | --- | --- | --- | --- |
| `labkit_ECGPrint_app` | experimental | ECG waveform preview, time ROI, peak/segment SNR analysis, SNR-over-time display, and class comparison | MAT timetable or CSV/TSV table | Segment SNR CSV, class summary/pairwise CSV, waveform PNG |

## Quick Start

From the repository root in MATLAB:

```matlab
startup_labkit

% App entry points
labkit_ChronoOverlay_app
labkit_CIC_app
labkit_VTResistance_app
labkit_CSC_app
labkit_EIS_app

% DIC app entry points
labkit_DICPreprocess_app
labkit_DICPostprocess_app

% Image measurement app entry points
labkit_CurvatureMeasurement_app

% Wearable biosignal app entry points
labkit_ECGPrint_app
```

Then use the app window to load the relevant files, review the plots/results, and export when the app supports export.

## Development Notes

The repository currently has three reusable MATLAB surfaces:

- `labkit.ui.*` for shared GUI structure and rendering helpers.
- `labkit.dta.*` for the current electrochemistry/Gamry DTA file support.
- `labkit.biosignal.*` for GUI-free biosignal recording loading, waveform processing, event/segment handling, SNR-style segment measurements, and group comparison.

Domain-specific logic, plot definitions, result fields, and export schemas live in the app files under `apps/`. Adding more independent apps is expected; adding new public library API should be conservative.

Automated tests can be run from a macOS shell:

```bash
scripts/run_matlab_tests.sh
```

GitHub Actions runs the default non-GUI MATLAB suite on pushes and pull requests to `main`. Private repositories need a GitHub secret named `MLM_LICENSE_TOKEN` for MATLAB licensing; public repositories can use MathWorks automatic licensing for supported MATLAB Actions.

Focused checks can run a single suite or test:

```bash
scripts/run_matlab_tests.sh --profile ui
scripts/run_matlab_tests.sh --profile dic
scripts/run_matlab_tests.sh --profile image_measurement
scripts/run_matlab_tests.sh --profile wearable
scripts/run_matlab_tests.sh --profile biosignal
scripts/run_matlab_tests.sh --profile electrochem
scripts/run_matlab_tests.sh --suite core
scripts/run_matlab_tests.sh --test test_gui_layout_controls
```

Profiles are the preferred path during iteration because they avoid running unrelated app families. Interactive GUI workflows are checked manually during app work.

## Repository Layout

```text
+labkit/             App-facing GUI and current DTA APIs
apps/                 App entry points and app-specific implementations
apps/electrochem/     Current electrochemistry app entry points
apps/dic/             Current DIC image workflow app entry points
apps/image_measurement/ Current image measurement app entry points
apps/wearable/         Current wearable biosignal app entry points
tests/                MATLAB tests
tests/fixtures/dta/   Named DTA test fixtures
scripts/              Test runner scripts
docs/                 UI, DTA, app, architecture, and testing docs
```

## More Documentation

- `docs/README.md`: documentation map.
- `docs/architecture.md`: current architecture and boundaries.
- `docs/ui.md`: reusable GUI shell, layout contract, and UI helpers.
- `docs/dta.md`: current Gamry DTA API, parser assumptions, and DTA structs.
- `docs/biosignal.md`: current biosignal facade and ECG print app boundary.
- `docs/apps.md`: app entry points, app-owned workflow rules, and current app-specific notes.
- `docs/testing.md`: automated validation guidance.
- `CHANGELOG.md`: release-style change history.
- `AGENTS.md`: agent and maintainer operating rules.

## License

This project is open source under the MIT License. See `LICENSE`.

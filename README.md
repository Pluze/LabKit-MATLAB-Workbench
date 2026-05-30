# LabKit MATLAB Workbench

LabKit MATLAB Workbench is a reusable MATLAB GUI foundation for lab-internal software tools. It is intended to make small MATLAB GUI apps easier to build, maintain, and keep consistent across different workflows.

The core idea is a shared app shell: configurable tabs and controls on the left, live plots or primary outputs on the right, and app-specific behavior kept in the owning app file. Small utilities and larger tools start from the same GUI structure instead of each rebuilding its own MATLAB interface.

The current app implementations include Gamry electrochemistry workflows and DIC image workflows built on this GUI foundation. Electrochemistry support uses the reusable DTA facade; DIC registration, crop, Ncorr strain extraction, overlays, summaries, and exports stay in the DIC app files.

## What It Provides

- A reusable MATLAB GUI workbench structure for lab tools.
- Shared UI building blocks for tabs, control panels, file panels, logs, plots, and result tables.
- A pattern where each app owns its domain logic, plotting choices, and exports.
- Current app implementations for Gamry electrochemistry workflows and DIC image workflows.

## Current Electrochemistry Apps

| Command | Use | Input | Typical output |
| --- | --- | --- | --- |
| `labkit_CIC_app` | Charge injection capacity / voltage-transient metrics | Chrono DTA | Results table and CSV |
| `labkit_VTResistance_app` | Steady resistance estimates from voltage transients | Chrono DTA | Resistance table and CSV |
| `labkit_CSC_app` | CV/CT charge and CSC comparison | CV/CT DTA | Plots and comparison values |
| `labkit_EIS_app` | EIS curve overlay and export | EIS ZCURVE DTA | Plot and CSV |
| `labkit_ChronoOverlay_app` | Chrono voltage/current overlay | Chrono DTA | Overlay plots and CSV |

## Current DIC Apps

| Command | Use | Input | Typical output |
| --- | --- | --- | --- |
| `labkit_DICPreprocess_app` | Image registration, paired crop preparation, and ROI mask drawing | Reference/current images | Aligned image, crop PNGs, and binary ROI mask |
| `labkit_DICPostprocess_app` | Ncorr strain overlay, ROI summary, and colorbar export | Ncorr MAT, reference image, mask | EXX/EYY overlays, summary CSV, and colorbar/level table |

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
```

Then use the app window to load the relevant files, review the plots/results, and export when the app supports export.

## Development Notes

The repository currently has two reusable MATLAB surfaces:

- `labkit.ui.*` for shared GUI structure and rendering helpers.
- `labkit.dta.*` for the current electrochemistry/Gamry DTA file support.

Domain-specific logic, plot definitions, result fields, and export schemas live in the app files under `apps/`.

Automated tests can be run from a macOS shell:

```bash
scripts/run_matlab_tests.sh
```

Focused checks can run a single suite or test:

```bash
scripts/run_matlab_tests.sh --profile ui
scripts/run_matlab_tests.sh --profile dic
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
- `docs/apps.md`: app entry points, app-owned workflow rules, and current app-specific notes.
- `docs/testing.md`: automated validation guidance.
- `CHANGELOG.md`: release-style change history.
- `AGENTS.md`: agent and maintainer operating rules.

# LabKit Electrochemistry Workbench

LabKit Electrochemistry Workbench is a MATLAB workspace for analyzing Gamry electrochemistry DTA data with small, task-focused GUI apps.

The current app set covers chrono, CV/CT, and EIS workflows for charge, resistance, capacitance, impedance, and overlay analysis. Each app provides a consistent left-side control area and right-side live plot area while keeping the scientific calculations visible in the app source.

## What It Provides

- GUI apps for common electrochemistry analysis tasks.
- Gamry DTA loading, session handling, pulse detection, and parsed table/curve access.
- Reusable MATLAB UI infrastructure for tabbed controls, file panels, logs, plots, and result tables.
- App-local scientific calculations and exports so experiment-specific behavior stays easy to inspect.

## Apps

| Command | Use | Input | Typical output |
| --- | --- | --- | --- |
| `labkit_CIC_app` | Charge injection capacity / voltage-transient metrics | Chrono DTA | Results table and CSV |
| `labkit_VTResistance_app` | Steady resistance estimates from voltage transients | Chrono DTA | Resistance table and CSV |
| `labkit_CSC_app` | CV/CT charge and CSC comparison | CV/CT DTA | Plots and comparison values |
| `labkit_EIS_app` | EIS curve overlay and export | EIS ZCURVE DTA | Plot and CSV |
| `labkit_ChronoOverlay_app` | Chrono voltage/current overlay | Chrono DTA | Overlay plots and CSV |

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
```

Then use the app window to add DTA files, review the plots/results, and export when the app supports export.

## Development Notes

The repository is organized around two reusable MATLAB surfaces:

- `labkit.ui.*` for shared GUI structure and rendering helpers.
- `labkit.dta.*` for DTA file discovery, loading, sessions, pulse detection, and parsed table/curve access.

Experiment-specific calculations, plots, result fields, and export schemas live in the app files under `apps/`.

Automated tests can be run from a macOS shell:

```bash
scripts/run_matlab_tests.sh
```

Interactive GUI workflows are checked manually during app work.

## Repository Layout

```text
+labkit/             App-facing GUI and DTA APIs
apps/                 App entry points and app-specific implementations
apps/electrochem/     Current electrochemistry app entry points
templates/            Copy-only GUI, DTA, and GUI+DTA starter programs
demo/                 Named DTA fixtures
tests/                MATLAB tests
scripts/              Test runner scripts
docs/                 Architecture, API, data model, parser, and validation docs
```

## More Documentation

- `docs/architecture.md`: current architecture and boundaries.
- `docs/api_usage.md`: reusable API examples, app layout, and new-app checklist.
- `docs/data_model.md`: current item/result/session schemas.
- `docs/file_format_notes.md`: DTA parser assumptions.
- `docs/validation_protocol.md`: automated validation guidance.
- `CHANGELOG.md`: release-style change history.
- `AGENTS.md`: agent and maintainer operating rules.

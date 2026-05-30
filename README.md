# LabKit Electrochemistry Workbench

MATLAB tools for electrochemistry workflows. Current apps process Gamry DTA files, live under `apps/`, and compose reusable infrastructure under `labkit.ui.*` and `labkit.dta.*`.

## Current Design

The current architecture is the intended direction:

- Scientific analysis, plotting choices, result tables, and exports live in the owning app file.
- `labkit.ui.*` provides reusable GUI structure: a standard resizable workbench shell, tabs, file/log panels, plot helpers, and generic controls.
- `labkit.dta.*` provides electrochemistry file-processing utilities: DTA discovery, loading, sessions, pulse detection, and parsed table/curve access.
- Parser internals, session construction, and pulse implementation details stay private behind the DTA facade.

## Apps

| App | Purpose | Input | Output |
| --- | --- | --- | --- |
| `labkit_CIC_app` | CIC / voltage-transient metrics | Chrono DTA | Results table and CSV |
| `labkit_VTResistance_app` | Steady resistance estimate | Chrono DTA | Resistance table and CSV |
| `labkit_CSC_app` | CV/CT charge and CSC comparison | CV/CT DTA | Plots and comparison fields |
| `labkit_EIS_app` | EIS overlay and export | EIS ZCURVE DTA | Plot and CSV |
| `labkit_ChronoOverlay_app` | Chrono voltage/current overlay | Chrono DTA | Overlay plots and CSV |

## Getting Started

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

## Running Tests

From a macOS shell:

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

## Documentation

- `AGENTS.md`: agent and developer operating rules.
- `CHANGELOG.md`: release-style change history.
- `docs/architecture.md`: current architecture and boundaries.
- `docs/api_usage.md`: reusable API usage, app layout, and new-app checklist.
- `docs/data_model.md`: current item/result/session schemas.
- `docs/file_format_notes.md`: DTA parser assumptions.
- `docs/validation_protocol.md`: behavior-preservation validation.

## API Boundary

For new app work, use `labkit.ui.*` for reusable GUI structure and `labkit.dta.*` for DTA discovery, loading, session, pulse, and parsed table/curve access. Parser IO, item construction, and session implementation helpers are DTA-private details, not app-facing APIs.

## Preservation Rule

Do not change scientific formulas, parser behavior, pulse detection behavior, GUI behavior, plot labels, or CSV/export formats during repository hygiene work.

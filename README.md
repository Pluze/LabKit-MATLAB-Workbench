# LabKit MATLAB Workbench

LabKit MATLAB Workbench is a reusable MATLAB GUI foundation for lab-internal software tools. It is intended to make small MATLAB GUI apps easier to build, maintain, and keep consistent across different workflows.

The core idea is a shared app shell: configurable tabs and controls on the left, live plots or primary outputs on the right, and app-specific behavior kept in the owning app file. Small utilities and larger tools start from the same GUI structure instead of each rebuilding its own MATLAB interface.

The current implementation includes an electrochemistry application set built on this GUI foundation. Those apps add Gamry DTA file handling and cover chrono, CV/CT, and EIS workflows for charge, resistance, capacitance, impedance, and overlay analysis.

## What It Provides

- A reusable MATLAB GUI workbench structure for lab tools.
- Shared UI building blocks for tabs, control panels, file panels, logs, plots, and result tables.
- A pattern where each app owns its domain logic, plotting choices, and exports.
- A current electrochemistry implementation with Gamry DTA loading, sessions, pulse detection, and parsed table/curve access.

## Current Electrochemistry Apps

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

The repository currently has two reusable MATLAB surfaces:

- `labkit.ui.*` for shared GUI structure and rendering helpers.
- `labkit.dta.*` for the current electrochemistry/Gamry DTA file support.

Domain-specific logic, plot definitions, result fields, and export schemas live in the app files under `apps/`.

Automated tests can be run from a macOS shell:

```bash
scripts/run_matlab_tests.sh
```

Interactive GUI workflows are checked manually during app work.

## Repository Layout

```text
+labkit/             App-facing GUI and current DTA APIs
apps/                 App entry points and app-specific implementations
apps/electrochem/     Current electrochemistry app entry points
templates/            Copy-only GUI, DTA, and GUI+DTA starter programs
demo/                 Named DTA fixtures
tests/                MATLAB tests
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

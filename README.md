# Gamry Electrochemistry Workbench

MATLAB tools for analyzing Gamry electrochemistry DTA files. The project preserves the original analysis workflows through app entry points under `apps/` and reusable `+gamrywb` APIs for Gamry/DTA loading plus scientific-app GUI scaffolding.

## Current Status

The v1.0 behavior-preserving package refactor is complete.

What that means:

- Current runtime entry points live under `apps/`.
- The old root-level GUI command wrappers and `legacy/` reference directory have been removed.
- EIS, Chrono overlay, CSC, VT resistance, and CIC are public single-file app implementations.
- Experiment-specific analysis, plots, result tables, and exports belong to the owning app file.
- Reusable `+gamrywb` code is limited to GUI base helpers, Gamry/DTA loading/data APIs, and small utilities.

Deferred beyond v1.0:

- Unified workbench GUI.
- Stored golden MAT references for every major analysis output.

## Getting Started

From the repository root in MATLAB:

```matlab
startup_gamrywb

% App entry points
gamrywb_ChronoOverlay_app
gamrywb_CIC_app
gamrywb_VTResistance_app
gamrywb_CSC_app
gamrywb_EIS_app
```

The old root-level GUI command names are no longer runtime entry points.

## Running Tests

From a macOS shell:

```bash
scripts/run_matlab_tests.sh
```

Optional noninteractive GUI compatibility checks:

```bash
scripts/run_matlab_tests.sh --gui
```

The default runner covers pure functions. The optional GUI mode checks launch/layout/callback compatibility without file dialogs, exports, or manual interaction.

## Repository Layout

```text
+gamrywb/             Reusable GUI, Gamry/DTA, and utility APIs
apps/                 App entry points and app-specific implementations
templates/            Copy-only GUI, DTA, and GUI+DTA starter programs
demo/                 Named DTA fixtures
tests/                MATLAB tests
scripts/              Test runner scripts
docs/                 Architecture, data model, parser, validation, and history docs
```

## Documentation

- `AGENTS.md`: agent and developer operating rules.
- `CHANGELOG.md`: release-style change history.
- `docs/architecture.md`: current architecture and boundaries.
- `docs/api_usage.md`: reusable API usage, single-file app template, and new-app checklist.
- `docs/data_model.md`: current item/result/session schemas.
- `docs/file_format_notes.md`: DTA parser assumptions.
- `docs/validation_protocol.md`: behavior-preservation validation.
- `docs/refactor_history.md`: concise archived migration history.

## Preservation Rule

Do not change scientific formulas, parser behavior, pulse detection behavior, GUI behavior, plot labels, or CSV/export formats during repository hygiene work.

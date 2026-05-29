# Gamry Electrochemistry Workbench

MATLAB tools for analyzing Gamry electrochemistry DTA files. The project preserves the original research GUIs while providing a reusable `+gamrywb` package for parsers, data helpers, analysis functions, plotting helpers, export helpers, sessions, and tests.

## Current Status

The v1.0 behavior-preserving package refactor is complete.

What that means:

- Current runtime entry points live under `apps/`.
- Preserved GUI implementations remain under `legacy/` as behavior references, not default-path commands.
- CIC, VT resistance, CV/CSC, chrono overlay, and EIS overlay/export workflows have package-backed parser, analysis, plotting, export, or UI helper coverage where v1.0 required it.
- `gamrywb_EIS_app`, `gamrywb_CSC_app`, and `gamrywb_VTResistance_app` are package-backed; the CIC app entry point currently delegates to the preserved legacy GUI.

Deferred beyond v1.0:

- Replacing the remaining CIC app delegate with package-backed app internals.
- Unified workbench GUI.
- Stored golden MAT references for every major analysis output.

## Getting Started

From the repository root in MATLAB:

```matlab
startup_gamrywb

% App entry points
gamrywb_CIC_app
gamrywb_VTResistance_app
gamrywb_CSC_app
gamrywb_EIS_app
```

`gamrywb_EIS_app`, `gamrywb_CSC_app`, and `gamrywb_VTResistance_app` are package-backed app entry points. The CIC `gamrywb_*_app` entry point currently delegates to a behavior-preserved legacy GUI and remains a compatibility entry point.

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
+gamrywb/             Reusable MATLAB package modules
apps/                 App entry points and compatibility delegates
legacy/               Preserved legacy GUI implementations used as reference code
demo/                 Named DTA fixtures
tests/                MATLAB tests
scripts/              Test runner scripts
docs/                 Architecture, data model, parser, validation, and history docs
```

## Documentation

- `AGENTS.md`: agent and developer operating rules.
- `CHANGELOG.md`: release-style change history.
- `docs/architecture.md`: current architecture and boundaries.
- `docs/data_model.md`: current item/result/session schemas.
- `docs/file_format_notes.md`: DTA parser assumptions.
- `docs/validation_protocol.md`: behavior-preservation validation.
- `docs/refactor_history.md`: concise archived migration history.

## Preservation Rule

Do not change scientific formulas, parser behavior, pulse detection behavior, GUI behavior, plot labels, or CSV/export formats during repository hygiene work.

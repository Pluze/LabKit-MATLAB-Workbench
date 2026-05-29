# Gamry Electrochemistry Workbench

MATLAB workbench for refactoring and maintaining Gamry electrochemistry DTA analysis GUIs.

This repository is being migrated from several standalone MATLAB GUI scripts into a reusable `+gamrywb` package while preserving legacy behavior.

---

## Current Status

The project is in an early behavior-preserving refactor stage.

Completed or started work:

- Phase 0 complete: legacy functions inventoried and migration notes started.
- Phase 1 complete: package skeleton and low-risk utilities added.
- Phase 2 mostly complete: chrono, EIS, and CV/CT parser modules extracted.
- Phase 3 mostly complete: shared pulse detection is used by the multi-DTA overlay/export, VT resistance, and CIC legacy GUIs.
- Phase 4 started: chrono overlay plotting and CSV export table construction are package-backed.
- Phase 5 started: VT resistance analysis and result/export table construction are package-backed.
- Phase 6 started: CIC / voltage-transient analysis and result/export table construction are package-backed.
- Phase 7 started: CV/CT charge, CSC analysis, selected-column access, and plotting are package-backed.
- Phase 8 complete: EIS item construction, axis values, overlay plotting, and current-plot export tables are package-backed.
- Phase 9 complete for the current legacy-compatible scope: shared session creation, file add/remove, save/load, batch summary helpers, VT/CIC/CV-CSC result table helpers, and legacy GUI session-state wiring are available.
- Legacy GUI entry points remain available through root-level compatibility wrappers.
- Demo DTA fixtures and MATLAB pure-function tests are available.

Not started yet:

- New thin apps under `apps/`.
- Unified workbench GUI.

The current goal is **same behavior, less duplicate code, clearer boundaries**.

---

## Getting Started

From the repository root in MATLAB, run:

```matlab
startup_gamrywb
```

Then launch one of the compatibility entry points:

```matlab
gamry_multiDTA_plot_export_gui
gamry_EIS_multiDTA_plot_gui
gamry_CV_CSC_dta_gui
gamry_VT_resistance_gui
gamry_CIC_VT_gui_paperlabels
```

The root-level entry points forward to preserved implementations under `legacy/`.

---

## Running Tests

From a macOS shell, run:

```bash
scripts/run_matlab_tests.sh
```

To include optional noninteractive GUI checks, run:

```bash
scripts/run_matlab_tests.sh --gui
```

The test runner attempts to find MATLAB through:

1. `MATLAB_CMD`
2. `matlab` on PATH
3. `/Applications/MATLAB_*.app/bin/matlab`

The default tests are intended for pure functions only. The optional `--gui` mode is the regression guard for preserving legacy GUI functionality during refactors: it checks that the legacy GUI entry points can create and close their main `uifigure` windows, verifies exact initialized component counts, required controls, complete dropdown item groups, tab titles, result-table columns, initial axes titles/labels, and window-size floors, then invokes safe callbacks that do not open dialogs. It does not open file dialogs, write exports, or validate manual interactions.

---

## Repository Layout

```text
+gamrywb/             Reusable MATLAB package modules
legacy/               Preserved legacy GUI implementations and compatibility shims
apps/                 Future thin app entry points
demo/                 Named DTA fixtures for tests and examples
tests/                MATLAB pure-function tests
scripts/              Local test runner scripts
docs/                 Architecture, data model, parser, validation, and future notes
```

---

## Documentation Map

- `AGENTS.md`: AI/Codex operating instructions.
- `REFACTOR_ROADMAP.md`: active phase plan and definition of done.
- `MIGRATION_NOTES.md`: completed migration history, behavior notes, and open risks.
- `CHANGELOG.md`: concise user-facing change record.
- `docs/architecture.md`: target layering and module boundaries.
- `docs/data_model.md`: planned struct models and naming conventions.
- `docs/file_format_notes.md`: Gamry DTA parser assumptions.
- `docs/validation_protocol.md`: test and reference-output strategy.
- `docs/future_features.md`: future features that should not be started before v1.0.

---

## Important Refactor Rule

Do not change scientific algorithms during structural refactoring unless explicitly requested.

Legacy behavior should remain the reference for parser outputs, pulse timing, CIC/CSC/resistance calculations, plotting behavior, and CSV export formats.

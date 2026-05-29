# Gamry Electrochemistry Workbench

MATLAB tools for analyzing Gamry electrochemistry DTA files. The project preserves the original analysis workflows through app entry points under `apps/` and reusable `+gamrywb` APIs for Gamry/DTA loading plus scientific-app GUI scaffolding.

## Current Status

The v1.0 behavior-preserving package refactor is complete.

What that means:

- Current runtime entry points live under `apps/`.
- The old `legacy/` GUI reference directory has been removed after app entry points became package-backed.
- CIC, VT resistance, CV/CSC, chrono overlay, and EIS overlay/export workflows have package-backed parser, analysis, plotting, export, or UI helper coverage where v1.0 required it.
- App entry points are package-backed and live under `apps/`.
- EIS, Chrono overlay, and CSC are now public single-file app implementations. VT resistance and CIC still have transitional `apps/private` launch bodies that should be collapsed back into their public app files.
- CSC-specific charge/CSC calculations now live on the app side instead of the reusable `+gamrywb` library; the long-term ideal is one experiment app file owning its scientific workflow.
- VT-specific resistance calculations, export formatting, and batch-table display data now live on the app side instead of the reusable `+gamrywb` library.
- CIC-specific voltage-transient calculations, export formatting, and batch-table display data now live on the app side instead of the reusable `+gamrywb` library.

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
+gamrywb/             Reusable Gamry/DTA APIs, scientific-app GUI APIs, and utilities
apps/                 App entry points and app-specific implementations
demo/                 Named DTA fixtures
tests/                MATLAB tests
scripts/              Test runner scripts
docs/                 Architecture, data model, parser, validation, and history docs
```

## Documentation

- `AGENTS.md`: agent and developer operating rules.
- `CHANGELOG.md`: release-style change history.
- `docs/architecture.md`: current architecture and boundaries.
- `docs/app_framework_roadmap.md`: planned app framework extraction route.
- `docs/data_model.md`: current item/result/session schemas.
- `docs/file_format_notes.md`: DTA parser assumptions.
- `docs/validation_protocol.md`: behavior-preservation validation.
- `docs/refactor_history.md`: concise archived migration history.

## Preservation Rule

Do not change scientific formulas, parser behavior, pulse detection behavior, GUI behavior, plot labels, or CSV/export formats during repository hygiene work.

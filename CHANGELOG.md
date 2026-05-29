# Changelog

All notable user-facing and maintainer-facing changes are recorded here.

## Unreleased

- No unreleased changes yet.

## v1.0.0 - 2026-05-28

### Added

- Package-backed parser, data, analysis, plotting, export, session, and UI helper modules under `+gamrywb`.
- Compatibility app entry points under `apps/` for CIC, VT resistance, CV/CSC, and EIS workflows.
- Root-level compatibility wrappers for the original legacy GUI command names.
- Named demo DTA fixtures for parser, pulse detection, analysis, plotting, export, and session tests.
- MATLAB pure-function test runner under `scripts/run_matlab_tests.sh`.
- Optional noninteractive GUI compatibility-contract checks under `scripts/run_matlab_tests.sh --gui`.
- Current documentation under `docs/` for architecture, data models, file formats, validation, and refactor history.

### Changed

- Moved preserved legacy GUI implementations under `legacy/`.
- Updated selected legacy GUI implementations to call package-backed helpers while preserving behavior.
- Removed legacy-directory same-name shims and kept original command compatibility through root wrappers.
- `startup_gamrywb` no longer adds `legacy/` to the default path.
- Reorganized root documentation so README and CHANGELOG describe current usage and release status, while phase history lives in `docs/refactor_history.md`.
- App entry points delegate to behavior-preserved legacy GUI entry points for the v1.0 compatibility scope.

### Preserved

- Legacy GUI command names.
- Scientific calculations and result definitions.
- Parser behavior for legacy-supported DTA file families.
- Pulse detection behavior.
- GUI layout and callback behavior.
- Plot labels, markers, axes, and visual behavior.
- CSV/export formats and column names.

### Deferred

- Package-backed replacements for the app delegates.
- Unified workbench GUI.
- Complete stored golden MAT reference outputs for every major analysis output.
- Broader parser unification and support for additional Gamry experiment types.

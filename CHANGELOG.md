# Changelog

All notable user-facing and maintainer-facing changes are recorded here.

## Unreleased

### Removed

- Root-level wrappers for the original legacy GUI command names.
- The old `legacy/` GUI reference directory after app entry points became package-backed.

### Changed

- Extracted shared initial axes creation for Chrono/EIS overlay apps into `+gamrywb/+ui`.
- Extracted the shared Chrono/EIS plot-options panel shell into `+gamrywb/+ui`.
- Extracted shared Chrono/EIS info and log text-area helpers into `+gamrywb/+ui`.
- Extracted the shared Chrono/EIS files button panel into `+gamrywb/+ui`.
- Extracted the shared Chrono/EIS two-pane outer shell into `+gamrywb/+ui`.
- Extracted session item file-listbox refresh for Chrono/EIS overlay apps into `+gamrywb/+ui`.
- Shared selected-item lookup for Chrono/EIS overlay plot and export paths through `+gamrywb/+app`.
- Shared selected-item session removal for Chrono/EIS overlay apps through `+gamrywb/+app`.
- Started the `+gamrywb/+app` layer with duplicate-aware file/session loading shared by Chrono/EIS overlay apps.
- Extracted simple labeled dropdown/edit-field row helpers for Chrono/EIS plot options into `+gamrywb/+ui`.
- Extracted shared app log append behavior into `+gamrywb/+ui`.
- Extracted shared multiselect file-list refresh behavior for overlay apps into `+gamrywb/+ui`.
- Rewrote the app framework roadmap around the current package-backed app state and the next extraction route.
- Extracted shared app axes reset and interactivity helpers into `+gamrywb/+ui`.
- Replaced `gamrywb_VTResistance_app`'s legacy delegate with a package-backed VT resistance app implementation.
- Replaced `gamrywb_CIC_app`'s legacy delegate with a package-backed CIC voltage-transient app implementation.
- Added `gamrywb_ChronoOverlay_app` as the package-backed app entry point for chrono overlay/export.
- GUI compatibility tests now treat `apps/` as the complete runtime entrypoint surface.

## v1.0.0 - 2026-05-28

### Added

- Package-backed parser, data, analysis, plotting, export, session, and UI helper modules under `+gamrywb`.
- App entry points under `apps/` for CIC, VT resistance, CV/CSC, and EIS workflows.
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
- Replaced `gamrywb_EIS_app`'s legacy delegate with a package-backed EIS app implementation.
- Replaced `gamrywb_CSC_app`'s legacy delegate with a package-backed CV/CSC app implementation.
- Reorganized root documentation so README and CHANGELOG describe current usage and release status, while phase history lives in `docs/refactor_history.md`.
- Remaining CIC and VT resistance compatibility app entry points delegate to behavior-preserved legacy GUI entry points for the v1.0 compatibility scope.

### Preserved

- Legacy GUI command names.
- Scientific calculations and result definitions.
- Parser behavior for legacy-supported DTA file families.
- Pulse detection behavior.
- GUI layout and callback behavior.
- Plot labels, markers, axes, and visual behavior.
- CSV/export formats and column names.

### Deferred

- Unified workbench GUI.
- Complete stored golden MAT reference outputs for every major analysis output.
- Broader parser unification and support for additional Gamry experiment types.

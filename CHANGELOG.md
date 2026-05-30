# Changelog

All notable user-facing and maintainer-facing changes are recorded here.

## Unreleased

### Changed

- Reusable package, startup, and app entrypoint names now use the generic `labkit` namespace.
- Chrono DTA loading now exposes `item.controlMode` / `meta.controlMode` for current-controlled, voltage-controlled, or unknown chrono files, and CIC/VT summary panels display that mode for the selected file.
- Public app-facing package surface is now `labkit.ui.*` plus `labkit.dta.*`.
- DTA parser helpers, session save/load, item/session construction, pulse internals, and parsed table/curve access now live behind the DTA facade or under `+labkit/+dta/private`.
- Current app implementations are single public files under `apps/`; experiment-specific analysis, plotting, result tables, and CSV/export schemas stay app-local.
- Documentation and architecture tests now guard against reintroducing public `+io`, `+data`, `+analysis`, `+util`, app-helper packages, or legacy wrapper entry points as app-facing APIs.
- Template programs now model the intended split: GUI-only, DTA-only, or GUI plus DTA, without exposing internal helper packages.
- `startup_labkit` now adds nested app category folders so app entry points resolve without changing into app directories.
- Current app GUIs now share the same resizable tabbed workbench shell: scrollable control tabs on the left and plot/output content on the right.
- App shells now use the standard three-tab workbench framework, and DTA-facing apps share the same file-selection panel structure.

### Fixed

- CSC app file loading now preserves the loaded session item struct shape while updating app state, and GUI tests cover loading a CV/CT fixture through the CSC app refresh path.

### Removed

- Public `+labkit/+io`, `+labkit/+data`, `+labkit/+analysis`, `+labkit/+util`, `+labkit/+plot`, and `+labkit/+app` app-facing surfaces.
- Transitional `apps/private` and `apps/+labkit_apps` helper namespaces.
- Root-level wrappers for the original legacy GUI command names and the old `legacy/` reference directory.
- One-line or app-specific reusable wrappers that only hid MATLAB built-ins or experiment decisions.

## v1.0.0 - 2026-05-28

### Added

- Package-backed parser, data, analysis, plotting, export, session, and UI helper modules under `+labkit`.
- App entry points under `apps/` for CIC, VT resistance, CV/CSC, and EIS workflows.
- Root-level compatibility wrappers for the original legacy GUI command names.
- Named demo DTA fixtures and MATLAB test runners.
- Current documentation under `docs/` for architecture, data models, file formats, validation, and refactor history.

### Preserved

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

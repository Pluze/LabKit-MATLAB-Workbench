# Changelog

All notable user-facing and maintainer-facing changes are recorded here.

## Unreleased

### Added

- GUI-free `+gamrywb/+dta` facade for recursive discovery, type detection, single-file loading, batch loading, and folder loading with status/report structs.
- Public single-file app implementations for EIS, Chrono overlay, CSC, VT resistance, and CIC under `apps/`.
- Reusable API usage guide with the single-file app template and new-app checklist.
- Architecture boundary tests for app ownership and reusable `+gamrywb` layer dependencies.
- `gamrywb.util.interp1Safe` for shared finite-vector interpolation with nearest-point fallback.
- Shared test fixture helpers and DTA facade edge-case coverage.

### Changed

- App-specific scientific workflow now lives in the owning app files: analysis formulas, plot annotations, result tables, export schemas, and CSV writing are not reusable `+gamrywb` APIs.
- Current apps load files through the GUI-free DTA facade where supported, while retaining app-local behavior such as Chrono pulse-gap alignment and EIS axis/export choices.
- App header comments now consistently describe single-file app ownership without implying reusable-library ownership of experiment-specific analysis.
- Agent/developer rules now describe app-specific helper packages as removed boundaries that should not be reintroduced and limit new package helpers to genuinely cross-cutting code.
- Reusable GUI helpers are kept domain-neutral: DTA-specific labels, shell tab titles, app callback choreography, and app reset/default behavior stay in the apps.
- Generic prepared-X/Y plotting lives in `gamrywb.ui.plotXY`; parsed-curve column selection stays in `gamrywb.data.getCurveXY` so the GUI layer does not depend on the data layer.
- Tests now separate default and GUI groups, share repeated fixture/assertion helpers, and keep architecture guardrails in `test_architecture_boundaries`.
- Session and DTA facade helpers now handle empty inputs, invalid expected kinds, and invalid folders consistently.
- CIC and VT resistance apps now call the shared interpolation utility instead of keeping duplicated local fallback helpers.
- Current docs now describe the stable three-surface library shape without keeping separate roadmap/playbook files.

### Removed

- Root-level wrappers for the original legacy GUI command names and the old `legacy/` GUI reference directory.
- Transitional `apps/private`, `apps/+gamrywb_apps`, `+gamrywb/+app`, and `+gamrywb/+plot` migration layers.
- App-specific reusable analysis/export helpers that hid experiment decisions outside the owning app file.
- The one-line `gamrywb.io.exportTableCSV` wrapper; apps that need MATLAB's default table writer call `writetable` directly.
- The data-coupled `gamrywb.ui.plotCurveXY` helper; apps now call `gamrywb.data.getCurveXY` before `gamrywb.ui.plotXY`.

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
- CIC and VT resistance app delegates were still deferred during the v1.0 compatibility checkpoint and have since been replaced in `Unreleased`.

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

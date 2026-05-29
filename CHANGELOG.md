# Changelog

All notable user-facing and maintainer-facing changes are recorded here.

## Unreleased

### Added

- Added a GUI-free `+gamrywb/+dta` facade for supported DTA discovery, type detection, single-file loading, and batch loading with status/report structs.
- Added `gamrywb.dta.findFiles` as the GUI-free DTA discovery facade for recursive folder scans.
- Added `gamrywb.dta.loadFolder` for GUI-free recursive folder discovery and loading in scripts or app prototypes.
- Added fixture-driven tests covering DTA facade detection, auto-loading, expected-kind mismatch handling, missing-file status, and mixed-family batch loading.

### Removed

- Root-level wrappers for the original legacy GUI command names.
- The old `legacy/` GUI reference directory after app entry points became package-backed.

### Changed

- Moved the EIS app implementation under `apps/private` so app-specific workflow code no longer lives in the reusable `+gamrywb` package.
- Moved the Chrono overlay app implementation under `apps/private` so overlay workflow code no longer lives in the reusable `+gamrywb` package.
- Moved the CSC app implementation and CSC-specific charge/CSC calculations to the app side outside the reusable `+gamrywb` package.
- Moved the VT resistance app implementation and VT-specific resistance/export/table logic to the app side outside the reusable `+gamrywb` package.
- Moved the CIC app implementation and CIC-specific voltage-transient/export/table logic to the app side outside the reusable `+gamrywb` package.
- Moved CIC-specific injected-charge, voltage-transient metric, and water-window helper calculations to the app side.
- Moved Chrono overlay pulse-gap alignment, VT/IT overlay plotting, and overlay CSV table construction out of the reusable `+gamrywb` package.
- Moved EIS overlay axis selection, overlay plotting, and plot CSV table construction to the app side outside the reusable `+gamrywb` package.
- Moved CSC CV/CT plotting to the app side and removed the empty reusable `+gamrywb/+plot` package.
- Collapsed the EIS app implementation from `apps/private` into the public `apps/gamrywb_EIS_app.m` single-file app entry.
- Collapsed the Chrono overlay app implementation from `apps/private` into the public `apps/gamrywb_ChronoOverlay_app.m` single-file app entry.
- Collapsed the CSC app implementation from `apps/private` into the public `apps/gamrywb_CSC_app.m` single-file app entry.
- Collapsed the VT resistance app implementation from `apps/private` into the public `apps/gamrywb_VTResistance_app.m` single-file app entry.
- Collapsed the CIC app implementation from `apps/private` into the public `apps/gamrywb_CIC_app.m` single-file app entry and removed the now-empty `apps/private` launcher directory.
- Folded Chrono overlay alignment, plotting, and export helpers into local functions in `apps/gamrywb_ChronoOverlay_app.m` and removed the temporary `apps/+gamrywb_apps/+chrono` package.
- Folded EIS overlay axis selection, plotting, and export helpers into local functions in `apps/gamrywb_EIS_app.m` and removed the temporary `apps/+gamrywb_apps/+eis` package.
- Streamlined app boundary tests by sharing single-file entrypoint assertions while keeping app-specific architecture checks explicit.
- Clarified the roadmap around reusable GUI, Gamry/DTA, and utility library surfaces plus single-file experiment apps.
- Added reusable API usage documentation and a single-file app template for future experiments.
- Expanded reusable API usage guidance with loading API choices and a new-app design checklist.
- Documented DTA facade discovery, status, and folder-load report schemas in the data model notes.
- Folded CSC CT/CV charge subcalculations into `apps/+gamrywb_apps/+csc/computeCSC.m` and removed redundant public/private helper files.
- Folded the remaining CSC charge/CSC calculation into local functions in `apps/gamrywb_CSC_app.m` and removed the transitional CSC helper package file.
- Folded VT steady-window and baseline subcalculations into the VT app-side resistance workflow and removed redundant public helper files.
- Folded the remaining VT resistance analysis, result-table, batch-table, and CSV helpers into local functions in `apps/gamrywb_VTResistance_app.m` and removed the transitional VT helper package files.
- Folded the remaining CIC analysis, result-table, batch-table, and CSV helpers into local functions in `apps/gamrywb_CIC_app.m` and removed the transitional CIC helper package files.
- Promoted generic selected-curve plotting to `gamrywb.ui.plotCurveXY` and removed the CSC-specific plotting helper.
- Removed the unused CSC result-table helper because the current CSC app has no CSV/export workflow.
- Streamlined app-boundary tests to prevent transitional helper packages, unused helper files, or private launcher directories from returning.
- Streamlined app-boundary DTA facade assertions so future facade API changes do not duplicate test boilerplate across every app.
- Tightened DTA facade tests around documented status and report schemas.
- Split the MATLAB test runner manifest into default and GUI groups so future tests have clearer placement.
- Removed duplicate app-boundary assertions from overlay export tests now that `test_phase10_apps` owns those architecture checks.
- Replaced repeated per-file numeric assertion helpers in tests with a shared test helper.
- Updated the app framework roadmap so completed app migrations are marked complete and the next-phase guidance focuses on extension contracts and guardrails.
- Corrected the documented single-select file-list refresh API signature to include the loaded-count text field.
- Folded VT/CIC single-file selection and clear-all callback choreography back into the owning app files so reusable UI helpers do not own app session workflow.
- Folded Chrono/EIS info and log text-area construction back into the owning app files and removed the row-hardcoded reusable wrappers.
- Replaced the item-schema-specific `refreshFileListbox` UI helper with app-local name extraction plus generic `refreshListboxItems`.
- Folded VT/CIC single-select file-list refresh state back into the owning app files and removed the item-schema-specific UI helper.
- Replaced the title-specific `resetTopBottomAxes` wrapper with direct app calls to the generic `hardResetAxis` helper.
- Moved DTA-specific file-panel button labels out of reusable GUI helpers and into the owning apps.
- Moved tabbed dual-plot shell tab and panel labels out of the reusable GUI helper and into the owning apps.
- Documented the required GUI label structs for file panels and tabbed dual-plot shells.
- Routed the EIS app's file loading through the GUI-free DTA facade instead of constructing EIS items directly in the app layer.
- Routed the Chrono overlay app's file loading through the GUI-free DTA facade while keeping pulse-gap alignment in the app workflow.
- Routed the CSC app's CV/CT file loading through the GUI-free DTA facade instead of parsing CV/CT files directly in the app layer.
- Routed the VT resistance app's chrono file loading through the GUI-free DTA facade instead of parsing chrono files directly in the app layer.
- Routed the CIC app's chrono file loading through the GUI-free DTA facade instead of parsing chrono files directly in the app layer.
- Routed folder-based DTA discovery in folder-capable apps through the GUI-free DTA facade instead of the lower-level IO helper.
- Extracted shared batch-result table panel construction for VT/CIC-style apps into `+gamrywb/+ui`.
- Moved generic batch result summaries from `+gamrywb/+analysis` to `+gamrywb/+data` so the reusable analysis surface stays pulse-focused.
- Moved GUI-free session loading, selected-item removal, and selected-item lookup helpers from `+gamrywb/+ui` to `+gamrywb/+data`.
- Removed the one-line `gamrywb.io.exportTableCSV` wrapper; apps that need MATLAB's default table writer call `writetable` directly.
- Extracted shared top/bottom plot selection and axes reset helpers for VT/CIC-style apps into `+gamrywb/+ui`.
- Shared the VT/CIC clear-all session reset sequence through `+gamrywb/+ui`.
- Shared the VT/CIC single-file selection callback sequence through `+gamrywb/+ui`.
- Extracted shared log-tab panel construction for VT/CIC-style apps into `+gamrywb/+ui`.
- Extracted shared read-only summary-row construction for VT/CIC-style apps into `+gamrywb/+ui`.
- Extracted shared single-select file-list refresh behavior for VT/CIC-style apps into `+gamrywb/+ui`.
- Extracted the shared single-select files panel for VT/CIC-style apps into `+gamrywb/+ui` and adopted it in the VT resistance and CIC apps.
- Extracted shared top/bottom plot-control rows for VT/CIC-style apps into `+gamrywb/+ui` and adopted them in the VT resistance and CIC apps.
- Extracted the shared tabbed dual-plot shell for VT/CIC-style apps into `+gamrywb/+ui` and adopted it in the VT resistance and CIC apps.
- Moved CSC app assembly behind the public `apps/` entry point, then relocated it under `apps/private` as an independent-app pattern.
- Moved CIC app assembly behind the public `apps/` entry point, then relocated it under `apps/private` as an independent-app pattern.
- Moved VT resistance app assembly behind the public `apps/` entry point, then relocated it under `apps/private` as an independent-app pattern.
- Moved EIS app assembly behind the public `apps/` entry point, then relocated it under `apps/private` as the reference independent-app pattern.
- Moved Chrono overlay app assembly behind the public `apps/` entry point, then relocated it under `apps/private` as an independent-app pattern.
- Extracted shared initial axes creation for Chrono/EIS overlay apps into `+gamrywb/+ui`.
- Extracted the shared Chrono/EIS plot-options panel shell into `+gamrywb/+ui`.
- Extracted shared Chrono/EIS info and log text-area helpers into `+gamrywb/+ui`.
- Extracted the shared Chrono/EIS files button panel into `+gamrywb/+ui`.
- Extracted the shared Chrono/EIS two-pane outer shell into `+gamrywb/+ui`.
- Extracted session item file-listbox refresh for Chrono/EIS overlay apps into `+gamrywb/+ui`.
- Shared selected-item lookup for Chrono/EIS overlay plot and export paths through `+gamrywb/+ui`.
- Shared selected-item session removal for Chrono/EIS overlay apps through `+gamrywb/+ui`.
- Shared duplicate-aware file/session loading for Chrono/EIS overlay apps through `+gamrywb/+ui`.
- Removed the transitional `+gamrywb/+app` package after app launchers moved under `apps/private` and remaining generic GUI/session helpers moved to `+gamrywb/+ui`.
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

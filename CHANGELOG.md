# Changelog

All notable user-facing and maintainer-facing changes are recorded here.

This project is still in an unreleased behavior-preserving refactor stage.

---

## Unreleased

### Added

- Added `AGENTS.md` as the canonical AI/Codex operating instruction file.
- Added `startup_gamrywb.m` for MATLAB path setup.
- Added initial `+gamrywb` package structure.
- Added low-risk shared utility helpers under `+gamrywb/+util`.
- Added shared chrono DTA parser under `+gamrywb/+io/parseChronoDTA.m`.
- Added shared EIS DTA parser under `+gamrywb/+io/parseEISDTA.m`.
- Added shared CV/CT DTA parser under `+gamrywb/+io/parseCVCTDTA.m`.
- Added shared DTA discovery and data accessor helpers.
- Added shared chrono overlay export table and CSV writer helpers.
- Added initial shared pulse detection helpers under `+gamrywb/+analysis`.
- Added shared chrono item construction and pulse-gap alignment helpers.
- Added shared VT resistance analysis helpers under `+gamrywb/+analysis`.
- Added shared chrono VT/IT overlay plot helper.
- Added named demo DTA fixtures for parser and pulse-detection tests.
- Added MATLAB pure-function test runner under `scripts/run_matlab_tests.sh`.
- Added documentation pages under `docs/` for architecture, data models, file formats, validation, and future features.

### Changed

- Moved preserved legacy GUI implementations under `legacy/`.
- Replaced root-level legacy GUI files with compatibility wrappers that preserve original command names.
- Updated selected legacy GUI implementations to call extracted parser and utility functions where behavior is intended to remain identical.
- Updated `legacy/gamry_multiDTA_plot_export_gui_legacy.m` to use shared pulse detection, chrono item construction, and pulse-gap alignment.
- Updated `legacy/gamry_multiDTA_plot_export_gui_legacy.m` to use shared chrono overlay plotting and CSV export table construction.
- Updated `legacy/gamry_VT_resistance_gui_legacy.m` to use shared chrono parsing, DTA discovery, table/column accessors, pulse detection, and low-risk utilities.
- Updated `legacy/gamry_VT_resistance_gui_legacy.m` to call shared VT resistance analysis.
- Updated `legacy/gamry_CIC_VT_gui_paperlabels_legacy.m` to use shared chrono parsing, DTA discovery, table/column accessors, pulse detection, and low-risk utilities.
- Reorganized Markdown documentation so README, roadmap, migration notes, AI instructions, and detailed docs have separate responsibilities.

### Preserved

- Scientific analysis formulas are not intentionally changed.
- Legacy GUI command names remain available.
- GUI behavior remains intended to match the preserved legacy scripts.
- CSV export formats are not intentionally changed.

### Known Gaps

- CIC analysis has not been fully extracted into package functions.
- VT resistance analysis has not been fully extracted into package functions.
- CV/CSC analysis has not been fully extracted into package functions.
- EIS overlay/export logic has not been fully extracted into package functions.
- New thin apps under `apps/` have not been implemented.
- Unified workbench GUI has not been started.
- Golden reference tests for every major analysis output are not complete yet.

# Migration Notes

## Phase 0-1 Scope

This phase establishes the refactor safety baseline and extracts only low-risk utilities. Scientific algorithms, DTA parsing behavior, pulse detection, plotting, and CSV export wire format are intentionally unchanged.

The original GUI command names remain available from the repository root through compatibility wrappers. The preserved implementations live in `legacy/*_legacy.m`; `legacy/<original name>.m` files are shims for users who add `legacy/` directly to the MATLAB path.

## Phase 2 Progress

Started Phase 2 with the lowest-risk chrono parser migration:

- Added `gamrywb.io.parseChronoDTA`.
- Added `gamrywb.io.findDTAFilesRecursive`.
- Added `gamrywb.data.getMainCurve`.
- Added `gamrywb.data.getColumn`.
- Updated only `legacy/gamry_multiDTA_plot_export_gui_legacy.m` to use these package functions.
- Added `gamrywb.io.parseEISDTA`.
- Added `gamrywb.data.getZCurve`.
- Updated only `legacy/gamry_EIS_multiDTA_plot_gui_legacy.m` to use the extracted EIS parser, shared DTA discovery, shared struct append, shared short file names, and shared column access.
- Added `gamrywb.io.parseCVCTDTA`.
- Updated only `legacy/gamry_CV_CSC_dta_gui_legacy.m` to use the extracted CV/CT parser.
- Left pulse detection, alignment, plotting, CSV export, and analysis logic local for later Phase 3+ commits.

## Phase 3 Progress

Started Phase 3 with shared pulse detection:

- Added `gamrywb.analysis.defaultPulseOptions`.
- Added `gamrywb.analysis.detectPulses`.
- Added `gamrywb.analysis.pulsesFromMetadata`.
- Added `gamrywb.analysis.pulsesFromCurrent`.
- Added `gamrywb.analysis.emptyPulse`.
- Updated only `legacy/gamry_multiDTA_plot_export_gui_legacy.m` to use the extracted pulse detection.
- The pulse struct currently keeps legacy flat fields such as `cath_start` and `gap_end` while also adding normalized `cath`, `anod`, and `gap` nested fields for later migration.
- VT resistance and CIC still use their local pulse detection until their Phase 3 migration commits.

## Git History Requirements

The refactor must preserve a useful local git history. Do not treat a large uncommitted working tree as finished work.

Required habits:

- Check `git status --short` before and after each refactor batch.
- Split work into logical commits whenever practical.
- Keep behavior-preserving moves, documentation updates, test harness changes, and executable refactors separate when the diff is large enough to review independently.
- Run `scripts/run_matlab_tests.sh` before committing executable MATLAB changes.
- Fetch and push the remote repository regularly after tested local commits.
- If MATLAB cannot run, document the blocker in the migration notes or final handoff.
- Do not commit generated logs such as `matlab_test.log`, `.DS_Store`, exported CSVs, or unrelated user changes.
- Prefer commit messages that state the purpose of the change, such as `refactor: add phase 1 utility package` or `test: add MATLAB smoke test runner`.

Remote sync rules:

- Run `git fetch origin` before pushing local phase commits.
- If the branch is only ahead of `origin/main`, push after tests pass.
- If the branch is behind or diverged, inspect incoming commits before rebasing or merging.
- Do not force-push unless the user explicitly approves it.
- Mention local-vs-remote status in handoffs when commits are not yet pushed.

Current local MATLAB test command:

```bash
scripts/run_matlab_tests.sh
```

## Demo Fixture Naming

Demo DTA files are named by test role so parser and analysis tests can choose the correct fixture without relying on ambiguous file names:

- `chrono_chronopot_current_pulse_0p2ms.DTA`, `chrono_chronopot_current_pulse_1ms.DTA`, and `chrono_chronopot_current_pt_0p65ms.DTA`: `TAG MULTI_STEP_CHRONOPOT` / `TITLE Chronopotentiometry Scan` current-controlled chrono fixtures.
- `chrono_chronoamp_voltage_pulse_0p2ms.DTA` and `chrono_chronoamp_voltage_pulse_1ms.DTA`: `TAG MULTI_STEP_CHRONOA` / `TITLE Chronoamperometry Scan` voltage-controlled chrono fixtures.
- `cv_cyclic_voltammetry_pt_reference.DTA` and `cv_cyclic_voltammetry_pt_replicate.DTA`: `TAG CV` / `TITLE Cyclic Voltammetry` fixtures.
- `eis_potentiostatic_zcurve.DTA`: `TAG EISPOT` / `TITLE Potentiostatic EIS` fixture.

Tests should assert required named fixtures exist and may assert minimum fixture counts, but should not fail merely because additional DTA files are added to `demo/`.

## Legacy Function Inventory

| Function | Found in files | Proposed package location | Notes |
|---|---|---|---|
| `parseGamryChronoDTA` | CIC, VT resistance, multi-DTA overlay | `+gamrywb/+io/parseChronoDTA.m` | Preserve metadata parsing, table parsing, log messages, invalid row handling, and unique-time behavior. Deferred to Phase 2. |
| `parseGamryDTA` for EIS | EIS overlay | `+gamrywb/+io/parseEISDTA.m` | Preserve `ZCURVE` detection and arbitrary axis support. Deferred to Phase 2/8. |
| `parseGamryDTA` for CV/CT | CV/CSC GUI | `+gamrywb/+io/parseCVCTDTA.m` | Preserve curve discovery and `SCANRATE` conversion from mV/s to V/s. Deferred to Phase 2/7. |
| `getMainCurve` | CIC, VT resistance, multi-DTA overlay | `+gamrywb/+data/getMainCurve.m` | Preserve preference for `CURVE`/`CURVE1`, then fallback to T/Vf/Im headers. Deferred to Phase 2. |
| `getZCurve` | EIS overlay | `+gamrywb/+data/getZCurve.m` | Preserve `ZCURVE` first, then Freq/Zreal/Zimag header fallback. Deferred to Phase 2/8. |
| `getColByName` | all GUI families | `+gamrywb/+data/getColumn.m` | Case-sensitivity differs by file; normalize only during parser/data-access extraction. Deferred. |
| `findDTAFilesRecursive` | CIC, VT resistance, EIS overlay, multi-DTA overlay | `+gamrywb/+io/findDTAFilesRecursive.m` | Preserve recursive `.DTA`/`.dta` scan order. Deferred to Phase 2. |
| `detectPulses` | CIC, VT resistance, multi-DTA overlay | `+gamrywb/+analysis/detectPulses.m` | Preserve metadata-first behavior and GUI mode options. Deferred to Phase 3. |
| `pulsesFromMetadata` | CIC, VT resistance, multi-DTA overlay | `+gamrywb/+analysis/pulsesFromMetadata.m` | Preserve ISTEP/TSTEP and VSTEP/TSTEP interpretation. Deferred to Phase 3. |
| `pulsesFromCurrent` | CIC, VT resistance, multi-DTA overlay | `+gamrywb/+analysis/pulsesFromCurrent.m` | Preserve threshold and longest-segment behavior. Deferred to Phase 3. |
| `emptyPulse` | CIC, VT resistance, multi-DTA overlay | `+gamrywb/+analysis/emptyPulse.m` | Future normalized pulse struct should be introduced only when Phase 3 updates all call sites. |
| `contiguousSegments` | CIC, VT resistance, multi-DTA overlay | `+gamrywb/+analysis/pulsesFromCurrent.m` or `+gamrywb/+util/` | Keep local until pulse detection extraction. |
| `buildExportTable` | multi-DTA overlay, EIS overlay | `+gamrywb/+io/buildChronoOverlayExportTable.m`, `+gamrywb/+io/buildEISExportTable.m` | Preserve CSV headers and interpolation behavior. Deferred to Phase 4/8. |
| `valuesForAxis` | EIS overlay | `+gamrywb/+analysis/valuesForEISAxis.m` | Preserve all axis labels and log-axis behavior. Deferred to Phase 8. |
| `integrate_signsplit_fullcurve` | CV/CSC GUI | `+gamrywb/+analysis/computeCSC.m` | Preserve zero-crossing split and CT/CV integration rules. Deferred to Phase 7. |
| `appendStruct` | CIC, EIS overlay, multi-DTA overlay | `+gamrywb/+util/appendStruct.m` | Extracted in Phase 1. |
| `shortName` | CIC, EIS overlay, multi-DTA overlay | `+gamrywb/+util/shortName.m` | Extracted in Phase 1. |
| `splitTabs` | all GUI families | `+gamrywb/+util/splitTabs.m` | Extracted using the common tab-run behavior used by most legacy parsers. VT-specific trimming remains local until parser extraction. |
| `nextNonEmpty` | all GUI families | `+gamrywb/+util/nextNonEmpty.m` | Extracted in Phase 1. |
| `isDataLike` | all GUI families | `+gamrywb/+util/isDataLike.m` | Extracted in Phase 1. |
| `csvEscape` | VT resistance | `+gamrywb/+util/csvEscape.m` | Extracted in Phase 1; VT call sites are not changed yet. |
| `parsePositiveScalar` | CIC, CV/CSC | `+gamrywb/+util/parsePositiveScalar.m` | Extracted in Phase 1; analysis call sites are not changed yet. |
| `nearestIndex` | CIC, VT resistance | `+gamrywb/+util/nearestIndex.m` | Extracted in Phase 1; analysis call sites are not changed yet. |
| `median_in_window` | CIC, VT resistance | `+gamrywb/+util/medianInWindow.m` | Extracted in Phase 1 with camel-case package name; analysis call sites are not changed yet. |
| `sanitizeAxisName` / `makeValidName` usage | EIS overlay, multi-DTA overlay | `+gamrywb/+util/sanitizeFieldName.m` | Phase 1 utility maps to `matlab.lang.makeValidName`; EIS-specific axis sanitation remains local until Phase 8. |

## GUI-Local Functions to Keep Local for Now

GUI callbacks, layout builders, drag-resize handlers, dropdown setters, log appenders, table refreshers, plot reset helpers, annotation drawing helpers, and alert handlers remain local until their surrounding GUI modules are migrated.

Examples include `onOpenFiles`, `onOpenFolder`, `refreshPlots`, `refreshBatchTable`, `refreshResultsSummary`, `startDrag`, `doDrag`, `stopDrag`, `disableAxesInteractivity`, `drawDurationBracket`, and GUI-specific annotation functions.

## Scientific Behavior That Must Not Change

- Chrono parsing must preserve T/Vf/Im/Pt column interpretation, invalid row removal, and stable unique-time handling.
- Pulse detection must preserve metadata-first, metadata-only, and current-only behavior where each GUI exposes those modes.
- Blank-gap-centered alignment must preserve fallback-to-first-sample behavior when a pulse gap is unavailable.
- VT resistance must preserve median current/voltage windows, baseline-corrected mode, raw Vf/I mode, and result table columns.
- CIC must preserve Emc/Ema sampling, 10 us default delay, measured-current integration, water-window presets, area handling, safety classification, unit conversion, and batch summary behavior.
- CV/CSC must preserve sign-split charge integration, zero-crossing handling, recorded-time CT charge, scan-rate-derived CV charge, and water-window trim behavior.
- EIS overlay must preserve axis labels, Nyquist/Bode plotting behavior, log checkboxes, legends, and CSV column names.
- Multi-DTA overlay/export must preserve selected X-axis behavior, plot labels, legends, grid behavior, merged aligned-time export axis, interpolation, and CSV column names.

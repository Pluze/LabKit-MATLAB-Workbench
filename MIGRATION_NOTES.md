# Migration Notes

This file records completed migration work, behavior-preservation notes, and known risks.

It is not a roadmap. Planned future phases live in `REFACTOR_ROADMAP.md`.

---

## Current Migration Status

```text
Phase 0: complete
Phase 1: complete
Phase 2: mostly complete
Phase 3: started
Phase 4+: not started
```

Current summary:

- Legacy GUI implementations are preserved under `legacy/`.
- Root-level compatibility wrappers keep original GUI command names available.
- Shared utilities have been added under `+gamrywb/+util`.
- Chrono, EIS, and CV/CT parser extraction has started and is mostly complete.
- Shared pulse detection has started and has been wired into the multi-DTA overlay/export legacy GUI.
- VT resistance and CIC still use their local pulse detection until later Phase 3 work.
- Full scientific analysis extraction has not started.

---

## Phase 0 — Inventory and Safety Baseline

Phase 0 established the refactor safety baseline.

Completed work:

- Identified the five legacy GUI families.
- Documented duplicated helper functions.
- Documented GUI-local functions that should remain local for now.
- Documented scientific behavior that must not change.
- Added this migration notes file.

No source behavior was intentionally changed in Phase 0.

---

## Phase 1 — Package Skeleton and Utilities

Phase 1 created the initial package-backed structure and extracted low-risk utilities.

Completed work:

- Added `startup_gamrywb.m`.
- Added initial `+gamrywb` package folders.
- Moved preserved legacy implementations under `legacy/`.
- Added root-level compatibility wrappers for original command names.
- Added legacy-directory compatibility shims.
- Added low-risk utility helpers under `+gamrywb/+util`.
- Added initial local MATLAB test runner.

Extracted utility helpers include:

| Function | Package location | Notes |
|---|---|---|
| `appendStruct` | `+gamrywb/+util/appendStruct.m` | Shared struct-array append helper. |
| `shortName` | `+gamrywb/+util/shortName.m` | Shared display name helper. |
| `splitTabs` | `+gamrywb/+util/splitTabs.m` | Shared tab-splitting helper for DTA text. |
| `nextNonEmpty` | `+gamrywb/+util/nextNonEmpty.m` | Shared line-scanning helper. |
| `isDataLike` | `+gamrywb/+util/isDataLike.m` | Shared numeric-row detection helper. |
| `csvEscape` | `+gamrywb/+util/csvEscape.m` | Extracted for later export refactors. |
| `parsePositiveScalar` | `+gamrywb/+util/parsePositiveScalar.m` | Extracted for later analysis option parsing. |
| `nearestIndex` | `+gamrywb/+util/nearestIndex.m` | Extracted for later signal indexing. |
| `medianInWindow` | `+gamrywb/+util/medianInWindow.m` | Extracted for later VT/CIC analysis work. |
| `sanitizeFieldName` | `+gamrywb/+util/sanitizeFieldName.m` | Wrapper around valid MATLAB table field naming. |

Phase 1 behavior note:

- Scientific calculations, plotting logic, and CSV export formats were intentionally left unchanged.

---

## Phase 2 — Parser and Data Accessor Extraction

Phase 2 extracted shared DTA parsers and table/column accessors.

Completed work:

- Added `gamrywb.io.parseChronoDTA`.
- Added `gamrywb.io.findDTAFilesRecursive`.
- Added `gamrywb.data.getMainCurve`.
- Added `gamrywb.data.getColumn`.
- Updated only `legacy/gamry_multiDTA_plot_export_gui_legacy.m` to use the extracted chrono parser and data accessors.
- Added `gamrywb.io.parseEISDTA`.
- Added `gamrywb.data.getZCurve`.
- Updated only `legacy/gamry_EIS_multiDTA_plot_gui_legacy.m` to use the extracted EIS parser, shared DTA discovery, shared struct append, shared short file names, and shared column access.
- Added `gamrywb.io.parseCVCTDTA`.
- Updated only `legacy/gamry_CV_CSC_dta_gui_legacy.m` to use the extracted CV/CT parser.

Still local after Phase 2:

- Pulse detection.
- Pulse-gap alignment.
- Plotting.
- CSV export.
- Scientific analysis formulas.

Parser behavior details live in `docs/file_format_notes.md`.

---

## Phase 3 — Pulse Detection Extraction

Phase 3 has started.

Completed work:

- Added `gamrywb.analysis.defaultPulseOptions`.
- Added `gamrywb.analysis.detectPulses`.
- Added `gamrywb.analysis.pulsesFromMetadata`.
- Added `gamrywb.analysis.pulsesFromCurrent`.
- Added `gamrywb.analysis.emptyPulse`.
- Added `gamrywb.data.makeChronoItem`.
- Added `gamrywb.analysis.alignChronoByPulseGap`.
- Updated only `legacy/gamry_multiDTA_plot_export_gui_legacy.m` to use the extracted pulse detection.
- Updated `legacy/gamry_multiDTA_plot_export_gui_legacy.m` to use the shared chrono item constructor and pulse-gap alignment helper.

Current pulse struct note:

- The shared pulse struct currently preserves legacy flat fields such as `cath_start`, `cath_end`, `anod_start`, `anod_end`, `gap_start`, and `gap_end`.
- It also adds normalized nested fields such as `pulse.cath.start_s`, `pulse.anod.start_s`, and `pulse.gap.center_s` for future package-backed analysis work.

Still local after current Phase 3 progress:

- VT resistance pulse detection call sites.
- CIC pulse detection call sites.
- VT resistance and CIC chrono item loading call sites.

Known scope limitation:

- Current pulse detection is legacy-compatible for single cathodic-first biphasic pulse protocols used by the existing GUIs.
- More general multi-cycle, anodic-first, or arbitrary protocol support is not part of the current behavior-preserving refactor.

---

## Legacy Function Inventory

| Function / behavior | Found in files | Package location or plan | Notes |
|---|---|---|---|
| `parseGamryChronoDTA` | CIC, VT resistance, multi-DTA overlay | `+gamrywb/+io/parseChronoDTA.m` | Extracted. Preserve metadata parsing, table parsing, log messages, invalid row handling, and unique-time behavior. |
| EIS `parseGamryDTA` | EIS overlay | `+gamrywb/+io/parseEISDTA.m` | Extracted. Preserve `ZCURVE` detection and arbitrary axis support. |
| CV/CT `parseGamryDTA` | CV/CSC GUI | `+gamrywb/+io/parseCVCTDTA.m` | Extracted. Preserve curve discovery and `SCANRATE` conversion from mV/s to V/s. |
| `getMainCurve` | CIC, VT resistance, multi-DTA overlay | `+gamrywb/+data/getMainCurve.m` | Extracted. Preserve preference for `CURVE`/`CURVE1`, then fallback to T/Vf/Im headers. |
| `getZCurve` | EIS overlay | `+gamrywb/+data/getZCurve.m` | Extracted. Preserve `ZCURVE` first, then Freq/Zreal/Zimag header fallback. |
| `getColByName` | all GUI families | `+gamrywb/+data/getColumn.m` | Extracted as case-insensitive column lookup. |
| `findDTAFilesRecursive` | CIC, VT resistance, EIS overlay, multi-DTA overlay | `+gamrywb/+io/findDTAFilesRecursive.m` | Extracted. Preserve recursive `.DTA`/`.dta` scan behavior. |
| chrono item construction | multi-DTA overlay, VT resistance, CIC | `+gamrywb/+data/makeChronoItem.m` | Partially migrated. Multi-DTA overlay uses shared implementation; VT resistance and CIC still local. |
| `detectPulses` | CIC, VT resistance, multi-DTA overlay | `+gamrywb/+analysis/detectPulses.m` | Partially migrated. Multi-DTA overlay uses shared implementation; VT resistance and CIC still local. |
| `pulsesFromMetadata` | CIC, VT resistance, multi-DTA overlay | `+gamrywb/+analysis/pulsesFromMetadata.m` | Extracted. Preserve ISTEP/TSTEP and VSTEP/TSTEP interpretation. |
| `pulsesFromCurrent` | CIC, VT resistance, multi-DTA overlay | `+gamrywb/+analysis/pulsesFromCurrent.m` | Extracted. Preserve threshold and longest-segment behavior. |
| `emptyPulse` | CIC, VT resistance, multi-DTA overlay | `+gamrywb/+analysis/emptyPulse.m` | Extracted. Includes legacy and normalized fields. |
| pulse-gap alignment | multi-DTA overlay | `+gamrywb/+analysis/alignChronoByPulseGap.m` | Extracted for blank-gap-centered alignment with first-sample fallback. Multi-DTA overlay uses shared implementation. |
| `buildExportTable` | multi-DTA overlay, EIS overlay | future `+gamrywb/+io` export builders | Deferred to Phase 4/8. Preserve CSV headers and interpolation behavior. |
| `valuesForAxis` | EIS overlay | future `+gamrywb/+analysis/valuesForEISAxis.m` | Deferred to Phase 8. Preserve all axis labels and log-axis behavior. |
| CV/CSC integration helpers | CV/CSC GUI | future `+gamrywb/+analysis/computeCSC.m` family | Deferred to Phase 7. Preserve sign-split and scan-rate-derived time behavior. |

---

## GUI-Local Functions to Keep Local for Now

These should remain local until their surrounding GUI modules are migrated:

```text
onOpenFiles
onOpenFolder
refreshPlots
refreshBatchTable
refreshResultsSummary
startDrag
doDrag
stopDrag
disableAxesInteractivity
drawDurationBracket
GUI-specific annotation helpers
uialert wrappers
layout builders
callback wiring
```

General rule:

```text
GUI code may own layout and callbacks.
Package code should own parsing, analysis, plotting helpers, export table construction, and reusable utilities.
```

---

## Scientific Behavior That Must Not Change

Chrono parsing must preserve:

- T/Vf/Im/Pt column interpretation.
- Invalid row removal.
- Stable unique-time handling.
- Metadata parsing for AREA, SAMPLETIME, ISTEP/VSTEP/TSTEP.

Pulse detection must preserve:

- metadata-first behavior.
- metadata-only behavior.
- current-only behavior where exposed by the GUI.
- fallback messages where used by legacy behavior.
- blank-gap-centered alignment.
- fallback-to-first-sample alignment when pulse gap is unavailable.

VT resistance must preserve:

- median current/voltage windows.
- baseline-corrected mode.
- raw Vf/I mode.
- result table columns.

CIC must preserve:

- Emc/Ema sampling.
- 10 us default delay.
- measured-current integration.
- water-window presets.
- area handling.
- safety classification.
- unit conversion.
- batch summary behavior.

CV/CSC must preserve:

- sign-split charge integration.
- zero-crossing handling.
- recorded-time CT charge.
- scan-rate-derived CV charge.
- water-window trim behavior.

EIS overlay must preserve:

- axis labels.
- Nyquist/Bode plotting behavior.
- log checkboxes.
- legends.
- CSV column names.

Multi-DTA overlay/export must preserve:

- selected X-axis behavior.
- plot labels.
- legends.
- grid behavior.
- merged aligned-time export axis.
- interpolation.
- CSV column names.

---

## Open Migration Risks

1. Parser implementations still duplicate some table-reading internals. This is acceptable during behavior-preserving extraction; deeper parser unification should wait until downstream behavior is verified.
2. Shared pulse detection currently targets the legacy single cathodic-first biphasic use case. General protocol support should be treated as a future feature, not a refactor requirement.
3. Existing tests validate extracted pure functions with demo fixtures, but not every legacy GUI output has a golden reference yet.
4. Full analysis extraction for CIC, VT resistance, CV/CSC, and EIS remains future work.
5. Interactive GUI behavior is not covered by the default batch test runner.

---

## Validation References

Validation strategy lives in:

```text
docs/validation_protocol.md
```

File-format assumptions live in:

```text
docs/file_format_notes.md
```

# Refactor Roadmap

This document defines the active behavior-preserving refactor plan for **Gamry Electrochemistry Workbench**.

The goal is not to rewrite the project at once. The goal is to extract common parsing, data models, analysis functions, plotting utilities, and export routines while preserving the behavior of the existing MATLAB GUIs.

---

## 1. Source Legacy Programs

The preserved legacy GUI programs are:

```text
legacy/gamry_CIC_VT_gui_paperlabels_legacy.m
legacy/gamry_VT_resistance_gui_legacy.m
legacy/gamry_CV_CSC_dta_gui_legacy.m
legacy/gamry_EIS_multiDTA_plot_gui_legacy.m
legacy/gamry_multiDTA_plot_export_gui_legacy.m
```

Root-level compatibility wrappers keep the original command names runnable.

| Legacy GUI | Role |
|---|---|
| `gamry_CIC_VT_gui_paperlabels` | CIC / voltage-transient GUI for Gamry `MULTI_STEP_CHRONOPOT` files. |
| `gamry_VT_resistance_gui` | Voltage-transient steady-state resistance GUI. |
| `gamry_CV_CSC_dta_gui` | CV/CT charge integration and CSC GUI. |
| `gamry_EIS_multiDTA_plot_gui` | Multi-file EIS `ZCURVE` overlay/export GUI. |
| `gamry_multiDTA_plot_export_gui` | Multi-file chronopotentiometry VT/IT overlay and aligned CSV export. |

---

## 2. Refactor Philosophy

Convert the current pattern:

```text
Each GUI = DTA parser + data cleaning + analysis + plotting + export + UI state
```

into:

```text
GUI = read UI options + call gamrywb library + display results
```

The reusable package should own:

```text
DTA parsing
common data models
pulse detection
CIC / CSC / resistance / EIS analysis
plot helpers
CSV/session export
small utilities
```

The legacy GUIs remain the reference until each package-backed module is verified.

---

## 3. Non-Negotiable Rules

1. Do not rewrite all GUIs in one pass.
2. Do not change scientific algorithms during structural refactoring.
3. Do not change GUI behavior unless a phase explicitly says so.
4. Keep legacy files runnable until each module has been migrated and verified.
5. Extract pure functions before changing UI architecture.
6. Prefer MATLAB `struct` data models first; avoid premature OOP.
7. Use MATLAB package namespace `+gamrywb`.
8. Avoid global path pollution.
9. Every analysis function must be callable from scripts, tests, and GUIs.
10. Every behavior-preserving refactor should have a reference check.
11. Work on one phase at a time.
12. Do not start the unified workbench GUI before the package library is stable.

Operational instructions for AI agents live in `AGENTS.md`.

---

## 4. Current Status

Current status at the time of this documentation cleanup:

```text
Phase 0: complete
Phase 1: complete
Phase 2: mostly complete
Phase 3: mostly complete
Phase 4: started
Phase 5: started
Phase 6: started
Phase 7: started
Phase 8: complete
Phase 9: complete for current legacy-compatible scope
Phase 10: started
Phase 11+: not started
```

Summary:

- Package skeleton exists under `+gamrywb`.
- Low-risk utilities have been extracted into `+gamrywb/+util`.
- Chrono, EIS, and CV/CT DTA parsers have been extracted.
- Data accessors such as `getMainCurve`, `getZCurve`, and `getColumn` have been extracted.
- Shared pulse detection is used by the multi-DTA overlay/export, VT resistance, and CIC legacy GUIs.
- Chrono overlay plotting and CSV export table construction have started moving into package helpers.
- VT resistance analysis extraction has started.
- CIC / voltage-transient analysis extraction has started.
- VT resistance and CIC now call package-backed analysis functions while preserving legacy GUI display/export behavior.
- CV/CT charge, CSC analysis, selected-column access, and plotting extraction has started.
- EIS item construction, axis-value generation, overlay plotting, and current-plot export table extraction is complete for the legacy EIS overlay GUI.
- Shared session creation, file add/remove, save/load, batch summary helper extraction, CV/CSC result table construction, and legacy GUI session-state migration are complete for the current legacy-compatible scope.
- Phase 10 app entry points exist under `apps/` and currently delegate to behavior-preserved legacy GUIs.

Completed migration details live in `MIGRATION_NOTES.md`.

---

## 5. Target Project Structure

The target structure is:

```text
GamryElectrochemWorkbench/
├── AGENTS.md
├── README.md
├── CHANGELOG.md
├── REFACTOR_ROADMAP.md
├── MIGRATION_NOTES.md
├── startup_gamrywb.m
│
├── legacy/
│   ├── gamry_CIC_VT_gui_paperlabels.m
│   ├── gamry_CIC_VT_gui_paperlabels_legacy.m
│   ├── gamry_VT_resistance_gui.m
│   ├── gamry_VT_resistance_gui_legacy.m
│   ├── gamry_CV_CSC_dta_gui.m
│   ├── gamry_CV_CSC_dta_gui_legacy.m
│   ├── gamry_EIS_multiDTA_plot_gui.m
│   ├── gamry_EIS_multiDTA_plot_gui_legacy.m
│   ├── gamry_multiDTA_plot_export_gui.m
│   └── gamry_multiDTA_plot_export_gui_legacy.m
│
├── apps/
│   └── future thin app entry points
│
├── +gamrywb/
│   ├── +io/
│   ├── +data/
│   ├── +analysis/
│   ├── +plot/
│   ├── +ui/
│   └── +util/
│
├── tests/
├── demo/
├── scripts/
└── docs/
```

Detailed architecture and data model notes live in:

- `docs/architecture.md`
- `docs/data_model.md`
- `docs/file_format_notes.md`
- `docs/validation_protocol.md`

---

## 6. Phase Plan

### Phase 0 — Inventory and Safety Baseline

Goal:

- Map duplicated functions.
- Identify GUI-local functions.
- Identify pure functions safe to extract.
- Document scientific behavior that must not change.

Status: complete.

Expected artifacts:

- `MIGRATION_NOTES.md`
- legacy function inventory
- scientific behavior preservation notes

---

### Phase 1 — Package Skeleton and Low-Risk Utilities

Goal:

- Create package skeleton.
- Move legacy implementations under `legacy/`.
- Add root-level compatibility wrappers.
- Extract low-risk utility helpers.

Representative utilities:

```text
appendStruct
shortName
splitTabs
nextNonEmpty
isDataLike
csvEscape
parsePositiveScalar
nearestIndex
medianInWindow
sanitizeFieldName
```

Status: complete.

Acceptance criteria:

- `startup_gamrywb` works.
- Legacy GUI command names remain runnable.
- No scientific calculations are modified.

---

### Phase 2 — DTA Parsers and Data Accessors

Goal:

- Extract shared DTA parsing and table/column accessors.

Package areas:

```text
+gamrywb/+io/parseChronoDTA.m
+gamrywb/+io/parseEISDTA.m
+gamrywb/+io/parseCVCTDTA.m
+gamrywb/+io/findDTAFilesRecursive.m
+gamrywb/+data/getMainCurve.m
+gamrywb/+data/getZCurve.m
+gamrywb/+data/getColumn.m
```

Status: mostly complete.

Remaining caution:

- Parser internals are still intentionally conservative and legacy-compatible.
- Do not over-generalize the DTA parser until downstream behavior is verified.

Acceptance criteria:

- Parsed numeric arrays match legacy behavior.
- EIS axis dropdown data remains unchanged.
- CV/CT curve dropdown data remains unchanged.
- Multi-DTA overlay still plots the same curves.

---

### Phase 3 — ChronoItem and Pulse Detection

Goal:

- Unify chronopotentiometry file loading, current/voltage cleaning, pulse detection, and pulse-gap alignment.

Package areas:

```text
+gamrywb/+analysis/defaultPulseOptions.m
+gamrywb/+analysis/detectPulses.m
+gamrywb/+analysis/pulsesFromMetadata.m
+gamrywb/+analysis/pulsesFromCurrent.m
+gamrywb/+analysis/emptyPulse.m
+gamrywb/+analysis/alignChronoByPulseGap.m
+gamrywb/+data/makeChronoItem.m
```

Status: mostly complete.

Current implementation note:

- Shared pulse detection keeps legacy flat fields such as `cath_start` and `gap_end` while adding normalized nested fields such as `pulse.cath.start_s` and `pulse.gap.center_s`.
- Shared pulse detection is now used by the multi-DTA overlay/export GUI, VT resistance GUI, and CIC GUI.

Required behavior to preserve:

```text
metadata-first detection
metadata-only detection
current-only fallback detection
ISTEP/TSTEP and VSTEP/TSTEP interpretation
blank-gap-centered alignment
fallback-to-first-sample alignment
```

Migration order:

1. `legacy/gamry_multiDTA_plot_export_gui_legacy.m` — started.
2. `legacy/gamry_VT_resistance_gui_legacy.m` — pulse detection migrated.
3. `legacy/gamry_CIC_VT_gui_paperlabels_legacy.m` — pulse detection migrated.

---

### Phase 4 — VT Overlay / Export Logic

Goal:

- Make the multi-DTA chronopotentiometry overlay/export GUI a thin wrapper around shared library functions.

Package areas:

```text
+gamrywb/+plot/plotChronoVTIT.m
+gamrywb/+io/buildChronoOverlayExportTable.m
+gamrywb/+io/exportTableCSV.m
```

Required behavior to preserve:

```text
multi-file open
recursive folder open
duplicate skipping
VT overlay
IT overlay
selected X axis: Time (s), Time (ms), Sample #
blank-gap-centered alignment
merged aligned-time export axis
interpolation for files with different time grids
CSV column naming
```

Status: started.

Current implementation note:

- `legacy/gamry_multiDTA_plot_export_gui_legacy.m` now uses `gamrywb.plot.plotChronoVTIT` for overlay plotting.
- `legacy/gamry_multiDTA_plot_export_gui_legacy.m` now uses `gamrywb.io.buildChronoOverlayExportTable` and `gamrywb.io.exportTableCSV` for CSV export.

---

### Phase 5 — VT Resistance Analysis

Goal:

- Extract steady-state voltage transient resistance analysis from GUI callbacks.

Package areas:

```text
+gamrywb/+analysis/computeVTResistance.m
+gamrywb/+analysis/estimateBaseline.m
+gamrywb/+analysis/selectSteadyWindow.m
+gamrywb/+io/buildVTResistanceResultsTable.m
+gamrywb/+io/writeVTResistanceResultsCSV.m
+gamrywb/+ui/buildVTResistanceBatchTableData.m
+gamrywb/+plot/plotVTResistanceDebug.m
```

Required behavior to preserve:

```text
metadata-first pulse detection
current fallback option
phase current estimated by median(Im)
steady phase voltage estimated by median(Vf)
full pulse median option
center 60% median option
baseline-corrected dV/I option
raw Vf/I option
cathodic resistance
anodic resistance
average resistance
batch result table columns
```

Status: started.

Current implementation note:

- `legacy/gamry_VT_resistance_gui_legacy.m` now calls `gamrywb.analysis.computeVTResistance`.
- `computeVTResistance` currently returns legacy-compatible fields so existing summary tables, plots, and CSV export remain unchanged.
- VT resistance CSV result table construction and legacy-format CSV writing are provided by `gamrywb.io`.
- The legacy VT batch `uitable` data is provided by `gamrywb.ui.buildVTResistanceBatchTableData`.

---

### Phase 6 — CIC / Voltage Transient Analysis

Goal:

- Extract CIC computation and voltage-transient metrics from `gamry_CIC_VT_gui_paperlabels_legacy.m`.

Package areas:

```text
+gamrywb/+analysis/computeCIC.m
+gamrywb/+analysis/computeVoltageTransientMetrics.m
+gamrywb/+analysis/computeInjectedCharge.m
+gamrywb/+analysis/checkWaterWindowSafety.m
+gamrywb/+plot/plotCICDebug.m
+gamrywb/+io/buildCICResultsTable.m
+gamrywb/+io/writeCICResultsCSV.m
+gamrywb/+ui/buildCICBatchTableData.m
```

Required behavior to preserve:

```text
Pt water window preset: -0.6 to 0.8 V
PEDOT:PSS water window preset: -0.9 to 0.6 V
custom water window behavior
10 us default delay after pulse end
Emc definition
Ema definition
measured current integration option
cathodic Q/CIC
anodic Q/CIC
total Q/CIC
mC/cm^2 and uC/cm^2 display modes
safe/unsafe classification
best safe file among loaded files
batch result table columns
plot markers
window limit lines
pulse window shading
```

Status: started.

Current implementation note:

- `legacy/gamry_CIC_VT_gui_paperlabels_legacy.m` now calls `gamrywb.analysis.computeCIC`.
- `computeCIC` currently returns legacy-compatible fields so existing summary tables, plots, and CSV export remain unchanged.
- CIC CSV result table construction and legacy-format CSV writing are provided by `gamrywb.io`.
- The legacy CIC batch `uitable` data is provided by `gamrywb.ui.buildCICBatchTableData`.
- Legacy GUI file-list management, selected-file handling, `uigetfile`/`uiputfile`, summary text, plotting, and logging remain local.

---

### Phase 7 — CV / CSC Analysis

Goal:

- Extract CV/CT integration and CSC calculation from `gamry_CV_CSC_dta_gui_legacy.m`.

Package areas:

```text
+gamrywb/+analysis/computeCTCharge.m
+gamrywb/+analysis/computeCVCharge.m
+gamrywb/+analysis/computeCSC.m
+gamrywb/+analysis/selectCVCTCurves.m
+gamrywb/+plot/plotCVCT.m
+gamrywb/+io/buildCSCResultsTable.m
```

Required scientific rules:

```text
Cathodic charge: integrate only negative current portion.
Anodic charge: integrate only positive current portion.
Full charge: cathodic + anodic.
CT charge: Qct = integral I dt using recorded time.
CV charge: dt = abs(dV) / scanRate, so Qcv = integral I * (abs(dV) / scanRate).
Do not compute CV charge as trapz(V, I) directly.
CSC = Q / area_cm2 when area is provided.
```

Status: started.

Current implementation note:

- `legacy/gamry_CV_CSC_dta_gui_legacy.m` now calls `gamrywb.analysis.computeCSC`.
- `computeCSC` uses `computeCTCharge` and `computeCVCharge` to preserve the legacy sign-split integration behavior.
- `legacy/gamry_CV_CSC_dta_gui_legacy.m` now uses `gamrywb.data.getCurveXY` and `gamrywb.plot.plotCVCT`.
- The legacy CV/CSC GUI currently has no CSV export path; `buildCSCResultsTable` remains deferred until a batch/session export workflow exists.

---

### Phase 8 — EIS Overlay / Export

Goal:

- Extract EIS axis-value generation, overlay plotting, and CSV export.

Package areas:

```text
+gamrywb/+data/makeEISItem.m
+gamrywb/+analysis/valuesForEISAxis.m
+gamrywb/+plot/plotEISOverlay.m
+gamrywb/+io/buildEISExportTable.m
```

Axis values to preserve:

```text
Freq (Hz)
log10(Freq)
Time (s)
Point #
Zreal (ohm)
Zimag (ohm)
-Zimag (ohm)
Zmod (ohm)
Zphz (deg)
Idc (A)
Vdc (V)
```

Status: complete.

Current implementation note:

- `legacy/gamry_EIS_multiDTA_plot_gui_legacy.m` now calls `gamrywb.data.makeEISItem`.
- EIS axis values are provided by `gamrywb.analysis.valuesForEISAxis`.
- EIS overlay plotting is provided by `gamrywb.plot.plotEISOverlay`.
- Current X/Y plot export tables are provided by `gamrywb.io.buildEISExportTable`.
- Legacy GUI file-list management, selected-file handling, `uigetfile`/`uiputfile`, summary text, and logging remain local.

---

### Phase 9 — Batch Session and Shared Export System

Goal:

- Create common session and export utilities used by all apps.

Package areas:

```text
+gamrywb/+data/makeSession.m
+gamrywb/+data/addFilesToSession.m
+gamrywb/+data/removeFilesFromSession.m
+gamrywb/+io/saveSession.m
+gamrywb/+io/loadSession.m
+gamrywb/+io/exportTableCSV.m
+gamrywb/+analysis/summarizeBatchResults.m
+gamrywb/+ui/buildVTResistanceBatchTableData.m
+gamrywb/+ui/buildCICBatchTableData.m
```

Status: complete for current legacy-compatible scope.

Current implementation note:

- `gamrywb.data.makeSession` creates the common session struct.
- `gamrywb.data.addFilesToSession` and `gamrywb.data.removeFilesFromSession` provide loader-driven add/remove helpers.
- `gamrywb.data.addFilesToSession` supports optional load-event callbacks so legacy GUI log ordering can be preserved during migration.
- `gamrywb.io.saveSession` and `gamrywb.io.loadSession` persist session structs to MAT files.
- `gamrywb.analysis.summarizeBatchResults` creates a common result status table.
- VT resistance result/export table helpers are package-backed while preserving the legacy GUI table shape and CSV format.
- CIC result/export table helpers are package-backed while preserving the legacy GUI table shape, dynamic units, and CSV format.
- CV/CSC result table construction is package-backed for computed CSC results without adding a legacy GUI export workflow.
- The legacy multi-DTA overlay and EIS overlay GUIs now use shared session add/remove helpers while preserving their legacy `S.items` display/export paths.
- The legacy VT resistance GUI now uses shared session add helpers and shared session reset on clear-all while preserving its legacy `S.items` display/export path.
- The legacy CIC GUI now uses shared session add helpers and shared session reset on clear-all while preserving its legacy `S.items` display/export path.
- The legacy CV/CSC GUI now stores its current parsed file and selected curve in a shared session while preserving its legacy `S.filepath`, `S.curves`, `S.scanRate`, and `S.currentCurve` display/analysis path.
- CV/CSC CSV writing and GUI export remain deferred because the legacy CV/CSC GUI has no batch CSV export workflow.

---

### Phase 10 — New Thin Apps

Goal:

- Create new app entry points in `apps/` only after the reusable library is stable.

Planned apps:

```text
apps/gamrywb_CIC_app.m
apps/gamrywb_VTResistance_app.m
apps/gamrywb_CSC_app.m
apps/gamrywb_EIS_app.m
```

Rule:

```text
UI controls → read options → call gamrywb package → update UI
```

No parser, scientific formula, CSV formatting, or pulse-detection logic should live inside the apps.

Status: started.

Current implementation note:

- `apps/gamrywb_CIC_app.m` delegates to `gamry_CIC_VT_gui_paperlabels`.
- `apps/gamrywb_VTResistance_app.m` delegates to `gamry_VT_resistance_gui`.
- `apps/gamrywb_CSC_app.m` delegates to `gamry_CV_CSC_dta_gui`.
- `apps/gamrywb_EIS_app.m` delegates to `gamry_EIS_multiDTA_plot_gui`.
- These app entry points preserve legacy GUI behavior while package-backed thin app internals mature.

---

### Phase 11 — Unified Workbench GUI

Goal:

- Create a unified workbench after the analysis modules and thin apps are stable.

Proposed UI sections:

```text
file/session panel
analysis mode selector
mode-specific settings panel
result summary table
plot area
log panel
```

Important rule:

Do not start this phase until Phases 1–10 pass their acceptance criteria.

Status: not started.

---

## 7. Migration Order Recommendation

Use this order:

```text
1. gamry_multiDTA_plot_export_gui
2. gamry_EIS_multiDTA_plot_gui
3. gamry_VT_resistance_gui
4. gamry_CIC_VT_gui_paperlabels
5. gamry_CV_CSC_dta_gui
6. new thin apps
7. unified workbench app
```

Rationale:

```text
multiDTA overlay is broad but relatively simple.
EIS overlay is isolated and table-driven.
VT resistance shares pulse detection but has simpler output than CIC.
CIC is central and should be migrated after pulse detection is stable.
CV/CSC has special integration rules and should be migrated carefully with tests.
Unified GUI should be last.
```

---

## 8. Definition of Done for v1.0

The refactor reaches v1.0 when:

```text
[ ] Legacy GUIs are preserved in legacy/.
[ ] Common parser functions live in +gamrywb/+io.
[ ] Common data accessors live in +gamrywb/+data.
[ ] Common analysis functions live in +gamrywb/+analysis.
[ ] Common plotting helpers live in +gamrywb/+plot.
[ ] Common UI helpers live in +gamrywb/+ui.
[ ] Common utility functions live in +gamrywb/+util.
[ ] CIC analysis can run without GUI.
[ ] VT resistance analysis can run without GUI.
[ ] CV/CSC analysis can run without GUI.
[ ] EIS overlay/export can run without GUI.
[ ] At least one reference test exists for each major analysis module.
[ ] New thin apps are available in apps/.
[ ] README explains how to run startup_gamrywb and each app.
[ ] MIGRATION_NOTES.md documents behavior differences and open risks.
```

---

## 9. Future Features

Future feature ideas are intentionally separated from the active behavior-preserving refactor.

See:

```text
docs/future_features.md
```

Do not start future-feature work before the reusable MATLAB package reaches v1.0 unless explicitly requested.

---

## 10. Final Reminder

This refactor should protect the scientific value of the existing scripts.

The existing single-file GUIs are working research tools. The first goal is not elegance. The first goal is:

```text
same results
less duplicate code
clearer boundaries
safer future changes
```

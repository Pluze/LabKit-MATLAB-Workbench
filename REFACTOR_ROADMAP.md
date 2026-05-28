# Gamry Electrochemistry Workbench Refactor Roadmap

This document is the task roadmap for refactoring several single-file MATLAB Gamry analysis GUIs into a reusable, maintainable MATLAB software system.

The goal is **not** to rewrite everything at once. The goal is to extract common parsing, data models, analysis functions, plotting utilities, and export routines while preserving the behavior of the existing GUIs.

---

## 0. Source Legacy Programs

The current legacy programs are:

```text
legacy source files
├── gamry_CIC_VT_gui_paperlabels.m
├── gamry_VT_resistance_gui.m
├── gamry_CV_CSC_dta_gui.m
├── gamry_EIS_multiDTA_plot_gui.m
└── gamry_multiDTA_plot_export_gui.m
```

Their current roles are:

| File | Current role |
|---|---|
| `gamry_CIC_VT_gui_paperlabels.m` | CIC / voltage-transient GUI for Gamry `MULTI_STEP_CHRONOPOT` files. Computes Emc/Ema, injected charge, charge density, safety status, and batch summaries. |
| `gamry_VT_resistance_gui.m` | Voltage-transient steady-state resistance GUI. Uses pulse detection, median current/voltage windows, and baseline-corrected resistance. |
| `gamry_CV_CSC_dta_gui.m` | CV/CT charge integration and CSC GUI. Computes CT charge from recorded time and CV charge using scan-rate-derived time. |
| `gamry_EIS_multiDTA_plot_gui.m` | Multi-file EIS `ZCURVE` overlay/export GUI. Supports arbitrary X/Y axes, Nyquist-style plots, Bode-style plots, and CSV export. |
| `gamry_multiDTA_plot_export_gui.m` | Multi-file chronopotentiometry VT/IT overlay and aligned CSV export. Aligns curves around pulse blank-gap center when available. |

---

## 1. Refactor Philosophy

### 1.1 Main objective

Convert the current pattern:

```text
Each GUI = DTA parser + data cleaning + analysis + plotting + export + UI state
```

into:

```text
GUI = read UI options + call gamrywb library + display results
```

The reusable library should own:

```text
DTA parsing
common data models
pulse detection
CIC / CSC / resistance / EIS analysis
plot helpers
CSV/session export
small utilities
```

### 1.2 Non-negotiable rules

1. Do **not** rewrite all GUIs in one pass.
2. Do **not** change scientific algorithms during structural refactoring.
3. Do **not** change GUI behavior unless a phase explicitly says so.
4. Keep legacy files runnable until each module has been migrated and verified.
5. Extract pure functions before changing UI architecture.
6. Prefer MATLAB `struct` data models first; avoid premature OOP.
7. Use MATLAB package namespace `+gamrywb`.
8. Avoid global path pollution.
9. Every analysis function must be callable from scripts, tests, and GUIs.
10. Every behavior-preserving refactor should have a reference check.
11. Preserve a clear local git history throughout the refactor.
12. Commit regularly at stable checkpoints instead of leaving large mixed working-tree changes.
13. Keep commits logically scoped: inventory/docs, package skeleton, utility extraction, parser extraction, analysis extraction, tests, and compatibility fixes should be separate when practical.
14. Run the available MATLAB test command before commits that change executable code; if tests cannot run, record the reason in the commit summary or migration notes.
15. Do not mix unrelated user edits or generated artifacts into refactor commits.

### 1.3 Git workflow requirements

Use the local git history as part of the refactor safety process.

Recommended workflow for each phase:

```text
1. Inspect git status before editing.
2. Make one small logical change set.
3. Run the relevant MATLAB tests or static checks.
4. Review git diff for unrelated changes.
5. Commit with a concise behavior-oriented message.
6. Start the next change set from a clean or intentionally understood working tree.
```

Commit message style:

```text
refactor: create phase 1 package skeleton
test: add MATLAB utility smoke tests
docs: record migration inventory
fix: preserve legacy GUI entrypoint resolution
```

Avoid committing:

```text
matlab_test.log
.DS_Store
temporary exports
experiment output data
```

### 1.4 What counts as success

A phase is successful only if:

```text
old GUI behavior == new package-backed behavior
```

within numerical tolerance for floating-point outputs.

Recommended tolerance:

```matlab
abs(oldValue - newValue) < 1e-9
```

Use a looser tolerance only when interpolation or plotting-only data alignment is involved.

---

## 2. Target Project Structure

Create this structure:

```text
GamryElectrochemWorkbench/
├── REFACTOR_ROADMAP.md
├── startup_gamrywb.m
├── README.md
├── CHANGELOG.md
├── MIGRATION_NOTES.md
│
├── legacy/
│   ├── gamry_CIC_VT_gui_paperlabels.m
│   ├── gamry_VT_resistance_gui.m
│   ├── gamry_CV_CSC_dta_gui.m
│   ├── gamry_EIS_multiDTA_plot_gui.m
│   └── gamry_multiDTA_plot_export_gui.m
│
├── apps/
│   ├── gamrywb_CIC_app.m
│   ├── gamrywb_VTResistance_app.m
│   ├── gamrywb_CSC_app.m
│   ├── gamrywb_EIS_app.m
│   └── gamrywb_Workbench.m
│
├── +gamrywb/
│   ├── +io/
│   │   ├── parseDTA.m
│   │   ├── parseChronoDTA.m
│   │   ├── parseEISDTA.m
│   │   ├── parseCVCTDTA.m
│   │   ├── findDTAFilesRecursive.m
│   │   ├── buildResultsTable.m
│   │   ├── exportTableCSV.m
│   │   ├── saveSession.m
│   │   └── loadSession.m
│   │
│   ├── +data/
│   │   ├── makeSession.m
│   │   ├── addFilesToSession.m
│   │   ├── makeChronoItem.m
│   │   ├── makeEISItem.m
│   │   ├── makeCVItem.m
│   │   ├── getMainCurve.m
│   │   ├── getZCurve.m
│   │   ├── getColumn.m
│   │   ├── validateChronoCurve.m
│   │   ├── validateEISCurve.m
│   │   └── validateCVCurve.m
│   │
│   ├── +analysis/
│   │   ├── defaultPulseOptions.m
│   │   ├── detectPulses.m
│   │   ├── pulsesFromMetadata.m
│   │   ├── pulsesFromCurrent.m
│   │   ├── emptyPulse.m
│   │   ├── alignChronoByPulseGap.m
│   │   ├── computeCIC.m
│   │   ├── computeVoltageTransientMetrics.m
│   │   ├── computeVTResistance.m
│   │   ├── estimateBaseline.m
│   │   ├── computeCTCharge.m
│   │   ├── computeCVCharge.m
│   │   ├── computeCSC.m
│   │   ├── valuesForEISAxis.m
│   │   └── summarizeBatchResults.m
│   │
│   ├── +plot/
│   │   ├── plotChronoVTIT.m
│   │   ├── plotCICDebug.m
│   │   ├── plotVTResistanceDebug.m
│   │   ├── plotCVCT.m
│   │   ├── plotEISOverlay.m
│   │   ├── shadeWindow.m
│   │   ├── annotatePulse.m
│   │   └── resetAxes.m
│   │
│   ├── +ui/
│   │   ├── addLog.m
│   │   ├── updateFileList.m
│   │   ├── updateResultsTable.m
│   │   ├── makeFilePanel.m
│   │   ├── makePlotControls.m
│   │   ├── disableAxesInteractivity.m
│   │   └── showLoadError.m
│   │
│   └── +util/
│       ├── appendStruct.m
│       ├── shortName.m
│       ├── splitTabs.m
│       ├── nextNonEmpty.m
│       ├── isDataLike.m
│       ├── csvEscape.m
│       ├── parsePositiveScalar.m
│       ├── nearestIndex.m
│       ├── medianInWindow.m
│       └── sanitizeFieldName.m
│
├── tests/
│   ├── run_all_tests.m
│   ├── test_parseChronoDTA.m
│   ├── test_detectPulses.m
│   ├── test_computeCIC.m
│   ├── test_computeVTResistance.m
│   ├── test_computeCSC.m
│   ├── test_parseEISDTA.m
│   └── test_exportTables.m
│
├── examples/
│   ├── sample_chrono/
│   ├── sample_cv/
│   └── sample_eis/
│
└── docs/
    ├── architecture.md
    ├── data_model.md
    ├── file_format_notes.md
    └── validation_protocol.md
```

---

## 3. Startup Script

Create `startup_gamrywb.m` in the project root.

It should:

1. Locate the project root using `mfilename("fullpath")`.
2. Add only the project root and necessary app folders to the MATLAB path.
3. Do **not** recursively add every folder unless necessary.
4. Avoid adding `legacy/old`, `.git`, `data`, or temporary folders.

Suggested implementation:

```matlab
function startup_gamrywb()
%STARTUP_GAMRYWB Configure MATLAB path for GamryElectrochemWorkbench.

    root = fileparts(mfilename("fullpath"));

    addpath(root);
    addpath(fullfile(root, "apps"));
    addpath(fullfile(root, "legacy"));

    fprintf("GamryElectrochemWorkbench loaded from:\n  %s\n", root);
end
```

MATLAB package folders under `+gamrywb` are accessible when the project root is on the path.

---

## 4. Data Models

Use `struct` data models first. Do not introduce MATLAB classes until the struct model has stabilized.

### 4.1 ChronoItem

Used for chronopotentiometry / voltage transient files.

```matlab
item = struct();
item.type = "chrono";
item.filepath = filepath;
item.name = filename;
item.meta = meta;
item.tables = tables;
item.curve = curve;
item.t_s = t(:);
item.Vf_V = Vf(:);
item.Im_A = Im(:);
item.pt = pt(:);
item.n = numel(t);
item.pulse = pulse;
item.alignTime_s = NaN;
item.tAligned_s = [];
item.message = "";
item.logmsg = {};
item.analysis = struct();
```

### 4.2 EISItem

Used for EIS `ZCURVE` data.

```matlab
item = struct();
item.type = "eis";
item.filepath = filepath;
item.name = filename;
item.meta = meta;
item.tables = tables;
item.zcurve = zcurve;
item.freq_Hz = freq(:);
item.time_s = time(:);
item.point = point(:);
item.Zreal_ohm = zreal(:);
item.Zimag_ohm = zimag(:);
item.Zmod_ohm = zmod(:);
item.Zphz_deg = zphz(:);
item.Idc_A = idc(:);
item.Vdc_V = vdc(:);
item.message = "";
item.logmsg = {};
item.analysis = struct();
```

### 4.3 CVItem

Used for CV / CT charge integration and CSC.

```matlab
item = struct();
item.type = "cvct";
item.filepath = filepath;
item.name = filename;
item.meta = meta;
item.tables = tables;
item.curves = curves;
item.scanRate_V_s = scanRate;
item.currentCurve = 1;
item.message = "";
item.logmsg = {};
item.analysis = struct();
```

### 4.4 Result models

Each analysis function should return a result struct with:

```matlab
result = struct();
result.ok = true;
result.message = "";
result.options = opts;
result.values = struct();
result.debug = struct();
```

Avoid returning loose numeric arrays from analysis functions.

---

## 5. Phase Plan

---

# Phase 0 — Inventory and Safety Baseline

## Goal

Build a map of duplicated functions and establish behavior-preserving reference outputs before editing scientific logic.

## Codex task

1. Read all 5 legacy files.
2. List nested helper functions in each file.
3. Identify duplicate or near-duplicate functions.
4. Identify GUI-specific functions that should remain local.
5. Identify pure functions that should be extracted.
6. Identify scientific behavior that must not change.
7. Create `MIGRATION_NOTES.md`.

## Expected output

Add a section to `MIGRATION_NOTES.md`:

```markdown
# Migration Notes

## Legacy function inventory

| Function | Found in files | Proposed package location | Notes |
|---|---|---|---|
| parseGamryChronoDTA | ... | +gamrywb/+io/parseChronoDTA.m | Preserve behavior. |
| detectPulses | ... | +gamrywb/+analysis/detectPulses.m | Preserve metadata-first fallback. |
```

## Acceptance criteria

- No source behavior changes.
- No GUI changes.
- All findings are documented.

---

# Phase 1 — Create Package Skeleton and Extract Utilities

## Goal

Create the project structure and extract low-risk utility functions.

## Extract to `+gamrywb/+util/`

```text
appendStruct.m
shortName.m
splitTabs.m
nextNonEmpty.m
isDataLike.m
csvEscape.m
parsePositiveScalar.m
nearestIndex.m
medianInWindow.m
sanitizeFieldName.m
```

Only extract functions that already exist in legacy code or are clearly needed by extracted functions.

## Refactor target

Start with only:

```text
gamry_multiDTA_plot_export_gui.m
```

because it is simpler than the CIC and CV/CSC GUIs but still exercises file loading, DTA parsing, pulse detection, alignment, overlay plotting, and export.

## Rules

1. Move legacy files into `legacy/`.
2. Keep the original function names runnable.
3. Replace local utility calls only where safe.
4. Do not change plot appearance.
5. Do not change CSV export headers.

## Acceptance criteria

- `startup_gamrywb` works.
- `legacy/gamry_multiDTA_plot_export_gui.m` still opens.
- Open file works.
- Open folder recursively works.
- Skip duplicate files behavior is preserved.
- Exported CSV column names are unchanged.
- No scientific calculations are modified.

---

# Phase 2 — Extract DTA Parsers and Data Accessors

## Goal

Move shared DTA parsing and table/column extraction out of GUI files.

## Create

```text
+gamrywb/+io/parseDTA.m
+gamrywb/+io/parseChronoDTA.m
+gamrywb/+io/parseEISDTA.m
+gamrywb/+io/parseCVCTDTA.m
+gamrywb/+io/findDTAFilesRecursive.m
+gamrywb/+data/getMainCurve.m
+gamrywb/+data/getZCurve.m
+gamrywb/+data/getColumn.m
```

## Required behavior

### Chrono parser

Must preserve existing behavior for:

```text
T column
Vf column
Im column
Pt column, if present
metadata parsing
table parsing
log messages
invalid row removal
unique time handling
```

### EIS parser

Must preserve existing behavior for:

```text
ZCURVE detection
Freq
Zreal
Zimag
Zmod
Zphz
Idc
Vdc
arbitrary axis selection support
```

### CV/CT parser

Must preserve existing behavior for:

```text
curve discovery
headers
units
numeric table detection
scan rate extraction
selected curve handling
```

## Refactor targets

After parser extraction, update these files one by one:

```text
1. legacy/gamry_multiDTA_plot_export_gui.m
2. legacy/gamry_EIS_multiDTA_plot_gui.m
3. legacy/gamry_CV_CSC_dta_gui.m
```

Do not update CIC or VT resistance until pulse detection is extracted.

## Acceptance criteria

- For the same input files, parsed numeric arrays match legacy behavior.
- EIS axis dropdown results remain unchanged.
- CV/CT curve dropdown behavior remains unchanged.
- MultiDTA overlay still plots the same curves.

---

# Phase 3 — Extract ChronoItem and Pulse Detection

## Goal

Unify chronopotentiometry file loading, current/voltage data cleaning, pulse detection, and pulse-gap alignment.

## Create

```text
+gamrywb/+data/makeChronoItem.m
+gamrywb/+analysis/defaultPulseOptions.m
+gamrywb/+analysis/detectPulses.m
+gamrywb/+analysis/pulsesFromMetadata.m
+gamrywb/+analysis/pulsesFromCurrent.m
+gamrywb/+analysis/emptyPulse.m
+gamrywb/+analysis/alignChronoByPulseGap.m
```

## Pulse detection API

Suggested API:

```matlab
opts = gamrywb.analysis.defaultPulseOptions();
opts.mode = "metadata_first";  % "metadata_first", "metadata_only", or "current_only"

[pulse, msg] = gamrywb.analysis.detectPulses(item.t_s, item.Im_A, item.meta, opts);
```

## Pulse struct

Use a normalized pulse struct:

```matlab
pulse = struct();
pulse.ok = false;
pulse.method = "";
pulse.message = "";

pulse.cath.start_s = NaN;
pulse.cath.end_s = NaN;
pulse.cath.current_A = NaN;

pulse.anod.start_s = NaN;
pulse.anod.end_s = NaN;
pulse.anod.current_A = NaN;

pulse.gap.start_s = NaN;
pulse.gap.end_s = NaN;
pulse.gap.center_s = NaN;
```

## Required behavior

Preserve:

```text
metadata-first detection
metadata-only detection
current-only fallback detection
ISTEP/TSTEP interpretation
pulse gap detection
blank-gap-centered alignment
fallback-to-first-sample alignment when pulse gap is unavailable
```

## Refactor targets

```text
1. legacy/gamry_multiDTA_plot_export_gui.m
2. legacy/gamry_VT_resistance_gui.m
3. legacy/gamry_CIC_VT_gui_paperlabels.m
```

## Acceptance criteria

- Pulse detection messages remain equivalent.
- Pulse start/end times match legacy values.
- Aligned time vectors match legacy values.
- Existing GUI debug markers and shaded windows still point to the same locations.

---

# Phase 4 — Extract VT Overlay / Export Logic

## Goal

Make the multi-DTA chronopotentiometry overlay/export GUI a thin wrapper around shared library functions.

## Create

```text
+gamrywb/+plot/plotChronoVTIT.m
+gamrywb/+io/buildChronoOverlayExportTable.m
+gamrywb/+io/exportTableCSV.m
```

## Required behavior

Preserve:

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

## Refactor target

```text
legacy/gamry_multiDTA_plot_export_gui.m
```

## Acceptance criteria

- Exported CSV is identical or numerically equivalent to legacy output.
- Plot axis labels and titles remain unchanged.
- Legend behavior remains unchanged.
- Grid and line width behavior remain unchanged.

---

# Phase 5 — Extract VT Resistance Analysis

## Goal

Extract steady-state voltage transient resistance analysis from GUI callbacks.

## Create

```text
+gamrywb/+analysis/computeVTResistance.m
+gamrywb/+analysis/estimateBaseline.m
+gamrywb/+analysis/selectSteadyWindow.m
+gamrywb/+plot/plotVTResistanceDebug.m
```

## Analysis API

Suggested API:

```matlab
opts = struct();
opts.pulseMode = "metadata_first";
opts.steadyWindow = "full_pulse_median";  % or "center_60_percent_median"
opts.voltageMode = "baseline_corrected";  % or "raw_vf_over_i"

result = gamrywb.analysis.computeVTResistance(item, opts);
```

## Required behavior

Preserve:

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

## Refactor target

```text
legacy/gamry_VT_resistance_gui.m
```

## Acceptance criteria

For the same file and UI options, the following must match legacy output:

```text
Ic(A)
Ia(A)
Vc_ss(V)
Va_ss(V)
cathodic baseline
anodic baseline
R_cath(ohm)
R_anod(ohm)
R_avg(ohm)
detection mode/message
```

---

# Phase 6 — Extract CIC / Voltage Transient Analysis

## Goal

Extract CIC computation and voltage transient metrics from `gamry_CIC_VT_gui_paperlabels.m`.

## Create

```text
+gamrywb/+analysis/computeCIC.m
+gamrywb/+analysis/computeVoltageTransientMetrics.m
+gamrywb/+analysis/computeInjectedCharge.m
+gamrywb/+analysis/checkWaterWindowSafety.m
+gamrywb/+plot/plotCICDebug.m
+gamrywb/+io/buildCICResultsTable.m
```

## Analysis API

Suggested API:

```matlab
opts = struct();
opts.cathLimit_V = -0.6;
opts.anodLimit_V = 0.8;
opts.delay_s = 10e-6;
opts.area_cm2 = 2.01;
opts.pulseMode = "metadata_first";
opts.summaryMode = "total_biphasic";  % "cathodic", "anodic", "total_biphasic"
opts.useMeasuredCurrent = true;

result = gamrywb.analysis.computeCIC(item, opts);
```

## Required behavior

Preserve:

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

## Refactor target

```text
legacy/gamry_CIC_VT_gui_paperlabels.m
```

## Acceptance criteria

For the same file and UI options, these must match legacy output:

```text
Emc(V)
Ema(V)
Qc
Qa
Qtot
CIC unit conversion
safe/unsafe status
best safe file among loaded
batch table values
CSV export values
```

---

# Phase 7 — Extract CV / CSC Analysis

## Goal

Extract CV/CT integration and CSC calculation from `gamry_CV_CSC_dta_gui.m`.

## Create

```text
+gamrywb/+analysis/computeCTCharge.m
+gamrywb/+analysis/computeCVCharge.m
+gamrywb/+analysis/computeCSC.m
+gamrywb/+analysis/selectCVCTCurves.m
+gamrywb/+plot/plotCVCT.m
+gamrywb/+io/buildCSCResultsTable.m
```

## Required scientific rules

Preserve the existing integration rules:

```text
Cathodic charge: integrate only negative current portion.
Anodic charge: integrate only positive current portion.
Full charge: cathodic + anodic.
CT charge: Qct = integral I dt using recorded time.
CV charge: dt = abs(dV) / scanRate, so Qcv = integral I * (abs(dV) / scanRate).
Do not compute CV charge as trapz(V, I) directly.
CSC = Q / area_cm2 when area is provided.
```

## Analysis API

Suggested API:

```matlab
opts = struct();
opts.mode = "full";  % "full", "cathodic", "anodic"
opts.area_cm2 = 2.01;
opts.scanRate_V_s = item.scanRate_V_s;

result = gamrywb.analysis.computeCSC(item, opts);
```

## Refactor target

```text
legacy/gamry_CV_CSC_dta_gui.m
```

## Acceptance criteria

For the same file and UI options, these must match legacy output:

```text
CT charge
CV charge
CT CSC
CV CSC
difference
relative difference
max |dt - |dV|/v|
status message
plot trim behavior
```

---

# Phase 8 — Extract EIS Overlay / Export

## Goal

Extract EIS parsing, axis-value generation, overlay plotting, and CSV export.

## Create

```text
+gamrywb/+data/makeEISItem.m
+gamrywb/+analysis/valuesForEISAxis.m
+gamrywb/+plot/plotEISOverlay.m
+gamrywb/+io/buildEISExportTable.m
```

## Axis values to preserve

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

## Refactor target

```text
legacy/gamry_EIS_multiDTA_plot_gui.m
```

## Acceptance criteria

- Nyquist plot behavior remains unchanged.
- Bode-style plot behavior remains unchanged.
- Log X and Log Y checkbox behavior remains unchanged.
- Marker, line width, marker size, legend, and grid behavior remain unchanged.
- CSV export column names and numeric values remain equivalent.

---

# Phase 9 — Batch Session and Shared Export System

## Goal

Create a common session object and export utilities used by all apps.

## Create

```text
+gamrywb/+data/makeSession.m
+gamrywb/+data/addFilesToSession.m
+gamrywb/+data/removeFilesFromSession.m
+gamrywb/+io/saveSession.m
+gamrywb/+io/loadSession.m
+gamrywb/+io/exportTableCSV.m
+gamrywb/+analysis/summarizeBatchResults.m
```

## Session model

```matlab
session = struct();
session.type = "gamrywb_session";
session.createdAt = datetime("now");
session.modifiedAt = datetime("now");
session.items = struct([]);
session.results = struct([]);
session.options = struct();
session.notes = "";
```

## Required behavior

- Any analysis app can save and load a session.
- Session files should include raw parsed data, options, and results.
- CSV export should remain available for publication/data sharing.
- Do not use `pickle`-style opaque state. Keep fields explicit.

---

# Phase 10 — New Thin Apps

## Goal

After library extraction, create new app entry points in `apps/`.

## New apps

```text
apps/gamrywb_CIC_app.m
apps/gamrywb_VTResistance_app.m
apps/gamrywb_CSC_app.m
apps/gamrywb_EIS_app.m
```

Each app should be a thin wrapper:

```text
UI controls
→ read options
→ load item/session
→ call gamrywb.analysis.*
→ call gamrywb.plot.*
→ update tables/text fields
```

## Rules

1. No parser code inside apps.
2. No scientific formula code inside apps.
3. No CSV formatting code inside apps.
4. No pulse-detection logic inside apps.
5. Apps may contain layout and callback wiring only.

## Acceptance criteria

- Each new app reproduces the corresponding legacy GUI result.
- Legacy GUI remains available until new app is verified.
- New apps can share common UI utilities.

---

# Phase 11 — Unified Workbench GUI

## Goal

Create a unified workbench only after the analysis modules are stable.

## Proposed UI structure

```text
Gamry Workbench
├── File/session panel
├── Analysis mode selector
│   ├── Chrono Overlay
│   ├── CIC / Voltage Transient
│   ├── VT Resistance
│   ├── CV / CSC
│   └── EIS Overlay
├── Mode-specific settings panel
├── Result summary table
├── Plot area
└── Log panel
```

## Important rule

Do not start this phase until Phases 1–10 pass their acceptance criteria.

A unified GUI before library extraction will create a larger monolithic GUI and make the project worse.

---

## 6. Testing Strategy

### 6.1 Golden reference files

Choose representative files:

```text
examples/sample_chrono/one_clear_metadata_pulse.DTA
examples/sample_chrono/one_current_fallback_pulse.DTA
examples/sample_chrono/multiple_amplitudes_for_CIC.DTA
examples/sample_cv/one_CV_CT_file.DTA
examples/sample_eis/one_EIS_ZCURVE_file.DTA
```

If real data cannot be committed, use a local `private_examples/` folder excluded from git.

### 6.2 Required reference outputs

Save expected outputs as `.mat` or `.csv` files:

```text
tests/reference/cic_expected.mat
tests/reference/vt_resistance_expected.mat
tests/reference/csc_expected.mat
tests/reference/eis_expected.mat
```

### 6.3 Test runner

Create:

```matlab
% tests/run_all_tests.m
startup_gamrywb;

results = runtests("tests");
disp(table(results));
assert(all([results.Passed]), "Some tests failed.");
```

### 6.4 Minimum tests

#### `test_parseChronoDTA.m`

Must verify:

```text
T/Vf/Im arrays exist
NaN rows are removed
time values are unique
metadata is parsed
main curve is detected
```

#### `test_detectPulses.m`

Must verify:

```text
metadata-first mode
metadata-only mode
current-only mode
fallback behavior
pulse gap center
```

#### `test_computeCIC.m`

Must verify:

```text
Emc
Ema
Qc
Qa
Qtot
CIC normalization
safe/unsafe status
```

#### `test_computeVTResistance.m`

Must verify:

```text
phase current median
steady voltage median
baseline estimate
baseline-corrected resistance
raw voltage resistance mode
```

#### `test_computeCSC.m`

Must verify:

```text
negative current integration
positive current integration
full charge
CT recorded-time charge
CV scan-rate-derived-time charge
CSC normalization
relative difference
```

#### `test_parseEISDTA.m`

Must verify:

```text
ZCURVE extraction
Freq
Zreal
Zimag
-Zimag
Zmod
Zphz
axis-value generation
```

---

## 7. Coding Standards

### 7.1 Function style

Use explicit input/output functions:

```matlab
function result = computeCIC(item, opts)
```

Avoid hidden dependencies on GUI state.

Do not write analysis functions that directly read from `uieditfield`, `uidropdown`, or `uitable`.

### 7.2 Options style

Use option structs:

```matlab
opts = struct();
opts.area_cm2 = 2.01;
opts.delay_s = 10e-6;
opts.pulseMode = "metadata_first";
```

Avoid many positional arguments:

```matlab
% Avoid this style:
computeCIC(t, Vf, Im, area, delay, cathLimit, anodLimit, mode)
```

### 7.3 Units

Include units in field names:

```matlab
t_s
Vf_V
Im_A
area_cm2
charge_C
charge_mC_cm2
charge_uC_cm2
resistance_ohm
freq_Hz
```

### 7.4 GUI callbacks

GUI callbacks should be short:

```matlab
function onAnalyzeButtonPushed(~, ~)
    opts = readOptionsFromUI();
    result = gamrywb.analysis.computeCIC(S.items(S.current), opts);
    S.items(S.current).analysis.cic = result;
    updateUIFromResult(result);
end
```

Avoid 200-line callbacks.

### 7.5 Error handling

Analysis functions should not call `uialert`.

Instead return:

```matlab
result.ok = false;
result.message = "Not enough valid T/Vf/Im points.";
```

GUI code decides how to display the error.

### 7.6 Logging

Library functions may return `logmsg` cell arrays.

GUI functions can display them in log panels.

Do not make library functions write directly into GUI text areas.

---

## 8. Codex Operating Instructions

When Codex works on this project, follow these rules:

1. Read this roadmap first.
2. Work on one phase at a time.
3. Before editing, state which files will be changed.
4. Do not modify scientific algorithms without explicit permission.
5. Keep legacy GUIs runnable.
6. Prefer small behavior-preserving commits.
7. After each phase, update `MIGRATION_NOTES.md`.
8. Add or update tests where possible.
9. If behavior is ambiguous, preserve legacy behavior.
10. If two legacy files implement similar functions differently, document the difference before merging.

---

## 9. Suggested Codex Prompts

### 9.1 Initial audit prompt

```text
Read REFACTOR_ROADMAP.md and the five legacy MATLAB GUI files. Do not modify files yet.

Produce:
1. A function inventory table.
2. A duplicate-function map.
3. A list of pure functions safe to extract.
4. A list of GUI-specific functions that should remain local.
5. A proposed Phase 1 edit plan.
6. Risks where two legacy files implement similar logic differently.
```

### 9.2 Phase 1 prompt

```text
Implement Phase 1 from REFACTOR_ROADMAP.md.

Create the package skeleton and extract only low-risk utility functions into +gamrywb/+util.

Refactor only legacy/gamry_multiDTA_plot_export_gui.m to call the extracted utilities where safe.

Do not change GUI layout, plot appearance, export headers, or scientific calculations.

Update MIGRATION_NOTES.md with all moved functions and any behavior assumptions.
```

### 9.3 Phase 2 prompt

```text
Implement Phase 2 from REFACTOR_ROADMAP.md.

Extract DTA parsing and data accessors into +gamrywb/+io and +gamrywb/+data.

Start by migrating parser calls in legacy/gamry_multiDTA_plot_export_gui.m only. After that works, migrate legacy/gamry_EIS_multiDTA_plot_gui.m.

Do not change analysis formulas, GUI layout, or export behavior.

Add a small parser validation test if sample DTA files are available.
```

### 9.4 Phase 3 prompt

```text
Implement Phase 3 from REFACTOR_ROADMAP.md.

Extract ChronoItem creation, pulse detection, and pulse-gap alignment.

Preserve metadata-first, metadata-only, and current-only modes exactly as in the legacy GUIs.

Refactor legacy/gamry_multiDTA_plot_export_gui.m and legacy/gamry_VT_resistance_gui.m to call the shared pulse detection functions.

Do not modify CIC analysis yet.
```

### 9.5 Behavior check prompt

```text
Compare the old local implementation and the new package implementation for the current phase.

For each changed function, report:
1. Inputs tested.
2. Outputs compared.
3. Numeric tolerance used.
4. Whether results are identical/equivalent.
5. Any behavior differences.

Do not proceed to the next phase until differences are either fixed or documented.
```

---

## 10. Migration Order Recommendation

Use this order:

```text
1. gamry_multiDTA_plot_export_gui.m
2. gamry_EIS_multiDTA_plot_gui.m
3. gamry_VT_resistance_gui.m
4. gamry_CIC_VT_gui_paperlabels.m
5. gamry_CV_CSC_dta_gui.m
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

## 11. Definition of Done for v1.0

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
[ ] MIGRATION_NOTES.md documents all behavior differences.
```

---

## 12. Long-Term Direction

After v1.0, consider:

```text
1. MATLAB Project .prj support.
2. App Designer version of the unified workbench.
3. Session save/load with explicit metadata.
4. Batch report generation.
5. Publication-quality figure export.
6. Plugin-like support for new Gamry experiment types.
7. Optional Python migration of pure analysis modules after MATLAB behavior is stable.
8. Optional MATLAB Compiler packaging for lab-internal distribution.
```

Do not prioritize these until the reusable MATLAB package is stable.

---

## 13. Final Reminder

This refactor should protect the scientific value of the existing scripts.

The existing single-file GUIs are working research tools. The first goal is not elegance. The first goal is:

```text
same results
less duplicate code
clearer boundaries
safer future changes
```

Only after that should the project pursue a unified polished workbench GUI.

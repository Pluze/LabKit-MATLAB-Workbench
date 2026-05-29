# Architecture Notes

This document describes the current architecture and intended boundaries for Gamry Electrochemistry Workbench.

The current refactor is behavior-preserving. Architecture cleanup should reduce duplication while keeping legacy outputs, GUI behavior, plot behavior, and CSV export behavior unchanged.

---

## 1. Core Architecture Principle

The target architecture is:

```text
thin GUI layer
    ↓
struct-based item/session models
    ↓
reusable +gamrywb package functions
```

The project moved away from the legacy pattern:

```text
Each GUI = parser + data cleaning + analysis + plotting + export + UI state
```

and toward:

```text
GUI = read user options + call package functions + display results
```

---

## 2. Layer Responsibilities

### 2.1 Compatibility entry points

Root-level files such as:

```text
gamry_multiDTA_plot_export_gui.m
gamry_EIS_multiDTA_plot_gui.m
gamry_CV_CSC_dta_gui.m
gamry_VT_resistance_gui.m
gamry_CIC_VT_gui_paperlabels.m
```

exist to preserve the original MATLAB command names.

They should remain thin wrappers that forward to preserved implementations under `legacy/`.

### 2.2 Legacy GUI layer

Files under `legacy/` contain preserved GUI implementations and compatibility shims.

During migration, legacy GUI files may be updated to call package functions, but they should not be rewritten as new apps until the reusable package is stable.

Allowed in legacy GUI files:

- layout construction
- UI controls
- callbacks
- listbox/table updates
- manual GUI logging
- `uialert` and other UI display behavior
- compatibility wiring to package functions

Avoid adding new scientific formulas or new parser variants inside legacy GUI files.

### 2.3 Package library layer

Reusable functions live under `+gamrywb`.

Package responsibilities:

```text
+gamrywb/+io        file parsing, folder discovery, export table construction, session IO
+gamrywb/+data      item/session construction, table/column access, validation helpers
+gamrywb/+analysis  pulse detection and scientific analysis functions
+gamrywb/+plot      reusable plotting helpers and annotations
+gamrywb/+ui        reusable UI utilities that are not specific to one app
+gamrywb/+util      small generic helpers
```

Package functions should not depend on GUI state.

### 2.4 Tests

Tests under `tests/` should exercise pure functions, not interactive GUI behavior.

The default test runner should avoid opening `uifigure`, `uigetfile`, or `uialert` in batch mode.

---

## 3. Data Flow

The intended long-term data flow is:

```text
DTA file
  ↓
+gamrywb.io parser
  ↓
+gamrywb.data item struct
  ↓
+gamrywb.analysis result struct
  ↓
+gamrywb.plot / +gamrywb.io export helpers
  ↓
GUI display, CSV export, or saved session
```

For example:

```text
chrono DTA
  ↓ parseChronoDTA
ChronoItem
  ↓ detectPulses / computeCIC / computeVTResistance
result struct
  ↓ plot/debug/export
GUI table and plots
```

```text
CV/CT DTA
  ↓ parseCVCTDTA
curve struct + scan rate
  ↓ computeCSC
result struct
  ↓ plotCVCT / GUI fields and trim overlays
```

```text
EIS DTA
  ↓ parseEISDTA
EIS item
  ↓ valuesForEISAxis / plotEISOverlay / buildEISExportTable
plot/export data
  ↓ GUI display or CSV export
```

```text
loaded item structs
  ↓ makeSession / addFilesToSession / removeFilesFromSession
session struct
  ↓ saveSession / loadSession / summarizeBatchResults
GUI state, saved MAT session, or batch summary table
```

---

## 4. What Belongs in GUI Code

GUI code may contain:

- layout definitions
- callbacks
- reading values from `uieditfield`, `uidropdown`, and `uitable`
- mapping UI values to option structs
- passing item structs to package functions
- displaying result structs
- user alerts and log-panel updates

GUI code should not contain:

- DTA parser logic
- table parser logic
- scientific formulas
- pulse detection logic
- CSV formatting logic
- reusable data-cleaning logic

---

## 5. What Belongs in Package Code

Package code should contain:

- explicit input/output functions
- struct-based item and result models
- parser logic
- analysis logic
- plotting helpers that accept axes and data
- export table builders
- shared validation helpers

Package functions should return useful status information instead of directly displaying UI errors.

Preferred error style for analysis functions:

```matlab
result.ok = false;
result.message = "Not enough valid T/Vf/Im points.";
```

The GUI decides whether to show a log message, table field, or `uialert`.

---

## 6. Current Architecture Status

Current implementation status:

- Root-level compatibility wrappers exist.
- Legacy GUI implementations are preserved under `legacy/`.
- `+gamrywb/+util` exists and contains shared low-risk helpers.
- `+gamrywb/+io` contains chrono, EIS, and CV/CT parsers, chrono/EIS/VT/CIC/CV-CSC result table builders, VT/CIC legacy-format CSV writers, and session save/load helpers.
- `+gamrywb/+data` contains table/column accessors, CV/CT selected-column access, chrono item construction, EIS item construction, and shared session helpers.
- `+gamrywb/+analysis` contains pulse detection helpers, pulse-gap alignment, VT resistance analysis, CIC analysis, CV/CSC analysis, EIS axis-value generation, and batch summary helpers.
- `+gamrywb/+plot` contains the chrono VT/IT overlay plot helper, CV/CT selected-column plot helper, and EIS overlay plot helper.
- `+gamrywb/+ui` contains VT resistance and CIC batch table display-data helpers.
- The legacy multi-DTA overlay, EIS overlay, VT resistance, CIC, and CV/CSC GUIs use shared session helpers while preserving their legacy display/export or display/analysis state surfaces.
- Phase 10 app entry points exist under `apps/` and delegate to the behavior-preserved legacy GUIs.
- Replacing those delegates with package-backed thin app internals is blocked until the DTA parser layer, normalized item/result/option schemas, session/export workflow, and fixture-driven validation are stable.
- Unified workbench GUI has not started.

---

## 7. Architectural Anti-Patterns to Avoid

Avoid these patterns:

```text
one larger monolithic unified GUI before package extraction
analysis functions reading directly from UI controls
package functions writing directly into GUI text areas
DTA parser copies in every GUI
CSV export logic duplicated in every GUI
struct fields without units for scientific values
MATLAB classes before struct models stabilize
```

---

## 8. Current Abstraction Audit

The current package extraction is intentionally conservative. Most helpers are small function-level extractions, and the project has not introduced a new class hierarchy, controller framework, plugin framework, or generic GUI framework. That is appropriate for the current behavior-preserving phase.

Current abstractions that fit the project:

- low-risk utilities in `+gamrywb/+util` are narrow and stable enough to share.
- parser entry points are experiment-family specific, which preserves legacy behavior while fixtures are still limited.
- analysis helpers such as VT resistance, CIC, CV/CSC, and EIS axis-value generation are pure enough for tests and non-GUI workflows.
- app-specific result table, CSV, UI-table, and plot helpers are acceptable because their job is to preserve legacy-visible formats and layout behavior.
- Phase 10 app entry points are compatibility delegates; this is a safe compatibility layer, not a claim that thin app internals are complete.

Current abstractions that should stay provisional:

- chrono and EIS item structs currently carry both legacy field names and unit-explicit package fields. This is useful during migration, but future apps should depend on a documented normalized item schema rather than both field families.
- analysis result structs currently expose legacy-compatible fields. Before building new app internals, define which result fields are stable schema and which are legacy bridge fields.
- local helper duplication inside export/UI builders, such as item-name and analysis-message accessors, is acceptable for now. Do not extract a generic table-builder layer until the legacy output contracts and future export conventions are both clear.
- parser table-reading code is duplicated across chrono, EIS, and CV/CT parsers. This is under-abstracted by design; deeper parser unification should wait for a generic DTA document model and fixture coverage across additional file types.

Near-term design need:

- stabilize a DTA document layer, normalized item/result/option schemas, and session/export workflow conventions before replacing Phase 10 delegates or starting Phase 11.

---

## 9. Future Architecture Direction

Future work may add:

- MATLAB Project `.prj` support.
- New App Designer wrapper around the stable package library.
- Expanded session workflow and reporting support.
- Batch report generation.
- Optional MATLAB Compiler packaging for internal lab distribution.

These should not be prioritized until the DTA core schemas, parser responsibilities, session/export conventions, and validation fixtures are stable enough for new app internals.

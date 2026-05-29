# Architecture Notes

This document describes the intended architecture for Gamry Electrochemistry Workbench.

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

The project should move away from the legacy pattern:

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

Planned package responsibilities:

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
- `+gamrywb/+io` contains initial chrono, EIS, and CV/CT parsers plus chrono/EIS export table builders.
- `+gamrywb/+data` contains initial table/column accessors, CV/CT selected-column access, chrono item construction, and EIS item construction.
- `+gamrywb/+analysis` contains initial pulse detection helpers, pulse-gap alignment, VT resistance analysis, CIC analysis, CV/CSC analysis, and EIS axis-value generation.
- `+gamrywb/+plot` contains the initial chrono VT/IT overlay plot helper, CV/CT selected-column plot helper, and EIS overlay plot helper.
- `+gamrywb/+ui` is a future package area.
- New thin apps and unified workbench GUI have not started.

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

## 8. Future Architecture Direction

After v1.0, the project may add:

- MATLAB Project `.prj` support.
- New App Designer wrapper around the stable package library.
- Session save/load support.
- Batch report generation.
- Optional MATLAB Compiler packaging for internal lab distribution.

These should not be prioritized before the behavior-preserving package refactor is complete.

# Architecture Notes

This document describes the current package boundaries and compatibility layers. It is not a roadmap.

## Core Shape

```text
app entry points
    ↓
package-backed app internals
    ↓
struct-based item/session models
    ↓
+gamrywb package functions
```

The package owns reusable app/session orchestration, parsing, data access, analysis, plotting helpers, export helpers, session helpers, and small utilities. Public files under `apps/` stay as entry points; app assembly can live under `+gamrywb/+app`.

## Entrypoints

The supported runtime entry points are:

```text
gamrywb_CIC_app
gamrywb_VTResistance_app
gamrywb_CSC_app
gamrywb_EIS_app
gamrywb_ChronoOverlay_app
```

The app files are package-backed and do not delegate to legacy GUI files.

`startup_gamrywb` adds the repository root and `apps/` to the MATLAB path. Root-level original command wrappers and the old `legacy/` GUI directory have been removed, so the old command names no longer resolve by default.

## Package Responsibilities

```text
+gamrywb/+app       app/session orchestration helpers
+gamrywb/+dta       GUI-free DTA type detection and loading facade
+gamrywb/+io        DTA parsers, folder discovery, export table construction, session IO
+gamrywb/+data      item/session construction and table/column access
+gamrywb/+analysis  pulse detection and scientific analysis
+gamrywb/+plot      reusable plot helpers that accept axes and data
+gamrywb/+ui        reusable UI display-data helpers and small UI construction helpers
+gamrywb/+util      small generic helpers
```

## Three-Layer Map

The reusable library should be understandable as three layers, even though MATLAB package folders remain practical and granular:

```text
Layer 1: GUI reuse framework
  +gamrywb/+ui
  reusable shells, panels, controls, display-data helpers, and handle-scoped UI utilities

Layer 2: DTA parsing/loading driver
  +gamrywb/+dta
  +gamrywb/+io parser functions
  +gamrywb/+data item/session construction and table/column access

Layer 3: experiment-specific app design
  +gamrywb/+app launch functions
  +gamrywb/+analysis
  +gamrywb/+plot
  export builders in +gamrywb/+io
```

This map is a design boundary, not a reason to force every function into exactly three folders. Keep granular packages when they make code easier to inspect. Refactor or remove helpers when they obscure which layer owns a decision.

Analysis, data, and IO package functions should not depend on GUI state or call `uialert`. Plot/UI helpers may accept explicit graphics handles and should keep side effects limited to those handles.

Analysis functions should return status through result structs, for example:

```matlab
result.ok = false;
result.message = "Not enough valid T/Vf/Im points.";
```

The GUI decides how to display that status.

## Current Package Surface

- `+app`: Chrono/EIS/VT resistance/CIC/CSC app launch assembly and shared app/session orchestration helpers such as duplicate-aware file loading, selected-item lookup, selected-item removal, single-file selection refresh, and single-file clear-all reset.
- `+dta`: GUI-free facade for supported DTA family detection, single-file loading, and batch loading with status/report structs. It delegates to existing `+io` parser and `+data` item-construction helpers.
- `+io`: chrono, EIS, and CV/CT parsers; chrono/EIS/VT/CIC/CV-CSC result table builders; VT/CIC legacy-format CSV writers; session save/load.
- `+data`: table/column accessors, CV/CT selected-column access, chrono item construction, EIS item construction, session add/remove helpers.
- `+analysis`: pulse detection, pulse-gap alignment, VT resistance, CIC, CV/CSC, EIS axis-value generation, batch summaries.
- `+plot`: chrono VT/IT overlay, CV/CT selected-column plotting, EIS overlay plotting.
- `+ui`: VT resistance and CIC batch table display data; shared app axes creation/reset, log append and log panel, multi-select and single-select file-listbox refresh, multi-file and single-select file-panel, summary row, result table panel, info/log text-area, plot-options panel, simple labeled-control, two-pane shell, tabbed dual-plot shell, and top/bottom plot-control construction/state helpers.
- `+util`: low-risk helpers used by parser, data, analysis, and export code.

## Boundaries To Preserve

Avoid:

- analysis functions reading UI controls
- package functions writing directly to GUI text areas
- new parser copies in GUI files
- duplicated CSV formatting in GUI files
- MATLAB classes before struct schemas stabilize
- starting a unified GUI before package-backed app internals are stable

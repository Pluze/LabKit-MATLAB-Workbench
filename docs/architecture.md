# Architecture Notes

This document describes the current package boundaries and compatibility layers. It is not a roadmap.

## Core Shape

```text
apps/ public app entry points; EIS and Chrono overlay are single-file app implementations
    ↓
+gamrywb GUI and DTA APIs
    ↓
struct-based item/session models
    ↓
+gamrywb package functions
```

The reusable `+gamrywb` package should provide two library surfaces that apps compose:

```text
Gamry/DTA library:
  DTA discovery, parser dispatch, normalized file loading, table/data access, sessions

Scientific-app GUI base library:
  generic shells, controls, panels, list refresh, logs, result surfaces, and UI state helpers

Shared utility base:
  only small cross-cutting utilities that are not experiment-specific
```

Experiment app implementations should live under public `apps/*.m` files rather than being absorbed into the reusable library package. The EIS and Chrono overlay apps are the first single-file app implementations. CSC, VT resistance, and CIC still have transitional `apps/private` launch bodies to collapse. The long-term ideal is one experiment app `.m` file owning its scientific workflow. App-specific helper packages under `apps/+gamrywb_apps` are transitional only when they preserve direct tests during migration; they are not a reusable app framework and should be eliminated.

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
+gamrywb/+dta       GUI-free DTA type detection and loading facade
+gamrywb/+io        DTA parsers, folder discovery, generic table CSV writing, session IO
+gamrywb/+data      item/session construction and table/column access
+gamrywb/+analysis  broad pulse detection helpers and remaining low-level utilities
+gamrywb/+ui        reusable GUI framework helpers and small UI construction helpers
+gamrywb/+util      small generic helpers
```

## Three-Layer Map

The reusable library should be understandable as three layers, even though MATLAB package folders remain practical and granular:

```text
Library 1: scientific-app GUI base
  +gamrywb/+ui
  reusable shells, panels, controls, display-data helpers, and handle-scoped UI utilities

Library 2: Gamry/DTA parsing and loading
  +gamrywb/+dta
  +gamrywb/+io parser functions
  +gamrywb/+data item/session construction and table/column access

Not library code: experiment-specific app design
  apps/ public app files
  apps/+gamrywb_apps app-specific helper packages only as transitional/testable app-side code
  experiment-specific analysis, plotting, result summaries, and exports

Shared utility base:
  +gamrywb/+util
```

This map is a design boundary, not a reason to force every function into exactly three folders. Keep granular packages when they make code easier to inspect. Refactor or remove helpers when they obscure which layer owns a decision.

`+gamrywb/+analysis` and app-specific export helpers in `+gamrywb/+io` are transitional when they encode experiment-specific decisions. Move those decisions toward app-side code when touching the related app. Keep only broadly reusable, parameter-light math and data utilities in the library.

Analysis, data, and IO package functions should not depend on GUI state or call `uialert`. Plot/UI helpers may accept explicit graphics handles and should keep side effects limited to those handles.

Analysis functions should return status through result structs, for example:

```matlab
result.ok = false;
result.message = "Not enough valid T/Vf/Im points.";
```

The GUI decides how to display that status.

## Current Package Surface

- `apps/`: user-facing app entry points and app-specific implementations. EIS and Chrono overlay are currently single public app source files with their app-specific workflow helpers folded into local functions. CSC, VT resistance, and CIC still use transitional `apps/private` launch bodies. CSC, VT, and CIC-specific analysis/export/plot helpers currently live under `apps/+gamrywb_apps` as app-side transitional code so numerical tests remain direct.
- `+dta`: GUI-free facade for supported DTA family detection, single-file loading, and batch loading with status/report structs. It delegates to existing `+io` parser and `+data` item-construction helpers.
- `+io`: DTA parsers, folder discovery, and session save/load. Export helpers that encode experiment-specific formats should stay with the owning app rather than in reusable `+gamrywb`.
- `+data`: table/column accessors, CV/CT selected-column access, chrono item construction, EIS item construction, session add/remove helpers.
- `+analysis`: broad pulse detection helpers and remaining low-level utilities. Experiment-specific calculations should migrate toward app-side code unless they are clearly general, parameter-light math utilities.
- `+ui`: reusable GUI framework helpers, including app axes creation/reset, log append and log panel, multi-select and single-select file-listbox refresh, multi-file and single-select file-panel, summary row, result table panel, info/log text-area, plot-options panel, simple labeled-control, two-pane shell, tabbed dual-plot shell, top/bottom plot-control construction/state helpers, and generic session/listbox orchestration used by apps.
- `+util`: low-risk helpers used by parser, data, analysis, and export code.

## Boundaries To Preserve

Avoid:

- analysis functions reading UI controls
- package functions writing directly to GUI text areas
- new parser copies in GUI files
- duplicated CSV formatting in GUI files
- MATLAB classes before struct schemas stabilize
- starting a unified GUI before package-backed app internals are stable

# Architecture Notes

This document describes the current package boundaries and compatibility layers. It is not a roadmap.

## Core Shape

```text
apps/ public app entry points; all current apps are single-file app implementations
    ↓
+gamrywb GUI and DTA APIs
    ↓
struct-based item/session models
    ↓
+gamrywb package functions
```

The reusable `+gamrywb` package should provide three library surfaces that apps compose:

```text
Gamry/DTA library:
  app-facing DTA discovery/loading/session facade plus lower-level parser and data APIs

Scientific-app GUI base library:
  generic shells, controls, panels, list refresh, logs, result surfaces, and UI state helpers

Internal helper base:
  implementation helpers that are not app-facing API
```

Experiment app implementations should live under public `apps/*.m` files rather than being absorbed into the reusable library package. All current app bodies are now single-file public app implementations. The long-term ideal is one experiment app `.m` file owning its scientific workflow. The previous `apps/+gamrywb_apps` helper namespaces were migration waypoints, not a reusable app framework, and should not be reintroduced for app-specific logic.

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
+gamrywb/+dta       GUI-free app-facing DTA discovery, loading, and session facade
+gamrywb/+io        DTA parsers, folder discovery, session IO
+gamrywb/+data      selected lower-level table/column access
+gamrywb/+ui        reusable GUI framework helpers and small UI construction helpers
private helpers     implementation helpers inside the owning package or app file
```

## Three-Layer Map

The reusable library should be understandable as three layers, even though MATLAB package folders remain practical and granular:

```text
Library 1: scientific-app GUI base
  +gamrywb/+ui
  reusable shells, panels, controls, display-data helpers, and handle-scoped UI utilities

Library 2: Gamry/DTA parsing and loading
  +gamrywb/+dta discovery, loading, and session facade for app code
  +gamrywb/+io parser functions
  +gamrywb/+data selected table/column access

Internal helper base
  package-private helpers and app-local functions
  internal string, struct, numeric, CSV, pulse-detection, and parser helpers used behind GUI/DTA/data APIs

Not library code: experiment-specific app design
  apps/ public app files
  experiment-specific analysis, plotting, result summaries, and exports
```

This map is a design boundary, not a reason to force every function into exactly three folders. Keep granular packages when they make code easier to inspect. Refactor or remove helpers when they obscure which layer owns a decision.

For concrete calling examples and the practical checklist used before adding a new experiment app, see `docs/api_usage.md`.

Pulse detection is app-facing only through `gamrywb.dta.detectPulses`; its implementation lives in `+gamrywb/+dta/private`. App-specific analysis, export-table construction, CSV schemas, and plot annotations belong in the owning public app file. Do not reintroduce those experiment decisions into a public analysis package, `+gamrywb/+io`, or a helper package unless a future repeated use case proves a lower-level utility is clearer.

Data, DTA, and IO package functions should not depend on GUI state or call `uialert`. Plot/UI helpers may accept explicit graphics handles and should keep side effects limited to those handles.

The DTA facade is also guarded as a GUI-free and app-free layer: it should not call MATLAB UI constructors, file dialogs, alerts, app entry points, or `apps/` helpers. New DTA-backed app code should prefer `gamrywb.dta.*` for loading and session operations; DTA code must not call back into app code.

The data layer is guarded as GUI-free and app-free table/curve access code. It should not call parser, DTA facade helpers, MATLAB UI constructors, file dialogs, alerts, `gamrywb.ui`, app entry points, or `apps/` helpers.

The IO layer is guarded as GUI-free and app-free parser/session IO code. It may call lower-level utility helpers and itself recursively for discovery, but it should not call MATLAB UI constructors, file dialogs, alerts, `gamrywb.ui`, app entry points, `apps/` helpers, or app-specific export writers.

Shared implementation helpers are not app-facing API. Parser-only helpers belong under package-private parser helpers. App-specific formatting, parsing, interpolation, and export helpers belong in the owning app file unless a repeated use case proves a clearer `gamrywb.dta`, `gamrywb.ui`, or selected `gamrywb.data` API.

Reusable UI helpers should build or update generic controls and draw prepared data. Data extraction, parser/session calls, and analysis decisions should stay in the app, DTA, or data layers; for example, apps should call `gamrywb.data.getCurveXY` before passing prepared vectors and labels to `gamrywb.ui.plotXY`. App-specific callback choreography, such as clearing a session, restoring app-specific plot defaults, refreshing experiment summaries, and writing app logs, should stay in the owning app file even when two apps have similar callback order. Domain labels such as DTA-specific open/export button text and app shell tab/panel titles should be passed in from apps rather than hardcoded in the GUI library.

App code may use selected `gamrywb.data.*` helpers for parsed table and curve access, such as `getColumn`, `getMainCurve`, and `getCurveXY`. DTA session operations should go through `gamrywb.dta.*` so apps do not need to understand lower-level loader callbacks or session internals.

DTA and app-local analysis functions should return status through result structs, for example:

```matlab
result.ok = false;
result.message = "Not enough valid T/Vf/Im points.";
```

The GUI decides how to display that status.

## Current Package Surface

- `apps/`: user-facing app entry points and app-specific implementations. All current app bodies are single public app source files, and app-specific workflow helpers are local functions in those files rather than reusable `+gamrywb` APIs or transitional app-helper packages.
- `+dta`: GUI-free facade for supported DTA file discovery, family detection, single-file loading, batch loading, folder loading, pulse detection, and app-facing DTA session operations with status/report structs. It delegates to existing `+io` parser and `+data` item/session helpers, with DTA-specific implementation helpers kept private.
- `+io`: DTA parsers, folder discovery, and session save/load. It should not contain app-specific export helpers or scientific result schemas.
- `+data`: selected table/column accessors: main chrono curve lookup, EIS ZCURVE lookup, exact-case column access, and prepared X/Y extraction.
- `+ui`: reusable GUI framework helpers, including generic axes creation/reset, prepared-X/Y plotting, log append and log panel, generic listbox item refresh, multi-file and single-select file-panel, summary row, result table panel, plot-options panel, simple labeled-control, two-pane shell, tabbed dual-plot shell, and top/bottom plot-control construction/state helpers.
- Internal helpers: package-private parser helpers and app-local helper functions. The public `+util` package should not be reintroduced as a new-app entry surface.

## Boundaries To Preserve

Avoid:

- analysis functions reading UI controls
- package functions writing directly to GUI text areas
- new parser copies in GUI files
- reusable package functions owning app-specific CSV schemas
- MATLAB classes before struct schemas stabilize
- starting a unified GUI before package-backed app internals are stable

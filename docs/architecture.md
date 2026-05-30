# Architecture Notes

This document describes the current package boundaries. It is not a roadmap.

## Core Shape

```text
apps/ category folders containing public app entry points
    ↓
+labkit GUI and DTA APIs
    ↓
struct-based item/session models
    ↓
+labkit package functions
```

The reusable `+labkit` package should provide two app-facing library surfaces that apps compose:

```text
DTA/electrochemistry library:
  app-facing DTA discovery, loading, session, pulse, and parsed table/curve APIs

Scientific-app GUI base library:
  resizable tabbed workbench shells, controls, panels, list refresh, logs, result surfaces, and UI state helpers

Internal helper base:
  parser, item/session, pulse, and other helpers that are not app-facing API
```

Short version:

```text
labkit.dta   = DTA file/session facade
labkit.ui    = reusable GUI structure and rendering helpers
```

`labkit` is the generic reusable MATLAB infrastructure namespace. The current `dta` module is the first concrete data/device family and is still Gamry DTA focused.

Future data or device families can be added beside `labkit.dta` as peer modules. They should expose one coherent app-facing facade each rather than leaking parser or low-level IO packages into app code.

Experiment app implementations live under category folders such as `apps/electrochem/` rather than being absorbed into the reusable library package. The intended app shape is one experiment app `.m` file owning its scientific workflow. App-specific helper packages should not be reintroduced just to make local code public.

## Entrypoints

The supported runtime entry points are:

```text
labkit_CIC_app
labkit_VTResistance_app
labkit_CSC_app
labkit_EIS_app
labkit_ChronoOverlay_app
```

The app files are package-backed and do not delegate to legacy GUI files.

`startup_labkit` adds the repository root, `apps/`, and normal nested app category folders to the MATLAB path. Root-level original command wrappers and the old `legacy/` GUI directory have been removed, so the old command names no longer resolve by default.

## Package Responsibilities

```text
+labkit/+dta       GUI-free app-facing DTA discovery, loading, and session facade
+labkit/+ui        reusable GUI framework helpers and small UI construction helpers
private helpers     parser, item/session, pulse, and other implementation helpers inside the owning package or app file
```

## Three-Layer Map

The reusable library should be understandable as three layers, even though MATLAB package folders remain practical and granular:

```text
Library 1: scientific-app GUI base
  +labkit/+ui
  reusable tabbed shells, panels, controls, display-data helpers, and handle-scoped UI utilities

Library 2: Gamry/DTA parsing and loading
  +labkit/+dta discovery, loading, session, pulse, and parsed table/curve facade for app code
  +labkit/+dta/private parser, item/session, and implementation helpers

Internal helper base
  package-private helpers and app-local functions
  internal string, struct, numeric, CSV, pulse-detection, and parser helpers used behind GUI/DTA APIs

Not library code: experiment-specific app design
  apps/<category>/ public app files
  experiment-specific analysis, plotting, result summaries, and exports
```

This map is a design boundary, not a reason to force every function into exactly three folders. Refactor or remove helpers when they obscure which layer owns a decision.

For concrete calling examples and the practical checklist used before adding a new experiment app, see `docs/api_usage.md`.

Pulse detection is app-facing only through `labkit.dta.detectPulses`; its implementation lives in `+labkit/+dta/private`. App-specific analysis, export-table construction, CSV schemas, and plot annotations belong in the owning public app file. Do not reintroduce those experiment decisions into a public analysis package, IO/data package, or helper package unless a future repeated use case proves a lower-level utility is clearer.

DTA package functions should not depend on GUI state or call `uialert`. Plot/UI helpers may accept explicit graphics handles and should keep side effects limited to those handles.

The DTA facade is guarded as a GUI-free and app-free layer: it should not call MATLAB UI constructors, file dialogs, alerts, app entry points, or `apps/` helpers. New DTA-backed app code should prefer `labkit.dta.*` for loading, session operations, pulse detection, and parsed table/curve access; DTA code must not call back into app code.

There is no public `+labkit/+io` or `+labkit/+data` app-facing surface. Parser/session IO and low-level table/curve helpers live behind `labkit.dta.*`, with parser-only helpers kept under `+labkit/+dta/private`.

Shared implementation helpers are not app-facing API. Parser-only helpers belong under package-private parser helpers. App-specific formatting, parsing, interpolation, and export helpers belong in the owning app file unless a repeated use case proves a clearer `labkit.dta` or `labkit.ui` API.

Reusable UI helpers should build or update generic controls and draw prepared data. Data extraction, parser/session calls, and analysis decisions should stay in the app or DTA layer; for example, apps should call `labkit.dta.getCurveXY` before passing prepared vectors and labels to `labkit.ui.plotXY`. App-specific callback choreography, such as clearing a session, restoring app-specific plot defaults, refreshing experiment summaries, and writing app logs, should stay in the owning app file even when two apps have similar callback order. Domain labels such as DTA-specific open/export button text and app shell tab/panel titles should be passed in from apps rather than hardcoded in the GUI library.

Current apps share the same workbench layout contract: a resizable left control region with scrollable tabs and a right output region for plots or primary content. Simple apps use the one-tab `createTwoPaneShell` variant; CIC, VT resistance, and CSC use the shared tabbed dual-plot variant. App files should not rebuild split-pane layout plumbing or own custom separator drag code.

App code may use selected `labkit.dta.*` helpers for parsed table and curve access, such as `getColumn`, `getMainCurve`, and `getCurveXY`. DTA session operations should go through `labkit.dta.*` so apps do not need to understand lower-level loader callbacks or session internals.

DTA and app-local analysis functions should return status through result structs, for example:

```matlab
result.ok = false;
result.message = "Not enough valid T/Vf/Im points.";
```

The GUI decides how to display that status.

## Current Package Surface

- `apps/`: user-facing app category folders and app-specific implementations. Current electrochemistry app bodies live under `apps/electrochem/` as single public app source files, and app-specific workflow helpers are local functions in those files rather than reusable `+labkit` APIs or transitional app-helper packages.
- `+dta`: GUI-free facade for supported DTA file discovery, family detection, single-file loading, batch loading, folder loading, pulse detection, item construction, parsed table/curve access, session save/load, and app-facing DTA session operations with status/report structs. It keeps parser and DTA-specific implementation helpers private.
- `+ui`: reusable GUI framework helpers, including the shared resizable tabbed workbench shell, generic axes creation/reset, prepared-X/Y plotting, log append and log panel, generic listbox item refresh, multi-file and single-select file-panel, summary row, result table panel, plot-options panel, simple labeled-control, one-tab two-pane shell, tabbed dual-plot shell, and top/bottom plot-control construction/state helpers.
- Internal helpers: package-private parser helpers and app-local helper functions. Public `+io`, `+data`, and `+util` packages should not be reintroduced as new-app entry surfaces.

## Boundaries To Preserve

Avoid:

- analysis functions reading UI controls
- package functions writing directly to GUI text areas
- new parser copies in GUI files
- reusable package functions owning app-specific CSV schemas
- MATLAB classes before struct schemas stabilize
- starting a unified GUI before package-backed app internals are stable

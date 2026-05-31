# Architecture

This document describes the current package boundaries. It is not a roadmap.

## Project Philosophy

LabKit is an internal lab app workbench for daily research utilities, not a monolithic analysis platform. The apps are first-class deliverables: each app targets a specific experimental workflow and should remain independently launchable and usable.

The reusable library should stay small and stable. Shared infrastructure belongs in `+labkit` only after repeated real app use shows that a pattern is domain-neutral, testable, and clearer as an API than as app-local code. App growth is acceptable; public library growth should be conservative.

## Core Shape

```text
apps/ category folders containing public app entry points
    ↓
+labkit GUI foundation and current DTA APIs
    ↓
struct-based item/session models
    ↓
+labkit package functions
```

The reusable `+labkit` package currently provides one general GUI foundation plus one electrochemistry implementation surface:

```text
GUI foundation:
  resizable tabbed workbench shells, controls, panels, list refresh, logs, result surfaces, and UI state helpers

Current DTA/electrochemistry implementation:
  app-facing DTA discovery, loading, session, pulse, and parsed table/curve APIs

Internal helper base:
  parser, item/session, pulse, and other helpers that are not app-facing API
```

Short version:

```text
labkit.ui    = reusable GUI structure and rendering helpers
labkit.dta   = current electrochemistry DTA file/session facade
```

`labkit` is the generic reusable MATLAB infrastructure namespace. The current `dta` module is the first concrete data/device family and is still Gamry DTA focused.

Future data or device families can be added beside `labkit.dta` as peer modules. They should expose one coherent app-facing facade each rather than leaking parser or low-level IO packages into app code.

Experiment app implementations live under category folders such as `apps/electrochem/` rather than being absorbed into the reusable library package. The intended app shape is one public entry point per experiment workflow, with that app owning its domain behavior. App-local helper functions are fine; app-specific helper packages should not be reintroduced just to make local code public.

## Entrypoints

The supported runtime entry points are:

```text
labkit_CIC_app
labkit_VTResistance_app
labkit_CSC_app
labkit_EIS_app
labkit_ChronoOverlay_app
labkit_DICPreprocess_app
labkit_DICPostprocess_app
labkit_CurvatureMeasurement_app
```

`startup_labkit` adds the repository root, `apps/`, and normal nested app category folders to the MATLAB path.

## Package Responsibilities

```text
+labkit/+dta       GUI-free app-facing DTA discovery, loading, and session facade
+labkit/+ui        reusable GUI framework helpers and small UI construction helpers
private helpers     parser, item/session, pulse, and other implementation helpers inside the owning package or app file
```

## Three-Layer Map

The reusable library should be understandable as three layers, even though MATLAB package folders remain practical and granular:

```text
Library 1: lab-app GUI base
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
  experiment-specific domain logic, plotting, result summaries, and exports
```

This map is a design boundary, not a reason to force every function into exactly three folders. Refactor or remove helpers when they obscure which layer owns a decision.

For the shared GUI layout contract, see `docs/ui.md`. For DTA facade details, see `docs/dta.md`. For app-owned workflow details and the practical checklist used before adding a new app, see `docs/apps.md`.

Pulse detection is app-facing only through `labkit.dta.detectPulses`; its implementation lives in `+labkit/+dta/private`. App-specific analysis, export-table construction, CSV schemas, and plot annotations belong in the owning public app file. Do not reintroduce those experiment decisions into a public analysis package, IO/data package, or helper package unless a future repeated use case proves a lower-level utility is clearer.

DTA package functions should not depend on GUI state or call `uialert`. Plot/UI helpers may accept explicit graphics handles and should keep side effects limited to those handles.

The DTA facade is guarded as a GUI-free and app-free layer: it should not call MATLAB UI constructors, file dialogs, alerts, app entry points, or `apps/` helpers. New DTA-backed app code should prefer `labkit.dta.*` for loading, session operations, pulse detection, and parsed table/curve access; DTA code must not call back into app code.

There is no public `+labkit/+io` or `+labkit/+data` app-facing surface. Parser/session IO and low-level table/curve helpers live behind `labkit.dta.*`, with parser-only helpers kept under `+labkit/+dta/private`.

Shared implementation helpers are not app-facing API. Parser-only helpers belong under package-private parser helpers. App-specific formatting, parsing, interpolation, and export helpers belong in the owning app file unless a repeated use case proves a clearer `labkit.dta` or `labkit.ui` API.

## Library Extraction Rule

A helper may move into `+labkit` only when it satisfies the practical extraction checklist:

- It can be named without experiment-specific vocabulary.
- It does not encode domain units, thresholds, result columns, or paper-specific logic.
- It does not read or mutate app state directly.
- It can be tested independently.
- At least two real apps use it, or a broad workflow family clearly needs it.
- Moving it into the library reduces duplication without increasing API confusion.

`+labkit` should not become a miscellaneous helper dump. Future broad data or device families may become peer facades beside `labkit.dta`, but only when a real class of workflows needs that surface.

Reusable UI helpers should build or update generic controls and draw prepared data. Data extraction, parser/session calls, and analysis decisions should stay in the app or DTA layer; for example, apps should call `labkit.dta.getCurveXY` before passing prepared vectors and labels to `labkit.ui.plotXY`. App-specific callback choreography, such as clearing a session, restoring app-specific plot defaults, refreshing experiment summaries, and writing app logs, should stay in the owning app file even when two apps have similar callback order. Domain labels such as DTA-specific open/export button text and app shell tab/panel titles should be passed in from apps rather than hardcoded in the GUI library.

Current apps share the workbench layout contract described in `docs/ui.md`: a resizable left control region with tabbed pages, plus a right output region for live plots or primary content. The app-facing shell entry point is `labkit.ui.createWorkbench`; apps configure the right side as a custom plot/output grid or as the standard dual-plot region.

The file panel and log panel may use shared structure, but app-specific tab sections, controls, result summaries, callback ordering, and plot behavior remain owned by the app. Generic helpers such as panel-grid creation, listbox selection refresh, and image-axis anchor curve editing can live in `labkit.ui` only when they are domain-neutral.

App code may use selected `labkit.dta.*` helpers for parsed table and curve access, such as `getColumn`, `getMainCurve`, and `getCurveXY`. DTA session operations should go through `labkit.dta.*` so apps do not need to understand lower-level loader callbacks or session internals.

DTA and app-local analysis functions should return status through result structs, for example:

```matlab
result.ok = false;
result.message = "Not enough valid T/Vf/Im points.";
```

The GUI decides how to display that status.

## Validation Boundary

The default automated validation boundary is the non-GUI MATLAB suite: core architecture checks, DTA facade/parser checks, and pure app analysis/export checks. GitHub Actions runs that suite on pushes and pull requests to `main`.

GUI launch/layout checks are available as focused local profiles, but interactive GUI workflows are user-validated outside CI. This keeps the reusable UI shell tested without requiring GitHub-hosted runners to provide stable MATLAB graphics behavior.

## Current Package Surface

- `apps/`: user-facing app category folders and app-specific implementations. Current electrochemistry app bodies live under `apps/electrochem/`, current DIC app bodies live under `apps/dic/`, and current general image-measurement app bodies live under `apps/image_measurement/`. Each workflow should keep one public launchable entry point; app-owned helpers may stay local or private to the app family rather than becoming reusable `+labkit` APIs or transitional app-helper packages.
- `labkit.dta`: GUI-free facade for supported DTA file discovery, family detection, single-file loading, batch loading, folder loading, pulse detection, item construction, parsed table/curve access, session save/load, and app-facing DTA session operations with status/report structs. It keeps parser and DTA-specific implementation helpers private.
- `labkit.ui`: reusable GUI framework helpers, centered on the unified `createWorkbench` shell plus domain-neutral components: file-selection panel, log panel, generic panel-grid creation, row-resize handles, axes creation/reset, image-axis anchor curve editing, prepared-X/Y plotting, listbox selection refresh, summary rows, result table panel, plot-options panel, simple labeled controls, and top/bottom plot-control construction/state helpers.
- Internal helpers: package-private parser helpers and app-local helper functions. Public `+io`, `+data`, and `+util` packages should not be reintroduced as new-app entry surfaces.

## Boundaries To Preserve

Avoid:

- analysis functions reading UI controls
- package functions writing directly to GUI text areas
- new parser copies in GUI files
- reusable package functions owning app-specific CSV schemas
- MATLAB classes before struct schemas stabilize
- replacing separate app entry points with a single all-in-one launcher without explicit approval

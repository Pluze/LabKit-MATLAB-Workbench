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
  DTA discovery, parser dispatch, normalized file loading, table/data access, sessions

Scientific-app GUI base library:
  generic shells, controls, panels, list refresh, logs, result surfaces, and UI state helpers

Shared utility base:
  only small cross-cutting utilities that are not experiment-specific
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
+gamrywb/+dta       GUI-free DTA discovery, type detection, file loading, and folder loading facade
+gamrywb/+io        DTA parsers, folder discovery, session IO
+gamrywb/+data      item/session construction, table/column access, session orchestration
+gamrywb/+analysis  broad pulse detection helpers
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
  +gamrywb/+dta discovery and loading facade
  +gamrywb/+io parser functions
  +gamrywb/+data item/session construction, table/column access, selection, loading orchestration, and result summaries

Library 3: utility base
  +gamrywb/+util
  small string, struct, numeric, CSV, and parsing helpers with no GUI, DTA-family, or experiment assumptions

Not library code: experiment-specific app design
  apps/ public app files
  experiment-specific analysis, plotting, result summaries, and exports
```

This map is a design boundary, not a reason to force every function into exactly three folders. Keep granular packages when they make code easier to inspect. Refactor or remove helpers when they obscure which layer owns a decision.

For concrete calling examples, see `docs/api_usage.md`. For the practical checklist used before adding a new experiment app, see `docs/new_app_playbook.md`.

`+gamrywb/+analysis` is intentionally narrow: it currently owns reusable pulse detection. App-specific analysis, export-table construction, CSV schemas, and plot annotations now belong in the owning public app file. Do not reintroduce those experiment decisions into `+gamrywb/+analysis`, `+gamrywb/+io`, or a helper package unless a future repeated use case proves a lower-level utility is clearer.

Analysis, data, and IO package functions should not depend on GUI state or call `uialert`. Plot/UI helpers may accept explicit graphics handles and should keep side effects limited to those handles.

Reusable UI helpers should build or update generic controls. App-specific callback choreography, such as clearing a session, restoring app-specific plot defaults, refreshing experiment summaries, and writing app logs, should stay in the owning app file even when two apps have similar callback order. Domain labels such as DTA-specific open/export button text and app shell tab/panel titles should be passed in from apps rather than hardcoded in the GUI library.

Analysis functions should return status through result structs, for example:

```matlab
result.ok = false;
result.message = "Not enough valid T/Vf/Im points.";
```

The GUI decides how to display that status.

## Current Package Surface

- `apps/`: user-facing app entry points and app-specific implementations. All current app bodies are single public app source files, and app-specific workflow helpers are local functions in those files rather than reusable `+gamrywb` APIs or transitional app-helper packages.
- `+dta`: GUI-free facade for supported DTA file discovery, family detection, single-file loading, batch loading, and folder loading with status/report structs. It delegates to existing `+io` parser and `+data` item-construction helpers.
- `+io`: DTA parsers, folder discovery, and session save/load. It should not contain app-specific export helpers or scientific result schemas.
- `+data`: table/column accessors, CV/CT selected-column access, chrono item construction, EIS item construction, session add/remove/select/load helpers, and generic item/result summaries.
- `+analysis`: pulse detection helpers. Experiment-specific calculations should migrate toward app-side code unless they are clearly general, parameter-light math utilities.
- `+ui`: reusable GUI framework helpers, including generic axes creation/reset, selected-curve plotting, log append and log panel, generic listbox item refresh, multi-file and single-select file-panel, summary row, result table panel, plot-options panel, simple labeled-control, two-pane shell, tabbed dual-plot shell, and top/bottom plot-control construction/state helpers.
- `+util`: low-risk generic helpers used by parser, data, analysis, UI, and app code, including string cleanup, simple struct operations, numeric window/index helpers, and safe interpolation. It should not contain GUI state, DTA-family dispatch, scientific result definitions, plot labels, or export schemas.

## Boundaries To Preserve

Avoid:

- analysis functions reading UI controls
- package functions writing directly to GUI text areas
- new parser copies in GUI files
- reusable package functions owning app-specific CSV schemas
- MATLAB classes before struct schemas stabilize
- starting a unified GUI before package-backed app internals are stable

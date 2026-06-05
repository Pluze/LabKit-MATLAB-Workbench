# Architecture

This document describes the current package boundaries. It is not a roadmap.

## Project Shape

LabKit is an internal lab app workbench for daily research utilities. Apps are first-class deliverables: each app targets a specific experimental workflow and should remain independently launchable and usable.

The reusable library stays small and stable. Shared infrastructure belongs in `+labkit` only after repeated real app use shows that a pattern is domain-neutral, testable, and clearer as an API than as app-local code.

```text
apps/ category folders containing public app entry points or app subfolders
    -> compose shared facades
+labkit GUI foundation plus DTA and biosignal facades
    -> use struct-based item/session/signal models
+labkit private helpers
    -> hide parser, normalization, pulse, and implementation details
```

Short version:

```text
labkit.ui        layered GUI foundation split into app/view/tool/diag facades
labkit.dta       current electrochemistry/Gamry DTA file and session facade
labkit.biosignal current wearable/physiological time-series facade
apps/            experiment-specific workflow apps
```

Future data or device families can become peer facades beside `labkit.dta` and `labkit.biosignal` when real workflows need them. They should expose coherent app-facing APIs rather than leaking parser or low-level IO packages into app code.

## Entrypoints

Supported runtime entry points:

```text
labkit_CIC_app
labkit_VTResistance_app
labkit_CSC_app
labkit_EIS_app
labkit_ChronoOverlay_app
labkit_DICPreprocess_app
labkit_DICPostprocess_app
labkit_CurvatureMeasurement_app
labkit_FocusStack_app
labkit_ECGPrint_app
```

`startup_labkit` adds the repository root, `apps/`, and normal nested app category folders to the MATLAB path. `LabKit.prj` records the same path setup and uses `startup_labkit.m` as the project startup file for users who open the repository as a MATLAB Project.

## Package Responsibilities

| Area | Responsibility |
| --- | --- |
| `apps/` | Public app entry points and app-specific workflow code, including app-owned private helpers. |
| `+labkit/+ui` | Reusable GUI app/view/tool/diagnostics facades plus private implementation helpers. |
| `+labkit/+dta` | GUI-free DTA discovery, loading, session, pulse, and parsed curve/table facade. |
| `+labkit/+biosignal` | GUI-free recording loading, channel extraction, waveform processing, events, segments, templates, measurements, and group comparisons. |
| `private/` helpers | Parser, normalization, item/session construction, pulse, and implementation details hidden behind the owning facade. |

Apps may use selected DTA helpers such as `getColumn`, `getMainCurve`, `getZCurve`, and `getCurveXY`. DTA session operations should go through `labkit.dta.*` so apps do not need lower-level loader callbacks or session internals.

## Boundaries

DTA code should not depend on GUI state, call UI constructors, open file dialogs, show alerts, or call app entry points. New DTA-backed app code should prefer `labkit.dta.*` for loading, session operations, pulse detection, and parsed table/curve access.

Biosignal code should not depend on GUI state, DTA, or app entry points. Low-level MAT/table normalization stays behind the biosignal facade.

UI helpers should build or update generic controls and draw prepared data. Apps pass labels, callbacks, prepared vectors, tables, debug contexts, and option values into UI helpers. UI helpers should not call DTA parsers, own formulas, define result fields, or decide export schemas.

Reusable image-interaction tools may own app-neutral UI state when the interaction itself is generic. Image apps with custom axes behavior should register default scroll or interaction hooks through `labkit.ui.tool.createRuntime`; direct app ownership of image-tool figure/axes pointer callbacks is outside the app boundary. Apps remain responsible for image loading/redrawing, edit-mode coordination, scientific calculations, summaries, and exports.

The app-facing UI API is intentionally layered:

| Layer | Responsibility | App-facing API |
| --- | --- | --- |
| App | Figure shell, tabs, request dispatch, busy state. | `labkit.ui.app.createShell`, `tab`, `dispatchRequest`, `runBusy`. |
| View | Sections, forms, reusable panels, axes, rendering actions, and UI state updates. | `labkit.ui.view.section`, `form`, `panel`, `axes`, `draw`, `update`, `place`. |
| Tool | Exclusive interaction runtime and composed tools. | `labkit.ui.tool.createRuntime`, `anchorEditor`, `scaleBar`, `scaleBarCalibration`. |
| Diagnostics | Debug launch, visible trace, callback instrumentation. | `labkit.ui.diag.createContext`. |

App-specific analysis, plotting annotations, result summaries, CSV schemas, failed-row behavior, and workflow wording belong in the owning app file or app-owned private helpers. The default private-helper location for a large app is `apps/<family>/<app_slug>/private/`; `apps/<family>/private/` should be reserved for helpers shared by multiple apps in that family.

## Library Extraction Rule

A helper may move into `+labkit` only when it satisfies all of these:

- It can be named without experiment-specific vocabulary.
- It does not encode domain units, thresholds, result columns, or paper-specific logic.
- It does not read or mutate app state directly.
- It can be tested independently.
- At least two real apps use it, or a broad workflow family clearly needs it.
- Moving it into the library reduces duplication without increasing API confusion.

If those conditions are not met, keep the helper app-local. App growth is acceptable; public library growth should be conservative.

## Public API Documentation

Every public library function under `+labkit/+ui`, `+labkit/+dta`, and `+labkit/+biosignal` should document its app-facing call contract immediately after the function declaration:

- usage example when helpful
- input parameter meanings and accepted types
- public `opts`, `spec`, `labels`, or `callbacks` fields with defaults and legal values
- returned struct/table fields intended for app code
- recommendation to start from a default-options helper when one exists

Private helpers may keep shorter comments, but should still identify expected caller, input/output shapes, important side effects or errors, and non-obvious assumptions.

## Validation Boundary

The default automated validation boundary is the non-GUI MATLAB build task: project architecture checks, `labkit` facade/parser checks, and pure app analysis/export checks. GitHub Actions runs that task on pushes and pull requests to `main`.

GUI launch/layout checks live in source-aligned build tasks such as `testLabkitUiGui` and `testAppsGui`. Interactive GUI workflows are validated manually in MATLAB app windows.

## Current Package Surface

- `labkit.ui.app`: shell specs, tab specs, internal request dispatch, and busy-state feedback.
- `labkit.ui.view`: sections, unified form controls, file panels, logs, tables, listbox state, axes reset/popout, image display, and prepared-X/Y plotting.
- `labkit.ui.tool`: interaction runtime, anchor editing, scale-bar tool, and scale-bar calibration.
- `labkit.ui.diag`: debug context, visible trace, callback instrumentation, and log mirroring.
- `labkit.dta`: DTA file discovery, type detection, single/batch/folder loading, pulse detection, item construction behind the facade, parsed table/curve access, session save/load, and session add/remove/select operations.
- `labkit.biosignal`: MAT timetable and delimited table recording loading, channel extraction, time ROI cropping, filtering, ECG/QRS peak detection, event-centered segmentation, template construction, template-residual SNR-style measurements, and group comparisons.

Public `+io`, `+data`, `+analysis`, and `+util` package surfaces should not be reintroduced as app-facing APIs.

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
labkit.ui        layered GUI foundation split into app/spec/view/tool/diag facades
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
labkit_ImageEnhance_app
labkit_ImageMatch_app
labkit_BatchImageCrop_app
labkit_ECGPrint_app
```

`labkit_launcher` is the primary human-facing entry point for selecting apps.
`startup_labkit` adds the repository root, `apps/`, and normal nested app
category folders to the MATLAB path for scripts, tests, and local MATLAB
Project startup. MATLAB Project metadata is optional local IDE state: users can
generate `LabKit.prj` with `scripts/create_local_matlab_project.m`, but the
repository does not track `LabKit.prj` or `resources/project/`.

## Package Responsibilities

| Area | Responsibility |
| --- | --- |
| `apps/` | Public app entry points and app-specific workflow code, including app-owned package helpers under the owning app folder. |
| `+labkit/+ui` | Reusable GUI app/spec/view/tool/diagnostics facades plus private implementation helpers. |
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
| App | Declarative app creation, legacy shell construction, request dispatch, busy state. | `labkit.ui.app.create`, `createShell`, `tab`, `dispatchRequest`, `runBusy`. |
| Spec | Data-only UI 2.0 workbench specs. | `labkit.ui.spec.app`, `workspace`, `tab`, `section`, `field`, `rangeField`, `action`, `actionGroup`, `pathPanel`, `previewArea`, `resultTable`, `logPanel`, `statusPanel`, `custom`. |
| View | Semantic UI 2.0 state helpers plus migration-era sections, forms, panels, axes, and rendering actions. | `labkit.ui.view.setValue`, `getValue`, `setEnabled`, `appendLog`, `setListItems`, `setListSelection`, `drawImage`, `resetAxes`, `clearAxes`, plus legacy `section`, `form`, `panel`, `axes`, `draw`, `update`, `place`. |
| Tool | Exclusive interaction runtime and composed tools. | `labkit.ui.tool.createRuntime`, `anchorEditor`, `scaleBar`, `scaleBarCalibration`. |
| Diagnostics | Debug launch, visible trace, callback instrumentation. | `labkit.ui.diag.createContext`. |

App-specific analysis, plotting annotations, result summaries, CSV schemas,
failed-row behavior, and workflow wording belong in the owning app file or an
app-owned package under the owning app folder. For large apps, the default
helper location is `apps/<family>/<app_slug>/+<app_slug>/...`, with component
packages such as `+ui`, `+state`, `+ops`, `+view`, `+export`, and `+io` created
as needed. The app-owned package name should match the app folder slug; do not
use a fixed `+app` namespace for every app. `apps/<family>/private/` should be
reserved for helpers that are genuinely shared by multiple apps in that family
and are not ready for a reusable `+labkit` facade.

Current image-measurement, electrochemistry, wearable, and DIC apps already
follow the app-owned package shape. Do not copy older family-level `private/`
helper layouts into new app work.

### App-Owned Package Shape

UI 2.0 migrations use role-based app packages. The standard is not that every
app owns every package; it is that a file lives under the package matching the
role it actually performs:

```text
<app_slug>/+ui/buildSpec.m     data-only UI 2.0 workbench spec
<app_slug>/+ui/build*.m        justified custom/tool UI builders only
<app_slug>/+state/*.m          state factories, defaults, and presets
<app_slug>/+io/*.m             file discovery, filters, readers, import parsing
<app_slug>/+ops/*.m            GUI-free calculations and transforms
<app_slug>/+view/*.m           tables, detail lines, display names, preview data
<app_slug>/+export/*.m         output writers, manifests, summary tables
```

For a migrated UI 2.0 app, the public `labkit_<AppName>_app.m` entry point or
the app-owned orchestration runner it delegates to owns launch/debug routing,
app state, callback closures, alerts, log wording, and refresh order. That
orchestration source should call `<app_slug>.ui.buildSpec(...)` and
`labkit.ui.app.create(...)` rather than hand-writing ordinary layout. Keeping
nested callbacks in the runner is acceptable when they need closure access to
app state and UI registry handles.

`+ui/buildSpec.m` returns only a data-only `labkit.ui.spec.*` tree. It may read
initial labels, defaults, callback handles, filters, and initial display data
from app-owned helpers, but it must not create MATLAB UI handles, call
`labkit.ui.app.create`, mutate app state, perform IO, run computations, write
exports, or set row/column layout mechanics. Custom UI belongs in a named
`+ui/build<Thing>.m` file only when an interaction cannot be represented by the
ordinary spec grammar.

File names should describe stable roles or outputs, not temporary
implementation buckets. Avoid names such as `helpers.m`, `utils.m`, `common.m`,
`misc.m`, `callbacks.m`, `manager.m`, `processor.m`, `layout.m`, and
`createUI.m`; prefer names such as `buildSpec.m`, `resultTableData.m`,
`detailLines.m`, `readImages.m`, `computeFocusStack.m`, `buildManifest.m`, or
`emptyResult.m`.

## Current Temporary Debt Inventory

This inventory is a narrow exception list, not a preferred design. It should
stay empty unless a future migration records a specific temporary exception.

Allowed oversized app-runner debt:

```text
none
```

Allowed app `private/` debt:

```text
none
```

Private helper contract debt:

```text
none
```

DIC Preprocess and DIC Postprocess both live under app folders with app-owned
packages. Public entry points own GUI state, callbacks, debug launch routing,
and user-facing log wording. Runner migration procedure lives in
`.agents/migration_guide.md` when active runner debt exists.

The wearable ECG Print app has moved to
`apps/wearable/ecg_print/labkit_ECGPrint_app.m` plus
`apps/wearable/ecg_print/+ecg_print/...`. The public launch command remains
`labkit_ECGPrint_app`.

Allowed electrochemistry string-dispatch debt: none. The former app-owned
`+core/dispatch.m` routers have been replaced by component-local package
functions. New apps and new migrations should not add `private` runners,
`*Workflow.m` adapters, or `+core/dispatch.m` routing layers.

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

The default automated validation boundary is the non-GUI MATLAB build task: project architecture checks, `labkit` facade/parser checks, and pure app analysis/export checks. GitHub Actions runs that task on pushes and pull requests for every branch.

GUI launch/layout checks live in source-aligned build tasks such as `testLabkitUiGui` and `testAppsGui`. Interactive GUI workflows are validated manually in MATLAB app windows. See `docs/testing.md` for the canonical validation matrix.

## Current Package Surface

- `labkit.ui.app`: declarative app creation, legacy shell specs, tab specs, internal request dispatch, and busy-state feedback.
- `labkit.ui.spec`: data-only UI 2.0 workbench specs for tabs, sections, fields, actions, path panels, previews, results, logs, status, and custom tool slots.
- `labkit.ui.view`: semantic UI 2.0 state helpers, sections, unified form controls, file panels, logs, tables, listbox state, axes reset/popout, image display, and prepared-X/Y plotting.
- `labkit.ui.tool`: interaction runtime, anchor editing, scale-bar tool, and scale-bar calibration.
- `labkit.ui.diag`: debug context, visible trace, callback instrumentation, and log mirroring.
- `labkit.dta`: DTA file discovery, type detection, single/batch/folder loading, pulse detection, item construction behind the facade, parsed table/curve access, session save/load, and session add/remove/select operations.
- `labkit.biosignal`: MAT timetable and delimited table recording loading, channel extraction, time ROI cropping, filtering, ECG/QRS peak detection, event-centered segmentation, template construction, template-residual SNR-style measurements, and group comparisons.

Public `+io`, `+data`, `+analysis`, and `+util` package surfaces should not be reintroduced as app-facing APIs.

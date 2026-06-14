# Architecture

LabKit is an app-first MATLAB workbench. Apps are the deliverables; `+labkit`
is the small reusable foundation they share.

## Project Model

```text
apps/      workflow-specific GUI apps and app-owned helpers
+labkit/   reusable UI, DTA, and biosignal facades
tests/     behavior tests, project contracts, smoke checks, and GUI checks
docs/      human-facing usage, API, architecture, and validation docs
scripts/   shell/Python support utilities for MATLAB batch runs and CI summaries
```

Apps should remain independently launchable. The reusable library should grow
only when a helper is domain-neutral, app-facing, tested, and useful beyond one
workflow.

## Runtime Entrypoints

Users normally start with:

```matlab
labkit_launcher
```

The launcher discovers `apps/**/labkit_*_app.m`. Public app command names are
stable user entry points, for example `labkit_CIC_app`,
`labkit_DICPreprocess_app`, `labkit_ECGPrint_app`, and
`labkit_ProjectGovernance_app`.

`startup_labkit` configures the MATLAB path. Local MATLAB Project metadata can
be created from `labkit_ProjectGovernance_app`; `LabKit.prj` and
`resources/project/` are not tracked.

## Ownership Boundaries

| Area | Owns |
| --- | --- |
| App entry point | Public launch name and debug dispatch. |
| App package | Workflow state, callbacks, calculations, summaries, exports, and app-local helpers. |
| `labkit.ui` | App shell, data-only UI specs, semantic view updates, reusable tools, and diagnostics. |
| `labkit.dta` | GUI-free Gamry DTA loading, sessions, parsed curves, and pulse helpers. |
| `labkit.biosignal` | GUI-free recording import, channel extraction, filtering, events, segments, templates, and measurements. |

Apps own experiment-specific vocabulary, thresholds, units, plots, result
schemas, export formats, alerts, and log wording. Reusable facades own
domain-neutral mechanics that multiple apps can share.

## App Package Shape

The standard app shape is:

```text
apps/<family>/<app_slug>/labkit_<AppName>_app.m
apps/<family>/<app_slug>/+<app_slug>/run.m
apps/<family>/<app_slug>/+<app_slug>/+ui/buildSpec.m
```

Optional role packages:

```text
+state/    defaults, factories, presets
+io/       file discovery, filters, readers, import parsing
+ops/      GUI-free calculations and transforms
+view/     tables, detail lines, display names, preview data
+export/   output writers, manifests, summary tables
```

Create only the packages the app needs. Package names match the app slug.
Avoid fixed `+app` namespaces, family-level `private/` helpers,
`*Workflow.m` string dispatchers, and `+core/dispatch.m` routers.

## UI Boundary

App GUIs use the layered UI foundation:

| Layer | App-facing API |
| --- | --- |
| App | `labkit.ui.app.create`, `dispatchRequest`, `runBusy` |
| Spec | `labkit.ui.spec.app`, `workspace`, `tab`, `section`, `field`, `rangeField`, `action`, `actionGroup`, `pathPanel`, `previewArea`, `resultTable`, `logPanel`, `statusPanel`, `custom` |
| View | `labkit.ui.view.setValue`, `getValue`, `setEnabled`, `appendLog`, `setListItems`, `setListSelection`, `drawImage`, `resetAxes`, `clearAxes` |
| Tool | `labkit.ui.tool.createRuntime`, `anchorEditor`, `scaleBar`, `scaleBarCalibration` |
| Diagnostics | `labkit.ui.diag.createContext` |

`+ui/buildSpec.m` returns a data-only `labkit.ui.spec.*` tree. It should not
create MATLAB UI handles, mutate app state, perform IO, run calculations, write
exports, or set row/column layout mechanics. The app runner owns state,
callbacks, alerts, refresh order, and log wording.

## Reusable Extraction Rule

A helper may move into `+labkit` only when all of these are true:

- It can be named without experiment-specific vocabulary.
- It does not encode app-specific units, thresholds, plots, result columns, or export schemas.
- It does not read or mutate app state.
- It is independently testable.
- At least two real apps use it, or one facade clearly needs it.
- It makes the app-facing API clearer rather than broader and vaguer.

If those conditions are not met, keep the helper app-local.

## Current Exceptions

Current architecture exceptions: none.

## Validation Boundary

The default automated validation boundary is:

```bash
buildtool test
```

This covers project contracts, reusable facade behavior, and non-GUI app
helper behavior. GUI checks cover launch, layout, callback wiring, and trace
plumbing. Manual MATLAB review is still required for full interactive workflow
feel.

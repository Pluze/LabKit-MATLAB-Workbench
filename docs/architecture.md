# Architecture

LabKit is an app-first MATLAB workbench. Apps are the deliverables; `+labkit`
is the small reusable foundation they share.

## Project Model

```text
apps/      workflow-specific GUI apps and app-owned helpers
+labkit/   reusable UI, image, DTA, RHS, and biosignal facades
tests/     behavior tests, project contracts, GUI checks, shared helpers, and runner code
docs/      human-facing usage, API, architecture, and validation docs
scripts/   CI helper scripts
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
`labkit_RHSPreview_app`.

The launcher is intentionally self-contained: it uses native MATLAB UI and
local helper functions so users can repair a damaged zip install even if
packages, apps, docs, or scripts have been deleted. It configures the MATLAB
path for app entry points. MATLAB desktop project metadata belongs to each
developer's local workspace.

## Ownership Boundaries

| Area | Owns |
| --- | --- |
| App entry point | Public launch name and debug dispatch. |
| App package | Workflow state, callbacks, calculations, summaries, exports, and app-local helpers. |
| `labkit.ui` | App shell, data-only UI specs, semantic view updates, reusable tools, and diagnostics. |
| `labkit.image` | GUI-free image file IO, display normalization, resizing, mean filtering, and basic enhancement primitives. |
| `labkit.dta` | GUI-free Gamry DTA discovery, loading, parsed curves, and pulse helpers. |
| `labkit.biosignal` | GUI-free recording import, channel extraction, filtering, events, segments, templates, and measurements. |
| `labkit.rhs` | GUI-free Intan RHS discovery, header parsing, block indexing, and lazy waveform window reads. |

Apps own experiment-specific vocabulary, thresholds, protocol roles, plots,
result schemas, export formats, alerts, and log wording. Reusable facades own
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
| App | `labkit.ui.app.create`, `dispatchRequest`, `appVersionTitle`, `applyVersionTitle`, `defaultDialogFolder`, `defaultOutputFolder`, `promptOutputFile`, `promptOutputFolder`, `runBusy` |
| Spec | `labkit.ui.spec.app`, `workspace`, `tab`, `section`, `field`, `rangeField`, `panner`, `action`, `actionGroup`, `filePanel`, `previewArea`, `resultTable`, `logPanel`, `statusPanel`, `usagePanel` |
| View | `labkit.ui.view.setValue`, `getValue`, `getFiles`, `setFileSelection`, `setEnabled`, `setLimits`, `appendLog`, `setListItems`, `setListSelection`, `fileLabels`, `filePaths`, `drawImage`, `resetAxes`, `clearAxes` |
| Tool | `labkit.ui.tool.createRuntime`, `anchorEditor`, `scaleBar`, `scaleBarCalibration`, `zoomAxesAtPoint` |
| Diagnostics | `labkit.ui.diag.createContext` |

Reusable facades publish MATLAB-native contract versions through their
`version()` APIs. Apps declare required facade ranges through app-local
`requirements.m` functions, and `labkit.contract` checks those ranges in tests
and at launch. This is a same-repo maintenance guardrail; routine users still
update LabKit as one repository.

Apps also publish app-local `version.m` metadata for display in the launcher and
app window title. App versions are not dependency constraints and do not belong
in `labkit.contract`. Project guardrails check `X.Y.Z` format and require
versioned code changes to increase the corresponding app, launcher, or facade
version.

Image workflows may use `labkit.image` for generic image file filters, source
image reads, display-name normalization, RGB double conversion, preview-size
fitting, mean filtering, basic enhancement primitives, and image writes. Apps
still own processing step semantics, ROI/background policy, matching formulas,
crop geometry, focus-stack algorithms, DIC behavior, export schemas, and user
workflow text.

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

## Extraction Quality

Line budgets are maintainability backstops, not architecture goals. A smaller
file is only better when the responsibilities are clearer.

Extracted helpers should own a coherent behavior contract: a stable data shape,
an explicit side effect, a GUI-free calculation, an export boundary, a display
model, or a reusable app-facing framework mechanism. Trivial label formatters,
single boolean checks, constant lists, and one-call facade wrappers can remain
local, nested, or inline when that makes the workflow easier to follow.

There is no minimum useful helper length. Small public facades, factories,
filters, defaults, and test-facing helpers are valid when the name protects a
real contract. Conversely, a long extracted helper is not reusable merely
because it moved out of `run.m`; it must improve ownership, testability, or the
app-facing API.

## Current Exceptions

Current architecture exceptions: none.

## Validation Boundary

The default automated validation boundary is:

```bash
buildtool headless
```

This covers project contracts, reusable facade behavior, and non-GUI app
helper behavior. GUI checks cover launch, layout, callback wiring, trace
plumbing, reusable tool lifecycle, and hidden synthetic app workflows. Manual
MATLAB review is still required for full interactive workflow feel.

# Architecture

[Development index](README.md) | [Public API index](../libraries/README.md)

LabKit is an app-first MATLAB workbench. Apps are the deliverables; `+labkit`
is the small reusable foundation they share.

## Project Model

```text
apps/      workflow-specific GUI apps and app-owned helpers
+labkit/   reusable UI, image, thermal, DTA, RHS, and biosignal facades
tests/     behavior tests, project contracts, GUI checks, shared helpers, and runner code
docs/      human-facing usage, API, architecture, and validation docs
scripts/   CI helper scripts
tools/     maintainer diagnostics, deployment packagers, and report generators
```

Apps should remain independently launchable. The reusable library should grow
only when a helper is domain-neutral, app-facing, tested, and useful beyond one
workflow.

## Runtime Dependency Boundary

LabKit apps run from MATLAB and repository-owned code. Production apps and
facades do not create Python or Conda environments, install third-party runtime
packages, download model weights, or require a network connection on first
use. This keeps source checkouts, offline packages, and restored lab systems
reproducible.

During rapid development, an app may temporarily accelerate a capability with
a MathWorks Toolbox only when it also ships a repository-owned base-MATLAB
implementation with comparable user-visible behavior. The app must remain
usable without the product, and automated tests must exercise that fallback.
When values feed scientific interpretation, branching, exports, or later
calculations, identical inputs must be idempotent: pure calculations reproduce
the same app-consumed values, while safely repeated stateful operations do not
compound state or side effects. A parity
test must compare app-consumed outputs against the Toolbox reference within a
documented tolerance. Visual similarity is not sufficient evidence.
The exact source, symbol, product, owner, fallback evidence, and replacement
plan plus fallback, idempotency, and parity evidence are recorded as active migration debt. Dependency analysis continues to
report the Toolbox call; hiding it behind reflection or string dispatch is not
an accepted compatibility technique. The debt closes by removing the Toolbox
branch once the owned implementation replaces it.

Adding any third-party runtime remains an architecture and deployment decision
requiring explicit approval; it is not an ordinary app-local implementation
choice.

## Runtime Entrypoints

Users normally start with:

```matlab
labkit_launcher
```

The launcher discovers public `apps/**/labkit_*_app.m` entry points. Public app
command names are stable user entry points, for example `labkit_CIC_app`,
`labkit_DICPreprocess_app`, `labkit_ECGPrint_app`, and
`labkit_RHSPreview_app`.

Source checkouts may also keep local private apps under an ignored
`private_apps/apps/` workspace or roots named by `LABKIT_PRIVATE_APP_ROOTS`.
Any developer can create that local workspace for their own private apps. The
launcher can list and launch those apps with `Visibility` set to `private`, but
the public repository, release artifacts, and CI guardrails own only the public
`apps/` tree. Keep each private workspace as a separate private Git repository
rather than mixing private app files into the public repo history. The public
structure guide is [private-apps.md](private-apps.md); private app
documentation belongs in the private workspace.

The launcher keeps update, discovery, and repair logic self-contained: it uses
native MATLAB UI and local helper functions so users can repair a damaged zip
install even if packages, apps, docs, or scripts have been deleted. It
configures the MATLAB path for app entry points. MATLAB desktop project
metadata belongs to each developer's local workspace.

Tools under `tools/` are source-checkout support utilities rather than app
runtime APIs. The launcher may call a small, explicit subset for maintenance
and deployment actions, such as profiling a selected app or packaging a single
app for offline deployment. Single-app deployment packages include the launcher
and only those launcher-needed tool folders, not the whole source checkout.

## Ownership Boundaries

| Area | Owns |
| --- | --- |
| App entry point | Public launch name plus requirements/version/debug request routing. |
| App package | App definition, workflow state, command handlers, presenters, calculations, summaries, exports, and app-local helpers. |
| `labkit.ui` | Declarative app runtime, app shell, readiness/busy state, data-only workbench layouts, semantic view updates, reusable tools, and diagnostics. |
| `labkit.image` | GUI-free image file IO, display normalization, resizing, mean filtering, and basic enhancement primitives. |
| `labkit.thermal` | GUI-free thermal source-file parsing, raw thermal matrices, embedded calibration metadata, raw-to-temperature conversion, and thermal colormap rendering. |
| `labkit.dta` | GUI-free Gamry DTA discovery, loading, parsed curves, and pulse helpers. |
| `labkit.biosignal` | GUI-free recording import, channel extraction, filtering, events, segments, templates, and measurements. |
| `labkit.rhs` | GUI-free Intan RHS discovery, header parsing, block indexing, and lazy waveform window reads. |

Apps own experiment-specific vocabulary, thresholds, protocol roles, plots,
result schemas, export formats, alerts, and log wording. Reusable facades own
domain-neutral mechanics that multiple apps can share.

## App Package Shape

The target app shape is workflow-first. Each app keeps one MATLAB package under
its app folder:

```text
apps/<family>/<app_slug>/labkit_<AppName>_app.m
apps/<family>/<app_slug>/+<app_slug>/definition.m
apps/<family>/<app_slug>/+<app_slug>/requirements.m
apps/<family>/<app_slug>/+<app_slug>/version.m
apps/<family>/<app_slug>/+<app_slug>/definitionActions.m
apps/<family>/<app_slug>/+<app_slug>/+appLifecycle/createProject.m
apps/<family>/<app_slug>/+<app_slug>/+appLifecycle/createSession.m
apps/<family>/<app_slug>/+<app_slug>/+appLifecycle/validateProject.m
apps/<family>/<app_slug>/+<app_slug>/+userInterface/buildWorkbenchLayout.m
apps/<family>/<app_slug>/+<app_slug>/+userInterface/presentWorkbench.m
```

Add workflow packages only when the app has that user-facing capability:

```text
+sourceFiles/     choosing, reading, validating, and previewing source data
+analysisRun/     collecting options, computing results, and showing results
+resultFiles/     choosing output folders, writing files, and summarizing exports
+cropGeometry/    app-owned crop geometry operations
+thermalFrames/   app-owned thermal frame queues and display choices
+debugArtifacts/  app-owned clean-room sample and debug artifact generation
```

Create only the packages the app needs. Names should describe a workflow or
domain capability that changes together, not a broad technical phase. Avoid
generic `+actions`, `+renderers`, `+ops`, `+io`, `+export`, `+helpers`, and
`+utils` packages for new app code. Avoid fixed `+app` namespaces,
family-level `private/` helpers, `*Workflow.m` string dispatchers, and
`+core/dispatch.m` routers.

`+state`, `+actions`, `+ui`, `+view`, `+ops`, `+io`, and `+export` packages
were retired with the workflow-first migration. Current app work should follow
the workflow-first shape.

## UI Boundary

App GUIs use the layered UI foundation:

| Layer | App-facing API |
| --- | --- |
| Runtime | `labkit.ui.runtime.launch`, `define`, `emptySourceRecords`, `saveState`, `loadState`, portable source references, and source-adjacent output defaults; the runtime privately owns request dispatch, queueing, resources, presentation, interactions, recovery, diagnostics, and result manifests. |
| Layout | `labkit.ui.layout.workbench`, `workspace`, `tab`, `section`, `group`, `field`, `rangeField`, `panner`, `action`, `filePanel`, `previewArea`, `resultTable`, `logPanel`, `statusPanel` |
| Plot | Advanced renderer helpers: `clear`, `fit`, `fitCanvas`, `offsetData`, `clampData`, `message` |
| Interaction | GUI-free `anchorPath`, `scaleBarCalibration`, `scaleBarGeometry`, plus `enablePopout`; editor/runtime objects are private. |

Reusable facades publish MATLAB-native contract versions through their
`version()` APIs. Apps declare required facade ranges through app-local
`requirements.m` functions, and `labkit.contract` checks those ranges in tests
and at launch. This is a same-repo maintenance guardrail; routine users still
update LabKit as one repository.

Apps also publish app-local `version.m` metadata for display in the launcher and
app window title. App versions are not dependency constraints and do not belong
in `labkit.contract`. Project guardrails check `X.Y.Z` format and require
versioned code changes to increase the corresponding app, launcher, or facade
version. Pick the next version from the version file in the latest `main`
commit, not from intermediate local working-tree edits made during an
unfinished migration. Feature-branch work may batch that version bump into the
final squash, PR handoff, or direct `main` integration step.

Image workflows may use `labkit.image` for generic image file filters, source
image reads, display-name normalization, RGB double conversion, preview-size
fitting, mean filtering, basic enhancement primitives, and image writes. Apps
still own processing step semantics, ROI/background policy, matching formulas,
crop geometry, focus-stack algorithms, DIC behavior, export schemas, and user
workflow text.

Thermal workflows may use `labkit.thermal` for radiometric source reads,
embedded calibration metadata, raw thermal matrices, Celsius conversion, and
linear thermal palette rendering. Apps still own file queues, display-range
defaults, log/gamma display-mapping controls, export manifests, colorbar
placement, overlay-removal workflow wording, measurements, and user-facing
decisions. Generic image IO and filters stay in `labkit.image`; thermal file
parsing and raw-to-temperature mechanics stay in `labkit.thermal`.

`definition.m` returns the app runtime contract. It names the project schema,
optional session factory, data-only layout builder, handler registry,
presenter, renderers, and optional `Start`. The framework runtime validates
the definition, generates semantic callbacks, builds the shell, owns the event
queue and readiness/busy state, routes diagnostics, and
protects hidden test behavior.

`+userInterface/buildWorkbenchLayout.m` returns a data-only `labkit.ui.layout.*`
tree. It should not create MATLAB UI handles, mutate app state, perform IO,
run calculations, write exports, schedule startup, or set row/column layout
mechanics. App command handlers own app-specific state changes, alerts, refresh
decisions, and log wording. `+userInterface/presentWorkbench.m` is the pure
bridge from canonical state to semantic control properties, prepared preview
models, and controlled interaction specs.

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
app-facing API. When reviewing helper organization, prefer evidence from the
helper's boundary role, call sites, tests, side effects, and ownership over raw
line count.

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

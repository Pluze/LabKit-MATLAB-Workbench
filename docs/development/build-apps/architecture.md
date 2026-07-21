# Architecture

[Development index](../README.md) | [Public API index](../../reference/README.md) |
[LabKit Launcher](../../apps/labkit-core/launcher/README.md) |
[Maintainer Tools](../tools/README.md)

LabKit is an app-first MATLAB workbench. Apps are the deliverables; `+labkit`
is the small reusable foundation they share.

## Project Model

```text
apps/      workflow-specific GUI apps and app-owned helpers
+labkit/   reusable UI, image, thermal, DTA, RHS, and biosignal facades
tests/     behavior tests, project contracts, GUI checks, shared helpers, and runner code
docs/      human-facing usage, API, architecture, and validation docs
tools/     maintainer diagnostics, deployment packagers, and report generators
.github/scripts/  GitHub Actions-only helper scripts
```

The repository root has no generic `scripts/` bucket. Keep automation beside
its single consumer; promote it to a shared owner only when several stable
consumers genuinely need the same operation.

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
compound state or side effects. A parity test must compare app-consumed outputs
against the Toolbox reference within a documented tolerance. Visual similarity
is not sufficient evidence.

Record each temporary Toolbox dependency with its source function, MathWorks
product, responsible app, fallback tests, idempotency/parity evidence, and
replacement plan. Dependency reports continue to show the Toolbox call while
that debt is open. The debt closes when the repository implementation replaces
the Toolbox branch and the branch is removed.

Adding any third-party runtime remains an architecture and deployment decision
requiring explicit approval; it is not an ordinary app-local implementation
choice.

## Version Ownership

Facade and App compatibility is expressed by the existing version metadata and
dependency-requirement components. Saved-data schemas keep explicit numeric
versions only inside their persistence and migration contracts. Release and
history records preserve the versions needed as evidence.

Architecture concepts themselves are versionless. Packages, folders, files,
functions, classes, type tags, protocol names, tests, and current manuals use
stable semantic names. An incompatible redesign replaces the owning contract
and updates version metadata; it does not create a second version-named
architecture.

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
public releases and CI checks cover only the public `apps/` tree. Keep each
private workspace as a separate private Git repository
rather than mixing private app files into the public repo history. The public
structure guide is [private-apps.md](../maintain-and-release/private-apps.md); private app
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
Direct syntax, options, outputs, and artifact behavior are documented in
[Maintainer Tools](../tools/README.md).

## Ownership Boundaries

| Area | Owns |
| --- | --- |
| App entry point | Public launch name delegated to one runtime definition, including lightweight requirements/version/debug requests. |
| App package | App definition, workflow state, command handlers, presenters, calculations, summaries, exports, and app-local helpers. |
| `labkit.app` | App definition and launch, semantic layout and view snapshots, typed events, callback capabilities, projects, diagnostics, results, interactions, and private native runtime lifecycle. |
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
apps/<family>/<app_slug>/+<app_slug>/+workbench/buildLayout.m
```

Those three files are a complete static App. Add only the capabilities the
product needs:

```text
projectSpec.m                               durable create/validate/migrate contract
createSession.m                             transient App-specific reconstruction
+workbench/present.m                        dynamic snapshot assembly
+<workflowCapability>/layoutSection.m       feature-owned controls
+<workflowCapability>/present.m             feature-owned snapshot fragment
+<workflowCapability>/draw.m                feature-owned plot renderer
```

`definition.m` is the single product contract. It owns identity, display
metadata, App version, facade requirements, layout, and references to any
optional capabilities. `projectSpec.m` is the one durable-schema entry and
keeps its create, validate, and version-aware migrate functions local. Runtime
owns the migration loop. Do not add separate `requirements.m`, `version.m`,
generic `+appLifecycle` or `+appState` packages, or per-version migration
files.

Add workflow packages only when the App has that user-facing capability:

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
generic `+actions`, `+renderers`, `+ops`, `+io`, `+ui`, `+userInterface`,
`+view`, `+export`, `+helpers`, and `+utils` packages for new app code. Avoid fixed `+app` namespaces,
family-level `private/` helpers, `*Workflow.m` string dispatchers, and
`+core/dispatch.m` routers.

`+state`, `+actions`, `+ui`, `+view`, `+ops`, `+io`, and `+export` packages
were retired with the workflow-first migration. Current app work should follow
the workflow-first shape.

## App SDK Boundary

App GUIs use the explicit `labkit.app` SDK:

| Layer | App-facing API |
| --- | --- |
| Definition | `labkit.app.Definition` owns identity, requirements, optional project/session boundaries, workbench, presentation, and launch. |
| Layout | `labkit.app.layout.*` owns semantic controls, containers, workspace pages, direct callbacks, bindings, and plot renderers. |
| View | `labkit.app.view.Snapshot` owns complete derived visible state and prepared renderer models. |
| Callback boundary | Typed `labkit.app.event.*` values and sealed, specifically named `labkit.app.CallbackContext` operations. |
| Optional contracts | `labkit.app.project.*`, `result.*`, and `dialog.*`. |

Reusable facades publish MATLAB-native contract versions through their
`version()` APIs. Apps declare required facade ranges in the `Requirements`
field of `definition.m`, and `labkit.contract` checks those ranges in tests and
at launch. This is a same-repo maintenance guardrail; routine users still
update LabKit as one repository.

Apps publish `AppVersion` and `Updated` metadata from the same definition for
the launcher and window title. App versions are not dependency constraints and
do not belong in `labkit.contract`. Project guardrails check `X.Y.Z` format and
require versioned code changes to increase the corresponding definition,
launcher, or facade version. The [release guide](../maintain-and-release/release.md) explains how to
select and publish the next version.

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

`definition.m` returns the app runtime contract. Layout nodes own concrete
callbacks and renderers, so Apps maintain no parallel registries. The
framework compiles the static graph, builds the shell, owns the transactional
event queue, persistence, resources, diagnostics, and private native adapter.

`+workbench/buildLayout.m` should read as the product's user workflow.
Capability packages own their controls, state transitions, prepared view
models, rendering, alerts, and wording. `+workbench/present.m` extracts exact
state inputs and composes those feature fragments; it is not a second
monolithic implementation of the App.

### The state funnel

The runtime commits one canonical value containing `project` and `session`,
but that value is an SDK transaction envelope, not the App's domain model.
Keep it at the edge:

```text
layout signal
    -> capability action(applicationState, event, callbackContext)
        -> calculation(exact scientific inputs)
        -> writer(exact result and destination inputs)

runtime presentation
    -> workbench.present(applicationState)
        -> capability.present(exact visible inputs)
            -> renderer(axes, prepared model)
```

Only `createSession`, `workbench.present`, `OnStart`, and a function bound
directly to a layout signal accept the complete envelope. Those functions
name it `applicationState`, expose the typed event and `callbackContext` in
their signatures, and unpack it immediately. Feature presenters, renderers,
calculations, writers, and local helpers receive named narrow inputs.

Do not introduce a second App object, service bag, callback registry, or
feature-wide context type to hide these inputs. If a calculation needs five
scientific values, list those five values. If several always travel together
and form a stable app-owned concept, give that concept a semantic struct and
validate it at its owner.

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
line count. Repository line budgets count effective MATLAB code lines: blank
lines and comment-only documentation do not consume the budget. Physical line
counts remain useful diagnostic context, but they must not discourage complete
function help.

## Validation Boundary

The default automated validation boundary is:

```bash
buildtool headless
```

This covers project contracts, reusable facade behavior, and non-GUI app
helper behavior. GUI checks cover launch, layout, callback wiring, trace
plumbing, reusable tool lifecycle, and hidden synthetic app workflows. Manual
MATLAB review is still required for full interactive workflow feel.

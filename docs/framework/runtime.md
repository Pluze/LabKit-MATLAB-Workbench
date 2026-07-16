# Runtime And Lifecycle

[Public API index](../libraries/README.md) | [App development](../development/app-development.md)

This page explains how a LabKit app is declared, launched, updated, saved, and
debugged. The current runtime manages queued events, project and session state,
presentation, resources, interactions, saved projects, and result manifests.
Old runtime snapshots can still be imported, but new apps use the current
lifecycle exclusively.

`labkit.ui` is divided into these public packages:

| Package | Owns | Main APIs |
| --- | --- | --- |
| `labkit.ui.runtime` | Launch, canonical state, queued events, services, projects, and resources. | `launch`, `define`, `emptySourceRecords`, `saveState`, `loadState`, `createPortableFileReference`, `resolvePortableFileReference`, `defaultOutputFolder`. |
| `labkit.ui.layout` | Data-only semantic workbench layouts. | `workbench`, `workspace`, `tab`, `section`, `group`, `field`, `rangeField`, `panner`, `action`, `filePanel`, `previewArea`, `resultTable`, `logPanel`, `statusPanel`. |
| `labkit.ui.plot` | Advanced renderer viewport and coordinate mechanics. | `clear`, `fit`, `fitCanvas`, `message`, `offsetData`, `clampData`. |
| `labkit.ui.interaction` | Managed-interaction calculation helpers and popout enablement. | `anchorPath`, `scaleBarCalibration`, `scaleBarGeometry`, `enablePopout`. |

Apps call the package that provides the behavior they need. The earlier flat
`labkit.ui.*` helper surface is no longer supported, and implementation details
inside each package's `private/` folder are not public APIs.

`labkit.ui.version()` returns the UI framework's version and compatibility
information for `labkit.contract` requirement checks.

## Declarative App Runtime

### Definition And Launch

The UI surface makes app code read as a semantic description of a LabKit
workflow, not as grid construction or a general MATLAB GUI DSL. Apps expose an
app-owned `definition.m` and launch it through `labkit.ui.runtime.launch`. The
framework owns lifecycle, callback dispatch, readiness, busy state,
diagnostics, persistence, and resources. App packages declare durable project
data, transient session data, workflow handlers, presentation, and data-only
UI structure.

Public launch files stay thin. They route requests, expose requirements and
version metadata, and delegate the GUI to the framework runtime:

```matlab
function varargout = labkit_Example_app(varargin)
    [varargout{1:nargout}] = labkit.ui.runtime.launch( ...
        @example.definition, @example.requirements, @example.version, ...
        varargin{:});
end
```

```matlab
function def = definition()
def = labkit.ui.runtime.define( ...
    "Id", "example", ...
    "Title", "Example App", ...
    "Project", example.projectSpec(), ...
    "CreateSession", @example.createSession, ...
    "Layout", @example.userInterface.buildWorkbenchLayout, ...
    "Actions", example.definitionActions(), ...
    "Present", @example.userInterface.presentWorkbench, ...
    "Renderers", example.userInterface.previewRenderers(), ...
    "Start", "start");
end
```

`definition.m` is a small MATLAB-scale DSL made of structs and function
handles. It is not a new language, a generator, or a class hierarchy. The
framework validates the definition, creates canonical state, generates
callbacks, builds the workbench, commits the first presentation, and queues
the optional `Start` event. App-specific launch payloads are available
read-only through injected services.

Apps use `projectSpec.m`, `createSession.m`, `definitionActions.m`, and
`+userInterface`;
app-specific work belongs in concrete workflow packages such as
`+sourceFiles`, `+analysisRun`, `+resultFiles`, or a domain-specific package.
The older `+state`, `+actions`, `+ui`, and `+view` adapter packages have been
retired.

```matlab
function layout = buildWorkbenchLayout(callbacks)
layout = labkit.ui.layout.workbench("exampleApp", "Example App", ...
    "controlTabs", controlTabs(callbacks), ...
    "workspace", previewWorkspace(callbacks), ...
    "usage", {"Load input data.", "Run analysis.", "Review/export results."});
end

function tabs = controlTabs(callbacks)
    tabs = {setupTab(callbacks), reviewTab(), logTab()};
end

function tab = setupTab(callbacks)
    tab = labkit.ui.layout.tab("setup", "Setup", { ...
        labkit.ui.layout.section("actions", "Actions", { ...
            labkit.ui.layout.action("run", "Run", callbacks.run, ...
                "priority", "primary"), ...
            labkit.ui.layout.action("reset", "Reset", callbacks.reset)})});
end

function tab = reviewTab()
    tab = labkit.ui.layout.tab("review", "Review", { ...
        labkit.ui.layout.section("results", "Results", { ...
            labkit.ui.layout.resultTable("resultsTable", "Results", ...
                "columns", {"Name", "Status"})})});
end

function tab = logTab()
    tab = labkit.ui.layout.tab("log", "Log", { ...
        labkit.ui.layout.section("logSection", "Log", { ...
            labkit.ui.layout.logPanel("appLog", "Log")})});
end

function workspace = previewWorkspace(callbacks)
    workspace = labkit.ui.layout.workspace("workspace", "Preview", { ...
        labkit.ui.layout.previewArea("preview", "Preview", ...
            "layout", "single", ...
            "viewModes", {"Input", "Output"}, ...
            "onModeChange", callbacks.previewModeChanged)});
end
```

`buildWorkbenchLayout.m` stays data-only. It receives framework-generated
semantic callbacks and returns a workbench layout. It does not create MATLAB
handles, run IO, compute data, mutate app state, schedule startup work, or set
concrete layout geometry.

### Layout And Action Rules

Use these app-facing rules:

- The default shell is a LabKit workbench: control tabs on the left and primary
  preview, plot, waveform, image, or canvas content on the right.
- `definition.m` declares app identity, project schema, optional session
  factory, workbench layout, handler registry, presenter, prepared-data
  renderers, and optional `Start` event.
- The framework runtime owns lifecycle scheduling, readiness/loading surface,
  generated callbacks, busy gating, debug exception plumbing, close guards, and
  hidden/minimized test behavior.
- `buildWorkbenchLayout.m` describes controls and workspace structure only. App
  command handlers own app-specific state changes, alerts, refresh decisions,
  and log wording.
- Control ids are globally unique within an app. The UI registry is keyed by
  those ids, not by tab or section placement.
- Public layouts are semantic controls such as `filePanel`, `toolPanel`, `field`,
  `panner`, `action`, `previewArea`, `resultTable`, `logPanel`, and `statusPanel`.
  Primitive MATLAB controls are implementation details.
- `section` layout nodes should contain real semantic controls. Use `toolPanel` as a
  named host when a reusable `labkit.ui.interaction.*` control needs to attach a
  composed runtime widget from app command or UI-update code; do not leave
  empty titled sections as placeholders.
- Public callbacks use `function callback(control, event)`. Events carry
  semantic fields such as `id`, `kind`, `source`, `value`, `previousValue`,
  and `ui`.
- App handlers should be named by user intent. They receive semantic events
  and injected services, then return updated canonical state without directly
  mutating framework lifecycle state.

### Identity Contracts

Runtime ids are developer-owned semantic names, not generated object handles.
Name an object once at its declaration and reuse that id when referring to it;
the runtime validates the resulting graph before it mutates the visible UI.

| Identity | Scope and contract | Compatibility meaning |
| --- | --- | --- |
| App `Id` | Starts with an ASCII letter and contains only letters, digits, `_`, `-`, or `.`. Public app ids are unique across the app catalog. | Permanent after a project or recovery file has been written. Renaming it creates a different app identity. |
| Layout node id | Nonempty MATLAB field name, globally unique in one workbench tree. | Used to bind presenter controls and UI callbacks. |
| Preview axis id | Nonempty MATLAB field name, unique within its preview area and in the runtime axes registry. | Used by presenter axes models and `services.previews.axes`. |
| Action id | MATLAB struct field in `definitionActions`; every layout or interaction event reference must name a registered action. | Renaming requires updating every declaration that emits the event. |
| Renderer id | MATLAB struct field in `Renderers`; every presented renderer reference must name a registered renderer. | App-owned presentation contract. |
| Durable source id | Nonempty text, unique in `project.inputs.sources`. | Stable key for reconciliation and portable external-file references. |
| Result output id | Nonempty text, unique within one result manifest. | Stable machine-readable name for one exported artifact. |
| Resource id | Nonempty text paired with an event, interaction, or figure scope. | Calling `set` again with the same scope and id intentionally disposes and replaces the previous resource; use different ids for resources that coexist. |

Invalid declarations fail during definition, layout preparation, state
validation, or presentation preflight instead of silently overwriting a
registry entry. Recovery folders use a reversible encoded app id so distinct
legal ids cannot normalize to the same path. Discovery also checks the earlier
MATLAB-normalized folder name, allowing existing recovery files to remain
readable while all new writes use the collision-free key.

### File Selection And Dialogs

- `filePanel` owns file input mechanics: file chooser defaults, optional
  recursive folder scans, duplicate filename display, current selection, and
  file-entry events. Each file entry exposes `id`, `index`, `path`, `name`,
  `displayName`, and `status`. Callback events expose file entries through
  `event.files`, `event.addedFiles`, `event.removedFiles`,
  `event.selectedFiles`, and `event.value` for the current selection. Apps
  consume paths and indices through `services.events`; apps do not parse
  control ids, UI registries, or adapter structs.
- The active `filePanel` selection is also a framework title context. When a
  file is selected through the panel or a presentation commit, the
  app window title and preview axes titles include `file N/M: name.ext`; when
  selection is cleared, the framework removes that suffix. Apps should keep
  preview titles focused on the view or measurement being shown, not duplicate
  the selected filename in app-local title strings.
- Multi-file `filePanel` mode exposes direct commands for adding one or more
  files from one folder,
  every supported file directly under one folder, or every supported file
  recursively below a folder, plus Remove selected and Clear. Each command
  opens the native file or folder navigator immediately; there is no
  file-versus-folder question. The native file dialog supports ordinary
  same-folder multi-selection; separate folder commands cover directory-wide
  imports. Recursive folder scans count matching files first and ask
  for confirmation only when the count exceeds the panel warning threshold.
  File labels show sequence numbers plus
  short filenames, adding the nearest unique parent directory when repeated
  filenames would otherwise collide. Apps that allow duplicate source files
  should remove by file `id` or `index` from `event.removedFiles` instead of
  deleting by path. Programmatic file replacement uses
  presenter-owned `Value` and `Selection` properties. Apps with their own
  nearby status field can pass `showStatus=false` to omit the panel's internal
  count/status text.
- Single-file `filePanel` mode opens one file directly, replaces the previous
  file on the next choose action, does not offer recursive folder selection,
  and displays the short filename in one read-only text field instead of a
  selectable list.
- File and folder selection in handlers goes through `services.dialogs`, which
  owns safe remembered defaults outside the LabKit install root.
- App output defaults should be source-adjacent when a source file or folder is
  known. Use `labkit.ui.runtime.defaultOutputFolder(sourcePaths, subfolderName)`;
  the helper uses the first source path when multiple files are loaded and
  creates the app-specific subfolder before returning it.
- App-owned alerts use `services.dialogs.alert(message, title)`. Apps still own
  the wording and decision; the runtime owns modal and hidden-test mechanics.

### Saved Projects And Result Utilities

- `labkit.ui.runtime.saveState/loadState` retain one stable public signature.
  Apps write a versioned `labkitProject` envelope with only durable project
  buckets, ordered app payload migrations, producer
  provenance, optional resume data, and additive extension preservation.
  Loads inventory the MAT file before loading a recognized variable,
  migrate and validate off to the side, resolve required sources, create a
  fresh session, invalidate the previous document's presentation cache, and
  then replace live state and repaint every preview once. This repaint also
  occurs when the loaded project has the same semantic values as the current
  document, because ephemeral graphics are not durable state. Saves use
  temporary-file readback plus atomic replacement. Project edits drive the dirty title,
  debounced bounded recovery, and unsaved-close wording; recovery never owns
  or overwrites an explicit project path. Declared old snapshots and legacy
  app variables are import-only and are never written again.
- Apps whose saved state refers to external source files should store
  `labkit.ui.runtime.createPortableFileReference(anchorFile, targetFile)` in
  their app-owned project schema. On load,
  `resolvePortableFileReference(anchorFile, reference)` checks the path
  relative to the loaded project first, then the original absolute path, then
  the saved filename beside the project. Relative references use `/` inside
  MAT payloads, so a project/source directory tree can move between cloud-drive
  roots and operating systems. If a required source remains unresolved, the
  runtime identifies its saved filename and role, asks whether to locate it,
  and opens one file chooser for that source. A selected file receives a new
  reference relative to the loaded project before session creation. The
  repaired document opens as unsaved work so the new location can be retained;
  cancelling leaves the current project and view unchanged. Apps may declare
  `Project.RelinkSources` only when their source schema needs behavior beyond
  this standard source-record flow. Projects migrated from an older payload,
  snapshot, or declared legacy variable also open as unsaved work. **Save
  State** reuses the opened path and atomically replaces it with the current
  `labkitProject` format; opening alone never rewrites the source MAT file.

### Workbench Utilities And Preview Axes

- The workbench shell includes a native `Plot` menu plus top-level
  `Screenshot`, `Save State`, and `Load State` entries. Plot commands operate
  on every registered preview axes
  in the app, so multi-axes workspaces do not require users to repeat the same
  command per view. Apps can use
  `define(..., "Utilities", struct(...))` to hide the bar or disable groups of
  commands without adding app-local shell buttons. Utility commands operate on
  framework-owned runtime or visible preview axes; scientific result exports
  remain app-owned.
- `previewArea` belongs in `workspace` by default. Its optional `viewModes`
  selector is workspace-owned, and apps can react through `onModeChange`.
- `previewArea` axes install LabKit-managed, pointer-gated mouse-wheel zoom by
  default. Scrolling over controls, logs, or empty figure space does not zoom
  plots, and users should not need to click a preview before wheel zoom works.
  Time-series axes with a time x-label zoom the horizontal time axis only.
  Apps can set per-axis `scrollZoomAxes` values of `xy`, `x`, or `y` when a
  secondary fixed-width scale or histogram axis should receive wheel events
  without changing its horizontal span.
  Preview axes are also registered with the workbench utility menus, whose plot
  commands act on all registered visible axes.
- `labkit.ui.interaction.enablePopout(ax)` installs the standard axes context
  menu action, which copies the visible axes into a
  standalone MATLAB figure with optional copied-figure text buttons for font
  size, plotted data line width, axes line width, grid visibility, and a Studio
  handoff. Popout edits operate on the copied figure only. Plot axes remain
  freely resizable, while image axes preserve locked data aspect ratio.
  Data-package export and generated reconstruction scripts belong in the
  Figure Studio workflow rather than the lightweight popout window; app-owned
  scientific CSV/MAT result exports still belong in the app package.

### Parameter Controls And Layout Sizing

- Parameter value controls (`field`, `rangeField`, and `panner`) debounce
  semantic `onChange` callbacks by default so short bursts of edits submit
  only the latest value after roughly 0.5 seconds of idle time. Explicit
  actions, file selection, and table edits run immediately. Apps should put
  expensive recompute work behind those semantic callbacks or explicit action
  buttons rather than binding work to lower-level MATLAB value-changing events.
- `panner` is the preferred app layout control for bounded numeric parameters.
  It renders as a compact numeric spinner plus a linked slider when limits are
  finite, and as spinner-only when limits are intentionally unbounded. Slider
  drags update the numeric readout continuously and submit semantic changes
  through the same debounced callback queue as spinner edits; release submits
  the final committed value.
- Text-heavy controls have conservative automatic heights owned by the
  framework. App layout nodes must not set concrete height, row-count, spacing,
  padding, chrome, row-height, or column-width properties.
- Text-bearing controls default to complete display over single-line
  compactness. The framework enables wrapping where MATLAB supports it,
  shrinks long labels within a small readability range, gives text-heavy rows
  extra height, and keeps the full text available as a tooltip when supported.
  Apps should shorten wording when it improves workflow clarity, but should
  not add app-local layout or font-size patches to prevent clipping.
- Section height is automatic: the builder estimates height from child control
  types and framework spacing defaults. Apps declare only the page, section,
  and control order.
- `group` composes related semantic controls inside a section and replaces the
  older action-only grouping concept. Apps should use `group(id, "", {...})`
  for inline tool rows and `group(id, title, {...})` for titled subgroups.
  With `layout="auto"`, a group whose children are all `action` layout nodes uses the
  action layout; mixed controls use a compact form layout. Action groups wrap
  into at most two columns by default, collapse to one column for long labels,
  and let a single odd final action span the row. Apps should not create
  app-local button grids just to place several actions near each other.
- Use app-level `usage`/`usageTitle` on `labkit.ui.layout.workbench` for static
  workflow instructions. The framework places that read-only usage panel at the
  bottom of the first control tab.
- Presenter `Limits` and `Items` properties are committed before bound values;
  the runtime clamps or selects safely without firing app callbacks.

The public layout-node grammar is semantic: pages, sections, controls, order,
values, and callbacks. When a workflow needs a control that cannot be expressed
with the ordinary layout nodes, add a named framework or app-owned layout node
instead of placing
MATLAB layout code in `buildWorkbenchLayout.m`.

Control tabs with more than one section include draggable horizontal
separators by default. A tab may opt out with `resize="none"` when a fixed
stack is intentional.

### Runtime State And Transactions

A definition declares `Project`, optional `CreateSession`, `Actions`,
`Present`, optional `Renderers`, and optional `Start`. It launches through
`labkit.ui.runtime.launch`, which owns lightweight request dispatch, contract
checks, runtime creation, output normalization, and the versioned title.

V2 state has exactly two roots, `project` and `session`. Project contains
`inputs`, `parameters`, `annotations`, `results`, and `extensions`; session
contains `selection`, `workflow`, `view`, and `cache`. Both slices contain only
plain serializable MATLAB data. Graphics, listeners, timers, tools, callbacks,
services, and debug contexts stay in the framework resource registry.

Project factories use `labkit.ui.runtime.emptySourceRecords()`; the runtime owns
that shape, while handlers populate it through `services.project` operations.

The V2 `Project` declaration owns its version, factory, validator, migrations,
and named read-only legacy imports. Optional `CreateResume` and `ApplyResume`
hooks may restore conveniences such as the current frame, never durable data.

V2 events run through one non-recursive FIFO queue per figure. A handler has
the signature `state = handler(state, event, services)`. Nested
`services.dispatch` calls enqueue a later transaction, so the current handler
finishes one state commit and one presentation commit first. A failed handler,
validator, or presenter restores the last committed state and visible
presentation.

Ordinary value controls may use a semantic binding such as
`"Bind", "project.parameters.gamma"` and may name an optional `Event` to run
after the value is staged. `Present(state)` returns control properties and
prepared preview models by semantic id. Registered renderers receive an axes
and model; presenters and actions do not receive the raw UI registry on the v2
path. A renderer runs only when its declared renderer/model request changes;
state-only commits preserve existing graphics and viewports. Plot utilities are
inferred from the layout. Dynamic `Items` and `Limits`
are applied before bound values. V2 saves one `labkitProject`; named legacy
variables import read-only.

`Event` is meaningful only on a control that also declares `Bind`. An unbound
control must use an explicit generated `onChange` callback; the runtime rejects
an unbound `Event` during launch so a migrated control cannot appear editable
while silently discarding user changes.

After shell, state, first presentation, and interaction hub exist, the runtime
queues optional `Start` with injected app-neutral `services`. An optional
`DebugSample` writer runs only for debug launches, without app startup glue.
V2 commits mirror `session.workflow.logLines` into semantic `logPanel` controls.
Injected `services.dialogs` provides input-file, input-folder, output-file, and
output-folder selection with safe defaults and test-injectable choosers. App
handlers therefore do not call `uigetfile`, `uigetdir`, or save-dialog helpers
directly. A `Start` handler may resolve a registered preview with
`services.previews.axes(previewId, axisId)` only to attach a framework-managed
listener or timer; actions, presenters, and semantic state still use plain data
and preview models.

Each figure owns one private interaction hub. Preview targets register as
`previewId` or `previewId.axisId`; the hub owns hover wheel/zoom routing,
drag callbacks, and atomic groups. V2 apps never set figure callbacks.
`Present` may declare `anchors`, `pairedAnchors`, `pointSlots`, `rectangle`, `regionSelection`, or
`scaleBarReference` with semantic targets, values, events, and image sizes. `regionSelection`
emits a dragged rectangle to `Event` or clicked point to `BackgroundEvent`.
Kind/target changes replace or dispose resources; programmatic values suppress
events, while user edits enqueue the declared event. When an interaction event
changes an overlay model and causes its renderer to run again, the runtime
preserves any manually zoomed or panned axes limits. Ordinary file-selection,
reset, and data-change events may still let the renderer fit a new view.

## Start And Readiness

LabKit app startup is a framework runtime state, not an app-owned progress
dialog convention. `labkit.ui.runtime.launch` builds the shell, canonical state,
first presentation, and interaction hub, then queues the optional definition
`Start` handler through the same transaction queue as every later event. The
runtime paints a readiness boundary when this work is slow enough to be
perceptible and clears it only after the first visible presentation commits.

Fast apps should not flash a loading strip. The app window remains hidden until
the initial workspace is ready, while the launcher progress dialog mirrors the
current framework phase. A direct command-window launch prints the same phases
with a `[LabKit startup]` prefix. This keeps slow or failed startup observable
without exposing a blank or partially constructed app window. Hidden or
minimized GUI test modes preserve readiness state for assertions while avoiding
disruptive visual UI and command output.

Nonessential work belongs behind a user event or a framework-owned managed
resource, not an app-created startup timer. App code should express initial
domain work in its single `Start` handler and must not mutate readiness flags
or manage loading controls directly.

## Busy State

Every `labkit.ui.layout.action` callback runs as an app-wide action transaction.
The framework marks the app busy before invoking the app callback and clears
that busy state after the callback returns or errors. While the figure is busy,
other semantic callbacks return without invoking app code, so repeated
clicks or value changes do not submit duplicate work even when the user waits
and interacts again before the first action finishes.

The default busy text comes from the action label:

```matlab
labkit.ui.layout.action("exportCrops", ...
    "Export cropped images", callbacks.exportCrops, ...
    "enabled", false)
```

This displays `Working: Export cropped images` in the window title while the
callback runs. Use `busyMessage` only when the title text needs to differ from
the button label.

`labkit.ui.runtime.runBusy` remains the lower-level helper for custom synchronous
work that is not launched from a layout action:

```matlab
payload = labkit.ui.runtime.runBusy(fig, ...
    "Writing cropped microscope images...", ...
    @() batch_crop.export.writeOutputs(items, opts));
```

Busy state is app-wide. While the callback runs, LabKit marks the figure busy,
sets a busy pointer, and appends the busy message to the window title. Direct
`runBusy` calls also freeze figure-level mouse, wheel, motion, and keyboard
callbacks and turn graphics hit testing off by default. Action transactions use
a non-invasive mode so actions that start editors or plotting tools can leave
their own pointer and callback state in place.

LabKit-created app figures install a framework close guard. Closing any LabKit
app shows an in-window confirmation prompt before deleting the figure. If the
user tries to close an app while a semantic action or `runBusy` operation is
active, the prompt uses busy-state wording.

The app-window close shortcut uses the same path: Command-W on macOS and
Control-W elsewhere request a guarded close rather than bypassing unfinished
work prompts. When a close shortcut opens the confirmation prompt, repeating or
holding the same close shortcut confirms the close.

Apps should not maintain close-guard dirty state. The framework owns close
confirmation for public and private LabKit apps.

`runBusy` intentionally does not create modal progress dialogs. Apps should not
maintain their own busy-control lists, and `runBusy` does not mutate control
`Enable` values. App render logic still owns permanent button enablement rules.

## Presentation And Plotting

Apps do not receive the UI registry and do not call control setters. A pure
`Present(state)` function returns semantic control properties, prepared preview
models, and controlled interaction specs. The runtime applies dynamic items and
limits before values, suppresses callbacks during the commit, mirrors workflow
logs, and invokes changed renderer/model requests with only `(axes, model)`.
Unchanged preview requests retain their graphics handles and axes limits.

Renderers may use ordinary MATLAB graphics plus the small advanced plot surface:
`clear`, `fit`, `fitCanvas`, `message`, `offsetData`, and `clampData`.
`clear` and `fit` own full-redraw viewport mechanics; `offsetData` and
`clampData` honor log scales and reversed axes. Image preparation, annotations,
labels, and scientific plot meaning remain app-owned.

A renderer may call `labkit.ui.interaction.enablePopout(ax)` after drawing an
axes. The workbench also installs the standard popout action automatically and
restores it after a renderer resets the axes or replaces its children.

## Managed Interactions

Apps declare controlled interaction specs from their presenter rather than
constructing editor objects. Supported kinds include `anchors`,
`pairedAnchors`, `pointSlots`, `rectangle`, `regionSelection`,
`interval`, and `scaleBarReference`. The figure-scoped interaction hub owns
pointer routing, wheel zoom, drag capture/release, callback restoration, event
enqueueing, and resource cleanup.

While an anchor interaction is active, the framework writes the exact add,
drag, and removal gesture into the preview subtitle. Curve anchors use
double-click to add/delete, point-marking modes use a single click plus their
explicit Undo/Clear controls, and paired matching explains that both previews
must be clicked in corresponding order.

Apps persist only semantic values such as points, rectangles, intervals, and
calibration. `labkit.ui.interaction.anchorPath`, `scaleBarCalibration`, and
`scaleBarGeometry` remain GUI-free advanced helpers for calculations,
presentation models, and exports. Apps never place editor/runtime objects or
graphics handles in project or session state.

## Debug

Debug launches create an ignored `artifacts/debug/<app>/<run>/manifest.json`.
This is a local index for the anonymous debug sample pack, trace log, and
expected debug output folder; it is not project state and is safe to remove
with the rest of that debug run. By contrast, `*.labkit.json` beside an
exported result is a result manifest containing output status, byte counts,
SHA-256 hashes, parameters, provenance, and summary data, and should normally
stay with the exported files.

`labkit.ui.runtime.launch` owns normal, debug, requirements, and version
requests. A debug launch remains:

```matlab
[fig, debug] = appName("debug");
```

The runtime injects diagnostics and workflow-log services. Handlers that catch
and continue after an exception call `services.diagnostics.report`; visible
log lines go through `services.workflow.log` and are mirrored into semantic
`logPanel` controls on commit. Apps do not construct debug contexts, wrap UI
callbacks, or append separately to a UI registry.

Each debug launch writes a session folder under
`artifacts/debug/<AppName>/<SessionId>/` containing `trace.log`, `samples/`,
`outputs/`, and `manifest.json`. The trace is authoritative when the GUI is
unresponsive; the Log tab is its human-readable workflow mirror. Framework
instrumentation records active operations and callback failures without adding
app-owned lifecycle glue.

## Callback Policy

Reusable helpers and tools keep three callback classes separate:

| Callback class | Purpose |
| --- | --- |
| User semantic callbacks | Notify the app that the user changed app-relevant state. |
| Internal refresh callbacks | Keep controls, graphics, and derived readouts synchronized without re-entering app semantics. |
| Programmatic callbacks | Apply app-initiated state changes and report source as programmatic when exposed through trace. |

All `setX(value)` style APIs should do nothing when the requested value is
already current. Internal synchronization should not fire app-facing semantic
callbacks. Composed tools should trace callback reason/source as `user`,
`internal`, or `programmatic` when an event crosses the app/tool boundary.

## Framework And App Responsibilities

`labkit.ui` provides the app-neutral GUI shell, view construction, axes
rendering, interaction lifecycle, composed tools, diagnostics, and reusable
control-state mechanics.

Experiment names, formulas, thresholds, parser calls, result fields, export
schemas, plotting annotations, and workflow-specific action order remain in the
app. Apps pass labels, semantic action ids, prepared vectors, tables, debug
contexts, and option values into UI helpers.

## Validation

Reusable UI contracts are covered by the source-aligned UI and project build
tasks listed in [Testing](../development/testing.md).

Automated GUI tests validate launch, layout, callback wiring, trace plumbing,
reusable tool lifecycle, and hidden synthetic app workflows. Full interactive
drawing, file selection, visual inspection, scientific validity, and workflow
feel still require manual MATLAB GUI validation.

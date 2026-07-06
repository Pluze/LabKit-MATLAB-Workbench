# UI Library

`labkit.ui` is the reusable MATLAB GUI foundation. It is split into app-facing facade packages:

| Facade | Owns | Main APIs |
| --- | --- | --- |
| `labkit.ui.runtime` | Declarative app runtime, request dispatch, readiness/busy state, safe dialog defaults, app title versioning, state snapshots, and shell utility commands. | `define`, `run`, `create`, `dispatchRequest`, `appVersionTitle`, `applyVersionTitle`, `defaultDialogFolder`, `defaultOutputFolder`, `promptOutputFile`, `promptOutputFolder`, `runBusy`, `saveState`, `loadState`, `setCloseGuard`, `showAlert`. |
| `labkit.ui.layout` | UI 5 data-only workbench layouts. | `workbench`, `workspace`, `tab`, `section`, `group`, `field`, `rangeField`, `panner`, `action`, `filePanel`, `toolPanel`, `previewArea`, `resultTable`, `logPanel`, `statusPanel`, `usagePanel`. |
| `labkit.ui.control` | Semantic registry updates, file-panel values, list selections, numeric limits, enable state, and log appends. | `setValue`, `getValue`, `getFiles`, `setFileSelection`, `setEnabled`, `setLimits`, `appendLog`, `setListItems`, `setListSelection`, `fileLabels`, `filePaths`, `fileIndices`. |
| `labkit.ui.plot` | Preview axes lookup, plot clearing, image drawing, fitted limits, canvas framing, empty-state messages, and data/axes coordinate conversion. | `getAxes`, `clear`, `clearPreview`, `reset`, `image`, `fit`, `fitCanvas`, `dataToFraction`, `fractionToData`, `offsetData`, `clampData`, `message`. |
| `labkit.ui.interaction` | Reusable composed preview tools and pointer/scroll interaction runtime. | `runtime`, `anchorEditor`, `scaleBar`, `scaleBarCalibration`, `enablePopout`, `popout`, `zoomAtPoint`. |
| `labkit.ui.debug` | Debug launch context, visible trace, callback instrumentation, and crash reports. | `context`. |

The root `labkit.ui.*` flat helper surface has been removed. Apps should call the facade that owns the behavior they need. Private implementation details live under each facade's `private/` folder.

`labkit.ui.version()` returns the UI facade contract version struct used by
`labkit.contract` requirement checks.

## Declarative App Runtime

The UI surface makes app code read as a semantic description of a LabKit
workflow, not as grid construction or a general MATLAB GUI DSL. New app code
should expose an app-owned `definition.m` and launch it through
`labkit.ui.runtime.run`. The framework runtime owns lifecycle, callback dispatch,
readiness, busy state, diagnostics, and staged activation. App packages declare
state factories, command handlers, visible-state updates, and data-only UI
structure.

Public launch files stay thin. They route requests, expose requirements and
version metadata, and delegate the GUI to the framework runtime:

```matlab
function varargout = labkit_Example_app(varargin)
    requirements = example.requirements();
    appVersion = example.version();
    [handled, outputs, debug] = labkit.ui.runtime.dispatchRequest( ...
        "labkit_Example_app", varargin, nargout, ...
        "Requirements", requirements, "Version", appVersion);
    if handled
        varargout = outputs;
        return;
    end

    request = struct("debug", debug);
    fig = labkit.ui.runtime.run(example.definition(), request);
    labkit.ui.runtime.applyVersionTitle(fig, appVersion);
    if nargout >= 1
        varargout{1} = fig;
    end
end
```

```matlab
function def = definition()
def = labkit.ui.runtime.define( ...
    "Id", "example", ...
    "Title", "Example App", ...
    "InitialState", @example.appLifecycle.createInitialState, ...
    "Layout", @example.userInterface.buildWorkbenchLayout, ...
    "Actions", example.definitionActions(), ...
    "Render", @example.userInterface.updateWorkbenchFromState, ...
    "Snapshot", example.snapshot.options(), ...
    "Utilities", struct("Visible", true, "Plot", true, ...
        "Screenshot", true, "State", "auto"), ...
    "Startup", ["workspace"], ...
    "Hydrate", ["tools"]);
end
```

`definition.m` is a small MATLAB-scale DSL made of structs and function
handles. It is not a new language, a generator, or a class hierarchy. The
framework validates the definition, generates callback closures, builds the
visible workbench, paints a readiness surface when startup is slow, dispatches
startup actions, and then hydrates nonessential regions when idle or on first
interaction. App-specific launch payloads may be passed to `labkit.ui.runtime.run`
in the request struct; command handlers receive those values read-only as
`services.request`.

Apps use `+appLifecycle`, `definitionActions.m`, and `+userInterface`;
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

Use these app-facing contracts:

- The default shell is a LabKit workbench: control tabs on the left and primary
  preview, plot, waveform, image, or canvas content on the right.
- `definition.m` declares app identity, state factory, workbench layout, command
  handler registry, visible-state update function, startup phases, and
  optional idle hydration phases, optional snapshot hooks, and optional shell
  utility visibility.
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
- App commands should be named by user intent or startup phase. They receive
  framework payload/services, return updated app state, and request framework
  effects instead of directly mutating lifecycle state.
- `filePanel` owns file input mechanics: file chooser defaults, optional
  recursive folder scans, duplicate filename display, current selection, and
  file-entry events. Each file entry exposes `id`, `index`, `path`, `name`,
  `displayName`, and `status`. Callback events expose file entries through
  `event.files`, `event.addedFiles`, `event.removedFiles`,
  `event.selectedFiles`, and `event.value` for the current selection. Apps
  that need paths call `labkit.ui.control.filePaths(files)` instead of reading
  fields directly from the event; apps that remove or select by panel entry
  call `labkit.ui.control.fileIndices(files, itemCount)` instead of parsing
  `id` or `index` locally.
- The active `filePanel` selection is also a framework title context. When a
  file is selected through the panel or `labkit.ui.control.setFileSelection`, the
  app window title and preview axes titles include `file N/M: name.ext`; when
  selection is cleared, the framework removes that suffix. Apps should keep
  preview titles focused on the view or measurement being shown, not duplicate
  the selected filename in app-local title strings.
- Multi-file `filePanel` mode uses the fixed commands Add, Remove selected,
  and Clear. Add lets users choose files or recursively scan a folder; folder
  scans count matching files first and ask for confirmation when the count
  exceeds the panel warning threshold. File labels show sequence numbers plus
  short filenames, adding the nearest unique parent directory when repeated
  filenames would otherwise collide. Apps that allow duplicate source files
  should remove by file `id` or `index` from `event.removedFiles` instead of
  deleting by path. Programmatic file replacement uses
  `labkit.ui.control.setValue`; programmatic file selection uses
  `labkit.ui.control.setFileSelection`. Apps with their own nearby status field
  can pass `showStatus=false` to omit the panel's internal count/status text.
- Single-file `filePanel` mode opens one file directly, replaces the previous
  file on the next choose action, does not offer recursive folder selection,
  and displays the short filename in one read-only text field instead of a
  selectable list.
- `filePanel` and app-owned save/open dialogs should not default to `pwd`;
  `labkit.ui.runtime.defaultDialogFolder("input")` and `"output"` provide safe
  remembered defaults outside the LabKit install root.
- App output defaults should be source-adjacent when a source file or folder is
  known. Use `labkit.ui.runtime.defaultOutputFolder(sourcePaths, subfolderName)`;
  the helper uses the first source path when multiple files are loaded and
  creates the app-specific subfolder before returning it.
- App-owned save dialogs may use `labkit.ui.runtime.promptOutputFile` when they
  only need a safe output default and cancel normalization; apps still own
  filenames, filters, export formats, and user-facing prompt wording.
- App-owned output folder dialogs should use
  `labkit.ui.runtime.promptOutputFolder` when they need a safe output default,
  cancel normalization, remembered output folder updates, or test chooser
  injection. Apps still own the selected folder state, exports, and workflow
  wording.
- App-owned alerts should use `labkit.ui.runtime.showAlert(fig, message, title)`.
  Apps still own alert text. The helper preserves normal modal `uialert`
  behavior, records alert payloads on the figure, and skips the modal only
  when `LABKIT_GUI_TEST_MODE=hidden` so hidden GUI workflow tests can cover
  error paths without stalling.
- `labkit.ui.runtime.saveState(fig, filepath)` and
  `labkit.ui.runtime.loadState(fig, filepath)` save and restore same-version app
  state snapshots. Snapshots store one MAT variable named `snapshot` with app
  id, optional app version, optional app snapshot schema version, LabKit UI
  version, MATLAB release/platform, and serialized semantic app state. They do
  not store UI handles, function handles, debug contexts, listeners, file
  identifiers, or the full runtime appdata struct. Apps may pass
  `define(..., "Snapshot", snapshotOptions)` with optional `Serialize`,
  `Deserialize`, and `AfterLoad` hooks to remove caches, validate restored
  values, or request follow-up refresh work. Snapshot loading is strict: schema, app id, LabKit UI
  version, MATLAB release/platform, app version when known, and app snapshot
  version must match before runtime state is replaced.
- The workbench shell includes native window utility menus with plot
  popout/copy/save commands, whole-app screenshot export, and state snapshot
  save/load commands. Plot commands operate on every registered preview axes
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
  Preview axes are also registered with the workbench utility menus, whose plot
  commands act on all registered visible axes.
- `labkit.ui.interaction.enablePopout(ax)` installs the standard axes context
  menu action. `labkit.ui.interaction.popout(ax)` copies the visible axes into a
  standalone MATLAB figure with optional copied-figure text buttons for font
  size, plotted data line width, axes line width, grid visibility, and a Studio
  handoff. Popout edits operate on the copied figure only. Plot axes remain
  freely resizable, while image axes preserve locked data aspect ratio.
  Data-package export and generated reconstruction scripts belong in the
  Figure Studio workflow rather than the lightweight popout window; app-owned
  scientific CSV/MAT result exports still belong in the app package.
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
- `labkit.ui.control.setLimits` updates numeric limits and clamps existing values
  without firing synchronous value-change callbacks.

The public layout-node grammar is semantic: pages, sections, controls, order,
values, and callbacks. When a workflow needs a control that cannot be expressed
with the ordinary layout nodes, add a named framework or app-owned layout node
instead of placing
MATLAB layout code in `buildWorkbenchLayout.m`.

Control tabs with more than one section include draggable horizontal
separators by default. A tab may opt out with `resize="none"` when a fixed
stack is intentional.

## Startup Readiness

LabKit app startup is a framework runtime state, not an app-owned progress
dialog convention. `labkit.ui.runtime.run` builds a named shell first, paints a
readiness boundary when startup is slow enough to be perceptible, dispatches
declared startup actions after the shell has a paint opportunity, and clears
readiness only after the first visible render completes.

Fast apps should not flash a loading strip. Slow apps should never sit as an
anonymous blank frame: the framework keeps a non-modal status surface visible
until the current startup phase has completed and the initial visible
workspace is rendered. Hidden or minimized GUI test modes preserve readiness
state for assertions while avoiding disruptive visual UI.

Nonessential work belongs in idle hydration or first-interaction activation
when the app definition marks it that way. Typical hydration candidates are
inactive tabs, expensive optional tools, debug artifact generation, or
secondary previews. App code should request app-level work through declared
startup or action phases; it should not create raw startup timers, mutate
framework readiness flags, or manage loading controls directly.

## Busy State

Every `labkit.ui.layout.action` callback runs as an app-wide action transaction.
The framework marks the app busy before invoking the app callback and clears
that busy state after the callback returns or errors. While the figure is busy,
other UI 5 semantic callbacks return without invoking app code, so repeated
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
work that is not launched from a UI 5 action:

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

LabKit-created app figures install a framework close guard. If the user tries
to close an app while a semantic action or `runBusy` operation is active, the
framework asks for confirmation instead of immediately deleting the figure.
Apps with unfinished workflow state should call
`labkit.ui.runtime.setCloseGuard(fig, true, message)` during refresh or dirty-state
updates, then clear it with `setCloseGuard(fig, false)` after the workflow is
complete.

`runBusy` intentionally does not create modal progress dialogs. Apps should not
maintain their own busy-control lists, and `runBusy` does not mutate control
`Enable` values. App render logic still owns permanent button enablement rules.

## Control and Plot Helpers

```matlab
labkit.ui.control.setValue(ui, "displayLimits", [0.1 0.9]);
labkit.ui.control.setValue(ui, "sourceImages", ["a.png"; "b.png"]);
files = labkit.ui.control.getFiles(ui, "sourceImages");
labkit.ui.control.setFileSelection(ui, "sourceImages", files(1));
paths = labkit.ui.control.filePaths(labkit.ui.control.getValue(ui, "sourceImages"));
labkit.ui.control.setEnabled(ui, "run", false);
labkit.ui.control.appendLog(ui, "log", "Loaded image.");
labkit.ui.plot.image(ui, "preview", imageData, ...
    "axis", "raw", "title", "Reference");
[ok, frame] = labkit.ui.plot.fitCanvas(ax, 720, 540);
labkit.ui.plot.fit(ax);
labkit.ui.plot.reset(ui, "preview", "Reference", true, "raw");
labkit.ui.plot.clearPreview(ui, "preview", "difference");
```

Control helpers target semantic ids in the UI registry owned by the app
runtime. Plot helpers target MATLAB axes handles or named previewArea axes.
They do not create arbitrary controls, expose MATLAB layout primitives, or
replace MATLAB's native plotting commands.
`previewArea` axes automatically receive the standard right-click action
`Open axes in new figure`; the current implementation copies the axes into a
standalone MATLAB figure and preserves the plot/image aspect behavior already
used by LabKit previews. Apps still draw prepared plot data with MATLAB
commands such as `plot`, `line`, `text`, `legend`, `xline`, and `patch`; use
`labkit.ui.plot.clear` before a full redraw, `labkit.ui.plot.fit` after the
main data graphics are drawn, and `labkit.ui.plot.getAxes` when app code needs
a named axes handle from a previewArea.

`labkit.ui.plot.image` preserves the current axes view when an image is
redrawn with the same displayed bounds, so overlay refreshes do not throw away
a user's zoomed preview. Use `labkit.ui.plot.reset` or
`labkit.ui.plot.clearPreview` when an app intentionally wants to return the
preview to its home view.

`labkit.ui.plot.fitCanvas` lets an app request a fixed pixel canvas inside a
`previewArea` axes host while the UI facade owns the row/column grid policy.
The returned frame describes the applied preview scale and pixel size so apps
can align their own font or line-width preview scaling without reading layout
internals.

Curve and image viewport behavior are intentionally different. Curve redraws
that replace plotted data should call `labkit.ui.plot.clear`, draw the main
data graphics, then call `labkit.ui.plot.fit(ax, hData)`. Passing the main
graphics handle prevents later annotations, threshold lines, and window
shading from stretching the data range. Overlay-only refreshes and image ROI
edits should keep the current viewport. Image redraws should continue to use
`labkit.ui.plot.image`, whose image policy preserves the current view when the
displayed bounds are stable.

For label placement and hit-testing, `labkit.ui.plot.dataToFraction`,
`fractionToData`, `offsetData`, and `clampData` convert between data
coordinates and normalized axes coordinates while honoring log scales and
reversed axes. Apps can use them to place labels such as extrema markers
without reimplementing coordinate math.

`logPanel` follows appended lines by default: `appendLog` scrolls the log to the
bottom after adding a line. Users can use the visible follow button or the log
context menu to pause auto-scroll while reading older lines, then resume
following the latest line.

## Interaction Tools

Preview tools that need custom scroll semantics, drag, hit-test, anchor editing, ROI-style drawing, or scale bars should create a runtime:

```matlab
runtime = labkit.ui.interaction.runtime(ax, struct( ...
    'figure', fig, ...
    'defaultScrollFcn', @onPreviewScroll, ...
    'onTrace', debug.trace));
```

The runtime owns exclusive sessions, pointer callbacks, drag capture, scroll ownership, and restoration. Temporary drag callbacks are cleared on normal release and on callback errors before errors are rethrown. Apps should not set `WindowScrollWheelFcn`, `WindowButtonMotionFcn`, `WindowButtonUpFcn`, or preview-tool `ButtonDownFcn` directly.
Default and session scroll callbacks are target-gated by default: the runtime
dispatches wheel events only when the pointer is over the declared axes,
background, or graphics handles. Pass `scrollScope="figure"` only when a tool
intentionally wants whole-figure wheel behavior. When a runtime target does
not receive the event, the pre-runtime fallback remains available, so
app-specific tools do not block the framework previewArea navigator outside
their declared targets.

Use `labkit.ui.interaction.zoomAtPoint(ax, [x y], scrollCount)` when a custom
tool or app needs the same cursor-centered axes-limit zoom used by default
previewArea navigation. The helper supports generic numeric plots and infers
image bounds for displayed image children; pass `"Bounds", [xmin xmax ymin ymax]`
when a tool has stricter data limits. Generic plots zoom both axes by default;
time-labeled x-axes zoom only the horizontal axis unless `"ZoomAxes"` is
provided explicitly.

Use `labkit.ui.interaction.anchorEditor(runtime, imageSize, opts)` for generic anchor editing. Use `labkit.ui.interaction.scaleBar(parent, row, runtime, opts)` for calibration controls, reference-pixel editing, unit normalization, final scale-bar placement, and overlay drawing. Apps can persist `tool.calibration()` per image and restore it with `tool.setCalibration(cal)`. Apps still own image loading, redraw order, scientific calculations, result summaries, alerts, logs, and exports.

`labkit.ui.interaction.scaleBarCalibration(referencePixels, referenceLength, unitName, opts)` is the GUI-free calibration struct helper used by apps and app-private calculations.

## Debug

Apps route debug launch requests through:

```matlab
[handled, outputs, debug] = labkit.ui.runtime.dispatchRequest( ...
    appName, varargin, nargout);
```

Debug contexts are created by dispatch for normal app entry points. Non-debug
string inputs are rejected by the public app launch path. App launchers expose
only the simple debug form; lower-level debug options such as log files or
callbacks belong to direct `labkit.ui.debug.context(appName, opts)` tests
and helpers.

The same dispatch path also consumes lightweight `"requirements"` and
`"version"` requests without launching a GUI.

Debug launches support:

```matlab
[fig, debug] = appName("debug");
```

Apps append visible log lines through `labkit.ui.control.appendLog(ui, "log",
message)` or the app's chosen log-panel id, then call `debug.append(message)`.
Debug-mode apps attach the Log tab text area, emit a startup trace line, pass
`debug.trace` into reusable tools through `onTrace`, and call
`debug.instrumentFigure(fig)` after controls are built.

Each public debug launch also writes a per-launch session folder under
`artifacts/debug/<AppName>/<SessionId>/`. Official test runs set
`LABKIT_ARTIFACTS` and `LABKIT_RUN_NAME`, so test-launched apps write under
`artifacts/debug/<RunName>/<AppName>/<SessionId>/`. Each session contains
`trace.log`, `samples/`, `outputs/`, and `manifest.json`. The trace file is
the authoritative debug record when the GUI freezes or the app Log tab is
inaccessible; the visible Log tab is only the human-readable mirror.

Debug instrumentation writes an active-operation report next to the trace log
when an instrumented callback starts, removes it when the callback completes,
and writes a crash report when a callback errors or exceeds the stall timeout.
The active-operation report records the current callback so a MATLAB process
crash or hard UI freeze still leaves the last in-flight operation on disk.
Crash reports include the exact MATLAB error id, message, stack, and a
`recent_operations` section derived from semantic trace lines so a bug report
can include both the failure and the likely reproduction path.
MATLAB timer callbacks cannot interrupt every synchronous native or M-code
stall while the main thread is blocked, so active-operation files and the
normal trace log are part of the freeze report contract.

Apps that intentionally catch an `MException` and continue should still call
`debug.reportException(component, event, ME)` before showing their own alert or
recovering. This keeps swallowed import, export, or preview failures visible in
the same crash-report stream as uncaught callback errors.

Trace is for diagnosing GUI interaction failures, callback errors, stalled file
loads, and environment-sensitive launch problems. It is not workflow
documentation and should not record sensitive file paths, raw sample metadata,
or high-volume pointer movement. Trace lines include timestamp plus stable
`app=...`, `component=...`, `event=...`, and `reason=...` fields. Default
instrumentation wraps semantic callbacks and skips low-level pointer, drag, and
scroll callbacks.
`filePanel` emits framework trace lines for file choice, accepted path count,
selection updates, and callback handoff boundaries. These traces intentionally
record counts and semantic ids, not full local paths; app-owned readers remain
responsible for per-file decode or parser progress.

## Callback Policy

Reusable helpers and tools keep three callback classes separate:

| Callback class | Purpose |
| --- | --- |
| User semantic callbacks | Notify the app that the user changed app-relevant state. |
| Internal refresh callbacks | Keep controls, graphics, and derived readouts synchronized without re-entering app semantics. |
| Programmatic callbacks | Apply app-initiated state changes and report source as programmatic when exposed through trace. |

All `setX(value)` style APIs should no-op when the requested value is already current. Internal synchronization should not fire app-facing semantic callbacks. Composed tools should trace callback reason/source as `user`, `internal`, or `programmatic` when the event crosses the app/tool boundary.

## Ownership Boundary

`labkit.ui` may provide app-neutral GUI shell, view construction, axes rendering, interaction lifecycle, composed tools, diagnostics, and reusable control state mechanics.

`labkit.ui` should not own experiment names, formulas, thresholds, parser calls, result fields, export schemas, plotting annotations, or app-specific workflow choreography. Apps pass labels, semantic action ids, prepared vectors, tables, debug contexts, and option values into UI helpers.

## Validation

Reusable UI contracts are covered by the source-aligned UI and project build
tasks listed in `docs/testing.md`.

Automated GUI tests validate launch, layout, callback wiring, trace plumbing,
reusable tool lifecycle, and hidden synthetic app workflows. Full interactive
drawing, file selection, visual inspection, scientific validity, and workflow
feel still require manual MATLAB GUI validation.

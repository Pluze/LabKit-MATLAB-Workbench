# UI Library

`labkit.ui` is the reusable MATLAB GUI foundation. It is split into app-facing facade packages:

| Facade | Owns | Main APIs |
| --- | --- | --- |
| `labkit.ui.app` | Declarative app runtime, request dispatch, readiness/busy state, safe dialog defaults, app title versioning. | `define`, `run`, `create`, `dispatchRequest`, `appVersionTitle`, `applyVersionTitle`, `defaultDialogFolder`, `defaultOutputFolder`, `promptOutputFile`, `promptOutputFolder`, `runBusy`, `setCloseGuard`, `showAlert`. |
| `labkit.ui.spec` | UI 3.0 data-only workbench specs. | `app`, `workspace`, `tab`, `section`, `field`, `rangeField`, `panner`, `action`, `actionGroup`, `filePanel`, `toolPanel`, `previewArea`, `resultTable`, `logPanel`, `statusPanel`, `usagePanel`. |
| `labkit.ui.view` | Semantic UI 3.0 registry updates and preview rendering helpers. | `setValue`, `getValue`, `getFiles`, `setFileSelection`, `setEnabled`, `setLimits`, `appendLog`, `setListItems`, `setListSelection`, `fileLabels`, `filePaths`, `fileIndices`, `drawImage`, `resetAxes`, `clearAxes`. |
| `labkit.ui.tool` | Reusable composed preview tools and interaction runtime. | `createRuntime`, `anchorEditor`, `scaleBar`, `scaleBarCalibration`, `enableAxesPopout`, `popoutAxes`, `zoomAxesAtPoint`. |
| `labkit.ui.diag` | Debug launch context, visible trace, callback instrumentation, and crash reports. | `createContext`. |

The root `labkit.ui.*` flat helper surface has been removed. Apps should call the facade that owns the behavior they need. Private implementation details live under each facade's `private/` folder.

`labkit.ui.version()` returns the UI facade contract version struct used by
`labkit.contract` requirement checks.

## Declarative App Runtime

The UI surface makes app code read as a semantic description of a LabKit
workflow, not as grid construction or a general MATLAB GUI DSL. New app code
should expose an app-owned `definition.m` and launch it through
`labkit.ui.app.run`. The framework runtime owns lifecycle, callback dispatch,
readiness, busy state, diagnostics, and staged activation. App packages declare
state factories, command handlers, visible-state updates, and data-only UI
structure.

Public launch files stay thin. They route requests, expose requirements and
version metadata, and delegate the GUI to the framework runtime:

```matlab
function varargout = labkit_Example_app(varargin)
    requirements = example.requirements();
    appVersion = example.version();
    [handled, outputs, debug] = labkit.ui.app.dispatchRequest( ...
        "labkit_Example_app", varargin, nargout, ...
        "Requirements", requirements, "Version", appVersion);
    if handled
        varargout = outputs;
        return;
    end

    request = struct("debug", debug);
    fig = labkit.ui.app.run(example.definition(), request);
    labkit.ui.app.applyVersionTitle(fig, appVersion);
    if nargout >= 1
        varargout{1} = fig;
    end
end
```

```matlab
function def = definition()
def = labkit.ui.app.define( ...
    "Id", "example", ...
    "Title", "Example App", ...
    "InitialState", @example.appLifecycle.createInitialState, ...
    "Spec", @example.userInterface.buildWorkbenchSpec, ...
    "Actions", example.definitionActions(), ...
    "Render", @example.userInterface.updateWorkbenchFromState, ...
    "Startup", ["workspace"], ...
    "Hydrate", ["tools"]);
end
```

`definition.m` is a small MATLAB-scale DSL made of structs and function
handles. It is not a new language, a generator, or a class hierarchy. The
framework validates the definition, generates callback closures, builds the
visible workbench, paints a readiness surface when startup is slow, dispatches
startup actions, and then hydrates nonessential regions when idle or on first
interaction.

Current migrated apps may still use transitional adapter packages such as
`+state`, `+actions`, `+ui`, and `+view`. New app code should use
`+appLifecycle`, `definitionActions.m`, and `+userInterface`; app-specific
work belongs in concrete workflow packages such as `+sourceFiles`,
`+analysisRun`, `+resultFiles`, or a domain-specific package.

```matlab
function spec = buildWorkbenchSpec(callbacks)
spec = labkit.ui.spec.app("exampleApp", "Example App", ...
    "controlTabs", controlTabs(callbacks), ...
    "workspace", previewWorkspace(callbacks), ...
    "usage", {"Load input data.", "Run analysis.", "Review/export results."});
end

function tabs = controlTabs(callbacks)
    tabs = {setupTab(callbacks), reviewTab(), logTab()};
end

function tab = setupTab(callbacks)
    tab = labkit.ui.spec.tab("setup", "Setup", { ...
        labkit.ui.spec.section("actions", "Actions", { ...
            labkit.ui.spec.action("run", "Run", callbacks.run, ...
                "priority", "primary"), ...
            labkit.ui.spec.action("reset", "Reset", callbacks.reset)})});
end

function tab = reviewTab()
    tab = labkit.ui.spec.tab("review", "Review", { ...
        labkit.ui.spec.section("results", "Results", { ...
            labkit.ui.spec.resultTable("resultsTable", "Results", ...
                "columns", {"Name", "Status"})})});
end

function tab = logTab()
    tab = labkit.ui.spec.tab("log", "Log", { ...
        labkit.ui.spec.section("logSection", "Log", { ...
            labkit.ui.spec.logPanel("appLog", "Log")})});
end

function workspace = previewWorkspace(callbacks)
    workspace = labkit.ui.spec.workspace("workspace", "Preview", { ...
        labkit.ui.spec.previewArea("preview", "Preview", ...
            "layout", "single", ...
            "viewModes", {"Input", "Output"}, ...
            "onModeChange", callbacks.previewModeChanged)});
end
```

`buildWorkbenchSpec.m` stays data-only. It receives framework-generated
semantic callbacks and returns a workbench spec. It does not create MATLAB
handles, run IO, compute data, mutate app state, schedule startup work, or set
concrete layout geometry.

Use these app-facing contracts:

- The default shell is a LabKit workbench: control tabs on the left and primary
  preview, plot, waveform, image, or canvas content on the right.
- `definition.m` declares app identity, state factory, UI spec, command
  handler registry, visible-state update function, startup phases, and
  optional idle hydration phases.
- The framework runtime owns lifecycle scheduling, readiness/loading surface,
  generated callbacks, busy gating, debug exception plumbing, close guards, and
  hidden/minimized test behavior.
- `buildWorkbenchSpec.m` describes controls and workspace structure only. App
  command handlers own app-specific state changes, alerts, refresh decisions,
  and log wording.
- Control ids are globally unique within an app. The UI registry is keyed by
  those ids, not by tab or section placement.
- Public specs are semantic controls such as `filePanel`, `toolPanel`, `field`,
  `panner`, `action`, `previewArea`, `resultTable`, `logPanel`, and `statusPanel`.
  Primitive MATLAB controls are implementation details.
- `section` specs should contain real semantic controls. Use `toolPanel` as a
  named host when a reusable `labkit.ui.tool.*` control needs to attach a
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
  that need paths call `labkit.ui.view.filePaths(files)` instead of reading
  fields directly from the event; apps that remove or select by panel entry
  call `labkit.ui.view.fileIndices(files, itemCount)` instead of parsing
  `id` or `index` locally.
- The active `filePanel` selection is also a framework title context. When a
  file is selected through the panel or `labkit.ui.view.setFileSelection`, the
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
  `labkit.ui.view.setValue`; programmatic file selection uses
  `labkit.ui.view.setFileSelection`. Apps with their own nearby status field
  can pass `showStatus=false` to omit the panel's internal count/status text.
- Single-file `filePanel` mode opens one file directly, replaces the previous
  file on the next choose action, does not offer recursive folder selection,
  and displays the short filename in one read-only text field instead of a
  selectable list.
- `filePanel` and app-owned save/open dialogs should not default to `pwd`;
  `labkit.ui.app.defaultDialogFolder("input")` and `"output"` provide safe
  remembered defaults outside the LabKit install root.
- App output defaults should be source-adjacent when a source file or folder is
  known. Use `labkit.ui.app.defaultOutputFolder(sourcePaths, subfolderName)`;
  the helper uses the first source path when multiple files are loaded and
  creates the app-specific subfolder before returning it.
- App-owned save dialogs may use `labkit.ui.app.promptOutputFile` when they
  only need a safe output default and cancel normalization; apps still own
  filenames, filters, export formats, and user-facing prompt wording.
- App-owned output folder dialogs should use
  `labkit.ui.app.promptOutputFolder` when they need a safe output default,
  cancel normalization, remembered output folder updates, or test chooser
  injection. Apps still own the selected folder state, exports, and workflow
  wording.
- App-owned alerts should use `labkit.ui.app.showAlert(fig, message, title)`.
  Apps still own alert text. The helper preserves normal modal `uialert`
  behavior, records alert payloads on the figure, and skips the modal only
  when `LABKIT_GUI_TEST_MODE=hidden` so hidden GUI workflow tests can cover
  error paths without stalling.
- `previewArea` belongs in `workspace` by default. Its optional `viewModes`
  selector is workspace-owned, and apps can react through `onModeChange`.
- `previewArea` axes install LabKit-managed, pointer-gated mouse-wheel zoom by
  default. Scrolling over controls, logs, or empty figure space does not zoom
  plots, and users should not need to click a preview before wheel zoom works.
  Time-series axes with a time x-label zoom the horizontal time axis only.
- Parameter value controls (`field`, `rangeField`, and `panner`) debounce
  semantic `onChange` callbacks by default so short bursts of edits submit
  only the latest value after roughly 0.5 seconds of idle time. Explicit
  actions, file selection, and table edits run immediately. Apps should put
  expensive recompute work behind those semantic callbacks or explicit action
  buttons rather than binding work to lower-level MATLAB value-changing events.
- `panner` is the preferred app-spec control for bounded numeric parameters.
  It renders as a compact numeric spinner plus a linked slider when limits are
  finite, and as spinner-only when limits are intentionally unbounded. Slider
  drags update the numeric readout continuously and submit semantic changes
  through the same debounced callback queue as spinner edits; release submits
  the final committed value.
- Text-heavy controls have conservative automatic heights owned by the
  framework. App specs must not set concrete height, row-count, spacing,
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
- `actionGroup` lays out commands in wrapped rows by default instead of
  forcing every button onto one line. The framework chooses the column count
  from the button count and label length.
- Use app-level `usage`/`usageTitle` on `labkit.ui.spec.app` for static
  workflow instructions. The framework places that read-only usage panel at the
  bottom of the first control tab.
- `labkit.ui.view.setLimits` updates numeric limits and clamps existing values
  without firing synchronous value-change callbacks.

The public spec grammar is semantic: pages, sections, controls, order, values,
and callbacks. When a workflow needs a control that cannot be expressed with
the ordinary specs, add a named framework or app-owned spec instead of placing
MATLAB layout code in `buildWorkbenchSpec.m`.

Control tabs with more than one section include draggable horizontal
separators by default. A tab may opt out with `resize="none"` when a fixed
stack is intentional.

## Startup Readiness

LabKit app startup is a framework runtime state, not an app-owned progress
dialog convention. `labkit.ui.app.run` builds a named shell first, paints a
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

Every `labkit.ui.spec.action` callback runs as an app-wide action transaction.
The framework marks the app busy before invoking the app callback and clears
that busy state after the callback returns or errors. While the figure is busy,
other UI 3.0 semantic callbacks return without invoking app code, so repeated
clicks or value changes do not submit duplicate work even when the user waits
and interacts again before the first action finishes.

The default busy text comes from the action label:

```matlab
labkit.ui.spec.action("exportCrops", ...
    "Export cropped images", callbacks.exportCrops, ...
    "enabled", false)
```

This displays `Working: Export cropped images` in the window title while the
callback runs. Use `busyMessage` only when the title text needs to differ from
the button label.

`labkit.ui.app.runBusy` remains the lower-level helper for custom synchronous
work that is not launched from a UI 3.0 action:

```matlab
payload = labkit.ui.app.runBusy(fig, ...
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
`labkit.ui.app.setCloseGuard(fig, true, message)` during refresh or dirty-state
updates, then clear it with `setCloseGuard(fig, false)` after the workflow is
complete.

`runBusy` intentionally does not create modal progress dialogs. Apps should not
maintain their own busy-control lists, and `runBusy` does not mutate control
`Enable` values. App render logic still owns permanent button enablement rules.

## View Helpers

```matlab
labkit.ui.view.setValue(ui, "displayLimits", [0.1 0.9]);
labkit.ui.view.setValue(ui, "sourceImages", ["a.png"; "b.png"]);
files = labkit.ui.view.getFiles(ui, "sourceImages");
labkit.ui.view.setFileSelection(ui, "sourceImages", files(1));
paths = labkit.ui.view.filePaths(labkit.ui.view.getValue(ui, "sourceImages"));
labkit.ui.view.setEnabled(ui, "run", false);
labkit.ui.view.appendLog(ui, "log", "Loaded image.");
labkit.ui.view.drawImage(ui, "preview", imageData, ...
    "axis", "raw", "title", "Reference");
labkit.ui.view.resetAxes(ui, "preview", "Reference", true, "raw");
labkit.ui.view.clearAxes(ui, "preview", "difference");
```

View helpers target semantic ids in the UI registry owned by the app runtime.
They do not create arbitrary controls or expose MATLAB layout primitives.
`previewArea` axes automatically receive the standard right-click action
`Open axes in new figure`; apps redraw prepared data through the named preview
helpers. `drawImage` preserves the current axes view when an image is redrawn
with the same displayed bounds, so overlay refreshes do not throw away a
user's zoomed preview. Use `resetAxes` or `clearAxes` when an app intentionally
wants to return the preview to its home view.

`logPanel` follows appended lines by default: `appendLog` scrolls the log to the
bottom after adding a line. Users can use the visible follow button or the log
context menu to pause auto-scroll while reading older lines, then resume
following the latest line.

## Interaction Tools

Preview tools that need custom scroll semantics, drag, hit-test, anchor editing, ROI-style drawing, or scale bars should create a runtime:

```matlab
runtime = labkit.ui.tool.createRuntime(ax, struct( ...
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

Use `labkit.ui.tool.zoomAxesAtPoint(ax, [x y], scrollCount)` when a custom
tool or app needs the same cursor-centered axes-limit zoom used by default
previewArea navigation. The helper supports generic numeric plots and infers
image bounds for displayed image children; pass `"Bounds", [xmin xmax ymin ymax]`
when a tool has stricter data limits. Generic plots zoom both axes by default;
time-labeled x-axes zoom only the horizontal axis unless `"ZoomAxes"` is
provided explicitly.

Use `labkit.ui.tool.anchorEditor(runtime, imageSize, opts)` for generic anchor editing. Use `labkit.ui.tool.scaleBar(parent, row, runtime, opts)` for calibration controls, reference-pixel editing, unit normalization, final scale-bar placement, and overlay drawing. Apps can persist `tool.calibration()` per image and restore it with `tool.setCalibration(cal)`. Apps still own image loading, redraw order, scientific calculations, result summaries, alerts, logs, and exports.

`labkit.ui.tool.scaleBarCalibration(referencePixels, referenceLength, unitName, opts)` is the GUI-free calibration struct helper used by apps and app-private calculations.

## Diagnostics

Apps route debug launch requests through:

```matlab
[handled, outputs, debug] = labkit.ui.app.dispatchRequest( ...
    appName, varargin, nargout);
```

Debug contexts are created by dispatch for normal app entry points. Non-debug
string inputs are rejected by the public app launch path. App launchers expose
only the simple debug form; lower-level debug options such as log files or
callbacks belong to direct `labkit.ui.diag.createContext(appName, opts)` tests
and helpers.

The same dispatch path also consumes lightweight `"requirements"` and
`"version"` requests without launching a GUI.

Debug launches support:

```matlab
[fig, debug] = appName("debug");
```

Apps append visible log lines through `labkit.ui.view.appendLog(ui, "log",
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

# UI Library

`labkit.ui` is the reusable MATLAB GUI foundation. It is split into app-facing facade packages:

| Facade | Owns | Main APIs |
| --- | --- | --- |
| `labkit.ui.app` | Declarative app creation, request dispatch, busy state. | `create`, `dispatchRequest`, `runBusy`. |
| `labkit.ui.spec` | UI 2.0 data-only workbench specs. | `app`, `workspace`, `tab`, `section`, `field`, `rangeField`, `panner`, `action`, `actionGroup`, `pathPanel`, `previewArea`, `resultTable`, `logPanel`, `statusPanel`, `custom`. |
| `labkit.ui.view` | Semantic UI 2.0 registry updates and preview rendering helpers. | `setValue`, `getValue`, `setEnabled`, `setLimits`, `appendLog`, `setListItems`, `setListSelection`, `drawImage`, `resetAxes`, `clearAxes`. |
| `labkit.ui.tool` | Reusable composed preview tools and interaction runtime. | `createRuntime`, `anchorEditor`, `scaleBar`, `scaleBarCalibration`, `enableAxesPopout`, `popoutAxes`, `zoomAxesAtPoint`. |
| `labkit.ui.diag` | Debug launch context, visible trace, callback instrumentation. | `createContext`. |

The root `labkit.ui.*` flat helper surface has been removed. Apps should call the facade that owns the behavior they need. Private implementation details live under each facade's `private/` folder.

## UI 2.0 Declarative Workbench

The UI 2.0 surface makes app code read as a semantic description
of a LabKit workbench workflow, not as grid construction or a general MATLAB GUI
DSL. App UI structure should be expressed through app-local
`+<app_slug>/+ui/buildSpec.m` files and created through `labkit.ui.app.create`.

Public launch files stay thin, package-root `run.m` owns lifecycle and
callbacks, and `buildSpec.m` owns only data-only UI shape:

```matlab
function varargout = labkit_Example_app(varargin)
    [varargout{1:nargout}] = example.run(varargin{:});
end
```

```matlab
function varargout = run(varargin)
[handled, outputs, debug] = labkit.ui.app.dispatchRequest( ...
    "labkit_Example_app", varargin, nargout);
if handled
    varargout = outputs;
    return;
end

callbacks = struct( ...
    "run", @onRun, ...
    "reset", @onReset, ...
    "previewModeChanged", @onPreviewModeChanged);
spec = example.ui.buildSpec(callbacks);
ui = labkit.ui.app.create(spec, "debug", debug);
labkit.ui.view.setEnabled(ui, "run", false);
labkit.ui.view.appendLog(ui, "appLog", "Ready.");

if nargout >= 1
    varargout{1} = ui.figure;
end
end
```

```matlab
function spec = buildSpec(callbacks)
spec = labkit.ui.spec.app("exampleApp", "Example App", ...
    "controlTabs", controlTabs(callbacks), ...
    "workspace", previewWorkspace(callbacks));
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

The fixed shape behind this sketch is:

- The default app shell remains a LabKit workbench: left control tabs plus a
  right workspace for primary preview, plotting, waveform, image, or canvas
  content.
- Nontrivial apps should keep the top-level `buildSpec.m` call shallow and use
  local builder functions for tabs, sections, and workspace regions. This keeps
  the UI tree readable without adding a second UI definition language or a
  formatter-only maintenance path. Put section builders in visual order, then
  the workspace builder, then small helper builders.
- `controlTabs`, `sections`, workspace children, and slots use cell arrays of
  scalar spec structs for heterogeneous children.
- Control ids are globally unique within the app spec. `ui.controls.run` and
  `ui.controls.sourceImages` are primary registry paths regardless of tab or
  section placement.
- Public specs express stable app shapes: `pathPanel`, `field`, `rangeField`,
  `panner`, `action`, `actionGroup`, `previewArea`, `resultTable`, `logPanel`, and
  `statusPanel`. Primitive controls such as button, dropdown, slider, listbox,
  textarea, and axes are internal implementation details, not public spec
  constructors.
- `pathPanel` separates chooser mode from list-selection behavior. A workflow
  can load multiple files while keeping one current selection by using
  `mode="multiFile"` with `selectionMode="single"`.
- `pathPanel` list boxes always show an empty-state prompt before files are
  chosen or after Clear. The default prompt is mode-aware, and apps can override
  it with `emptyText` when list wording should differ from the status line.
- `pathPanel` owns generic chooser/list/status mechanics while apps own command
  wording. Use `chooseLabel` when the default `Choose files` or `Choose folder`
  text is not the app's user-facing action label, and use `clearLabel` when
  the clear action needs app-specific wording such as `Clear all`.
- `field` uses a fixed kind whitelist: `text`, `number`, `spinner`, `dropdown`,
  `slider`, `checkbox`, and `readonly`.
- `panner` is the preferred control for browsing along a numeric axis. It
  combines a slider with built-in left/right small-step buttons while exposing
  one semantic value and one `onChange` callback to the app.
- Text-heavy controls have conservative automatic starting heights. `statusPanel`,
  `logPanel`, `pathPanel`, and `resultTable` accept `minRows` and `minHeight`
  when an app needs more room without hand-writing grid layout. Use explicit
  `height` only when the whole row should be fixed or flexed intentionally.
  Numeric section heights are treated as preferred heights and are clamped to
  the section's estimated content minimum, so adding controls cannot silently
  clip buttons or fields.
- Public callbacks use `function callback(control, event)`, where `event`
  carries semantic fields such as `id`, `kind`, `source`, `value`,
  `previousValue`, and `ui`.
- `labkit.ui.view.setLimits` updates numeric limits for slider-like controls
  and range fields, clamping existing values without firing synchronous
  value-change callbacks.
- `previewArea` belongs in `workspace` by default. Its optional `viewModes`
  selector is also workspace-owned; apps can react through
  `onModeChange`. Put preview-like content in a left tab only when it is
  intentionally a compact control-pane preview.
- `previewArea` can take `axisIds`, `axisTitles`, `xLabels`, and `yLabels` so
  plot and waveform apps keep app-authored axis wording without owning axes
  layout mechanics.
- `previewArea` axes install LabKit-managed scroll-wheel navigation by
  default. Wheel events are target-gated to the preview axes under the
  pointer; scrolling over controls, logs, or empty figure space does not zoom
  plots. This does not rely on MATLAB focus-gated `UIAxes.Interactions`, so
  users should not need to click a preview before wheel zoom works. Apps should
  override this only when wheel input changes app data or workflow state rather
  than ordinary axes limits.
- App-specific hand-written layout must go through `labkit.ui.spec.custom` and
  a named builder file, for example:

```matlab
labkit.ui.spec.custom("roiEditor", @example.ui.buildRoiEditor, ...
    "height", "flex")
```

`buildRoiEditor.m` may hand-write layout for that custom tool only. The app
runner, callbacks, and ordinary control specs should not create grids or set
`Layout.Row`/`Layout.Column` directly.
- Control tabs with more than one section include draggable horizontal
  separators between sections by default so users can reallocate vertical
  space between tools. A tab may opt out with `resize="none"` when a fixed
  stack is intentional.

## Busy State

Every `labkit.ui.spec.action` callback runs as an app-wide action transaction.
The framework marks the app busy before invoking the app callback and clears
that busy state after the callback returns or errors. While the figure is busy,
other UI 2.0 semantic callbacks return without invoking app code, so repeated
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
work that is not launched from a UI 2.0 action:

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

`runBusy` intentionally does not create modal progress dialogs. Apps should not
maintain their own busy-control lists, and `runBusy` does not mutate control
`Enable` values. App callbacks still own permanent button enablement logic.

## View Helpers

```matlab
labkit.ui.view.setValue(ui, "displayLimits", [0.1 0.9]);
labkit.ui.view.setEnabled(ui, "run", false);
labkit.ui.view.setListItems(ui, "sourceImages", imageNames);
labkit.ui.view.setListSelection(ui, "sourceImages", imageNames, currentName);
labkit.ui.view.appendLog(ui, "log", "Loaded image.");
labkit.ui.view.drawImage(ui, "preview", imageData, ...
    "axis", "raw", "title", "Reference");
labkit.ui.view.resetAxes(ui, "preview", "Reference", true, "raw");
labkit.ui.view.clearAxes(ui, "preview", "difference");
```

View helpers target semantic ids in the UI registry returned by
`labkit.ui.app.create`. They do not create arbitrary controls or expose MATLAB
layout primitives. `previewArea` axes automatically receive the standard
right-click action `Open axes in new figure`; apps redraw prepared data through
the named preview helpers. `drawImage` preserves the current axes view when an
image is redrawn with the same displayed bounds, so overlay refreshes do not
throw away a user's zoomed preview. Use `resetAxes` or `clearAxes` when an app
intentionally wants to return the preview to its home view.

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
when a tool has stricter data limits.

Use `labkit.ui.tool.anchorEditor(runtime, imageSize, opts)` for generic anchor editing. Use `labkit.ui.tool.scaleBar(parent, row, runtime, opts)` for calibration controls, reference-pixel editing, unit normalization, final scale-bar placement, and overlay drawing. Apps still own image loading, redraw order, scientific calculations, result summaries, alerts, logs, and exports.

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

Debug launches support:

```matlab
[fig, debug] = appName("debug");
```

Apps append visible log lines through `labkit.ui.view.appendLog(ui, "log",
message)` or the app's chosen log-panel id, then call `debug.append(message)`.
Debug-mode apps attach the Log tab text area, emit a startup trace line, pass
`debug.trace` into reusable tools through `onTrace`, and call
`debug.instrumentFigure(fig)` after controls are built.

Each public debug launch also writes a trace file under
`artifacts/debug/<AppName>/`. Official test runs set `LABKIT_ARTIFACTS` and
`LABKIT_RUN_NAME`, so test-launched apps write under
`artifacts/debug/<RunName>/<AppName>/`. The file is the authoritative debug
record when the GUI freezes or the app Log tab is inaccessible; the visible Log
tab is only the human-readable mirror.

Trace is for diagnosing GUI interaction failures, callback errors, stalled file
loads, and environment-sensitive launch problems. It is not workflow
documentation and should not record sensitive file paths, raw sample metadata,
or high-volume pointer movement. Trace lines include timestamp plus stable
`app=...`, `component=...`, `event=...`, and `reason=...` fields. Default
instrumentation wraps semantic callbacks and skips low-level pointer, drag, and
scroll callbacks.

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

`labkit.ui` should not own experiment names, formulas, thresholds, parser calls, result fields, export schemas, plotting annotations, or app-specific callback choreography. Apps pass labels, callbacks, prepared vectors, tables, debug contexts, and option values into UI helpers.

## Validation

Reusable UI contracts are covered by the source-aligned UI and project build
tasks listed in `docs/testing.md`.

Automated GUI tests validate launch, layout, callback wiring, and trace plumbing. Full interactive drawing, file selection, visual inspection, and workflow feel still require manual MATLAB GUI validation.

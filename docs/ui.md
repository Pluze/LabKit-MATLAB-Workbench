# UI Library

`labkit.ui` is the reusable MATLAB GUI foundation. It is split into app-facing facade packages:

| Facade | Owns | Main APIs |
| --- | --- | --- |
| `labkit.ui.app` | Declarative app creation, legacy shell construction, request dispatch, busy state. | `create`, `createShell`, `tab`, `dispatchRequest`, `runBusy`. |
| `labkit.ui.spec` | UI 2.0 data-only workbench specs. | `app`, `workspace`, `tab`, `section`, `field`, `rangeField`, `action`, `actionGroup`, `pathPanel`, `previewArea`, `resultTable`, `logPanel`, `statusPanel`, `custom`. |
| `labkit.ui.view` | Semantic UI 2.0 state updates plus migration-era sections, forms, panels, and axes helpers. | `setValue`, `getValue`, `setEnabled`, `appendLog`, `setListItems`, `setListSelection`, `drawImage`, `resetAxes`, `clearAxes`, plus legacy `section`, `form`, `panel`, `axes`, `draw`, `update`, `place`. |
| `labkit.ui.tool` | Reusable composed image tools and interaction runtime. | `createRuntime`, `anchorEditor`, `scaleBar`, `scaleBarCalibration`. |
| `labkit.ui.diag` | Debug launch context, visible trace, callback instrumentation. | `createContext`. |

The root `labkit.ui.*` flat helper surface has been removed. Apps should call the facade that owns the behavior they need. Private implementation details live under each facade's `private/` folder.

## UI 2.0 Declarative Workbench

The UI 2.0 surface makes app code read as a semantic description
of a LabKit workbench workflow, not as grid construction or a general MATLAB GUI
DSL. The declarative foundation is available for new migration work; existing
apps may still use the legacy app/view helpers below until they are migrated.

```matlab
function varargout = labkit_Example_app(varargin)
[handled, outputs, debug] = labkit.ui.app.dispatchRequest( ...
    "labkit_Example_app", varargin, nargout);
if handled
    varargout = outputs;
    return;
end

spec = labkit.ui.spec.app("exampleApp", "Example App", ...
    "controlTabs", { ...
        labkit.ui.spec.tab("setup", "Setup", { ...
            labkit.ui.spec.section("inputs", "Inputs", { ...
                labkit.ui.spec.pathPanel("sourceImages", "Source images", ...
                    "mode", "multiFile", ...
                    "selectionMode", "single", ...
                    "filters", {{"*.png;*.tif;*.jpg", "Images"}}, ...
                    "status", "No images loaded", ...
                    "onChoose", @onChooseImages), ...
                labkit.ui.spec.field("blendRadius", "Blend radius", ...
                    "kind", "slider", ...
                    "limits", [0 50], ...
                    "value", 12, ...
                    "unit", "px", ...
                    "onChange", @onBlendRadiusChanged), ...
                labkit.ui.spec.rangeField("displayLimits", ...
                    "Display limits", ...
                    "limits", [0 1], ...
                    "value", [0 1], ...
                    "onChange", @onDisplayLimitsChanged), ...
                labkit.ui.spec.actionGroup("runActions", { ...
                    labkit.ui.spec.action("run", "Run", @onRun, ...
                        "priority", "primary"), ...
                    labkit.ui.spec.action("reset", "Reset", @onReset)})})}), ...
        labkit.ui.spec.tab("review", "Review", { ...
            labkit.ui.spec.resultTable("results", "Results", ...
                "columns", {"Name", "Status", "Score"}), ...
            labkit.ui.spec.statusPanel("status", "Status")}), ...
        labkit.ui.spec.tab("log", "Log", { ...
            labkit.ui.spec.logPanel("log", "Log")})}, ...
    "workspace", labkit.ui.spec.workspace("workspace", "Preview", { ...
        labkit.ui.spec.previewArea("preview", "Preview", ...
            "layout", "pair", ...
            "viewModes", {"Input", "Fused", "Difference"}, ...
            "onModeChange", @onPreviewModeChanged)}));

ui = labkit.ui.app.create(spec, "debug", debug);
labkit.ui.view.setEnabled(ui, "run", false);
labkit.ui.view.appendLog(ui, "Ready.");

if nargout >= 1
    varargout{1} = ui.figure;
end
end
```

The fixed shape behind this sketch is:

- The default app shell remains a LabKit workbench: left control tabs plus a
  right workspace for primary preview, plotting, waveform, image, or canvas
  content.
- `controlTabs`, `sections`, workspace children, and slots use cell arrays of
  scalar spec structs for heterogeneous children.
- Control ids are globally unique within the app spec. `ui.controls.run` and
  `ui.controls.sourceImages` are primary registry paths regardless of tab or
  section placement.
- Public specs express stable app shapes: `pathPanel`, `field`, `rangeField`,
  `action`, `actionGroup`, `previewArea`, `resultTable`, `logPanel`, and
  `statusPanel`. Primitive controls such as button, dropdown, slider, listbox,
  textarea, and axes are internal implementation details, not public spec
  constructors.
- `pathPanel` separates chooser mode from list-selection behavior. A workflow
  can load multiple files while keeping one current selection by using
  `mode="multiFile"` with `selectionMode="single"`.
- `pathPanel` owns generic chooser/list/status mechanics while apps own command
  wording. Use `chooseLabel` when the default `Choose files` or `Choose folder`
  text is not the app's user-facing action label, and use `clearLabel` when
  the clear action needs app-specific wording such as `Clear all`.
- `field` uses a fixed kind whitelist: `text`, `number`, `spinner`, `dropdown`,
  `slider`, `checkbox`, and `readonly`.
- Public callbacks use `function callback(control, event)`, where `event`
  carries semantic fields such as `id`, `kind`, `source`, `value`,
  `previousValue`, and `ui`.
- `previewArea` belongs in `workspace` by default. Its optional `viewModes`
  selector is also workspace-owned; apps can react through
  `onModeChange`. Put preview-like content in a left tab only when it is
  intentionally a compact control-pane preview.
- `previewArea` can take `axisIds`, `axisTitles`, `xLabels`, and `yLabels` so
  plot and waveform apps keep app-authored axis wording without owning axes
  layout mechanics.
- App-specific hand-written layout must go through `labkit.ui.spec.custom` and
  a named builder file, for example:

```matlab
labkit.ui.spec.custom("roiEditor", @example.ui.buildRoiEditor, ...
    "height", "flex")
```

`buildRoiEditor.m` may hand-write layout for that custom tool only. The app
runner, callbacks, and ordinary control specs should not create grids or set
`Layout.Row`/`Layout.Column` directly.

## Legacy Standard Shell

Unmigrated apps still start from `labkit.ui.app.createShell`:

```matlab
opts = struct( ...
    'rightTitle', 'Preview', ...
    'rightGridSize', [1 1], ...
    'rightRowHeight', {{'1x'}});
ui = labkit.ui.app.createShell(struct( ...
    'title', 'Example App', ...
    'position', [90 70 1200 800], ...
    'leftWidth', 380, ...
    'options', opts));
```

Default left tabs are:

```text
Files + Analysis
Summary + Results
Log
```

Custom tabs use `labkit.ui.app.tab`:

```matlab
opts.tabs = labkit.ui.app.tab( ...
    'filesAnalysis', 'Files + Analysis', [4 1], ...
    {180, 220, 260, 140});
```

The shell owns split panes, scrollable tab grids, row resize handles, and the right-side grid. Multi-row tabs get resize handles between adjacent logical rows by default. Use `struct('resize','none')` only for tabs whose rows should remain fixed. Apps own the controls and axes placed inside returned grids.

## Legacy Views And Forms

Unmigrated apps use `labkit.ui.view.section` for titled app-defined sections:

```matlab
section = labkit.ui.view.section(layFA, 'Analysis Settings', 2, [3 2]);
grid = section.grid;
```

In unmigrated apps, `labkit.ui.view.form` is the single public control entry
point. It replaces separate labeled spinner/dropdown/edit/read-only helpers:

```matlab
[lblMode, ddMode] = labkit.ui.view.form(grid, struct( ...
    'kind', 'dropdown', ...
    'label', 'Mode:', ...
    'items', {{'Auto', 'Manual'}}, ...
    'value', 'Auto', ...
    'callback', @onModeChanged));

[lblN, edN] = labkit.ui.view.form(grid, struct( ...
    'kind', 'spinner', ...
    'label', 'Samples:', ...
    'value', 10, ...
    'limits', [1 Inf], ...
    'step', 1));

txtStatus = labkit.ui.view.form(grid, struct( ...
    'kind', 'readonly', ...
    'value', 'No file loaded'));

txtMetric = labkit.ui.view.form(grid, struct( ...
    'kind', 'info', ...
    'row', 3, ...
    'label', 'Current value:'));
```

`form` also accepts a section spec with `title`, `row`, `layout`, and `controls`. The returned struct exposes `controls`, `labels`, `setValue(id,value,reason)`, and `getValue(id)`. `setValue` no-ops for unchanged values and suppresses app-facing semantic callbacks for internal/programmatic updates.

In unmigrated shell code, use `labkit.ui.view.place(component, parentGrid,
logicalRow)` when manually placing a component in a shell tab grid. App code
should not depend on physical row indices inserted by row-resize handles.

In unmigrated apps, use `labkit.ui.view.panel` for reusable component groups
such as file panels, log panels, read-only text panels, and result tables:

```matlab
fileUi = labkit.ui.view.panel(layFA, 'files', labels, callbacks);
logUi = labkit.ui.view.panel(layLog, 'log', 1, {'Ready.'});
tableUi = labkit.ui.view.panel(laySR, 'table', 'Batch Results', 2, columns);
```

In unmigrated apps, use `labkit.ui.view.update` for state changes on existing
component handles:

```matlab
labkit.ui.view.update(logUi.textArea, 'appendLog', 'Loaded file.');
[value, idx] = labkit.ui.view.update(fileUi.listbox, ...
    'listSelection', names, previousSelection);
```

## Legacy Axes And Rendering

In unmigrated apps, use legacy view helpers for app-neutral rendering
boilerplate. Migrated apps should prefer `previewArea` in the workspace plus
the named view helpers such as `drawImage`, `resetAxes`, and `clearAxes`.

```matlab
ax = labkit.ui.view.axes(parent, 1, 'Preview', 'X', 'Y');
labkit.ui.view.draw(ax, 'reset', 'Preview', true);
hImage = labkit.ui.view.draw(ax, 'image', imageData, 'Reference');
labkit.ui.view.draw(ax, 'popout');
```

`draw(..., 'popout')` installs the standard right-click action `Open axes in new figure` and attaches it to axes children such as images and plotted lines. Apps should call it after custom redraws that create new graphics children.

## Interaction Tools

Image apps that need scroll, drag, hit-test, anchor editing, ROI-style drawing, or scale bars should create a runtime:

```matlab
runtime = labkit.ui.tool.createRuntime(ax, struct( ...
    'figure', fig, ...
    'defaultScrollFcn', @onPreviewScroll, ...
    'onTrace', debug.trace));
```

The runtime owns exclusive sessions, pointer callbacks, drag capture, scroll ownership, and restoration. Temporary drag callbacks are cleared on normal release and on callback errors before errors are rethrown. Apps should not set `WindowScrollWheelFcn`, `WindowButtonMotionFcn`, `WindowButtonUpFcn`, or image-tool `ButtonDownFcn` directly.

Use `labkit.ui.tool.anchorEditor(runtime, imageSize, opts)` for generic anchor editing. Use `labkit.ui.tool.scaleBar(parent, row, runtime, opts)` for calibration controls, reference-pixel editing, unit normalization, final scale-bar placement, and overlay drawing. Apps still own image loading, redraw order, scientific calculations, result summaries, alerts, logs, and exports.

`labkit.ui.tool.scaleBarCalibration(referencePixels, referenceLength, unitName, opts)` is the GUI-free calibration struct helper used by apps and app-private calculations.

## Diagnostics

Apps route debug launch requests through:

```matlab
[handled, outputs, debug] = labkit.ui.app.dispatchRequest( ...
    appName, varargin, nargout);
```

Debug contexts are created by dispatch for normal app entry points. Non-debug string inputs are rejected by the public app launch path. Apps with nonstandard request paths may call `labkit.ui.diag.createContext(appName, opts)` directly.

Debug launches support:

```matlab
[fig, debug] = appName("__labkit_debug__", opts);
[fig, debug] = appName("debug", opts);
[fig, debug] = appName("--debug", opts);
```

Unmigrated app-local `addLog` functions should append to the visible UI log
with `labkit.ui.view.update(txtLog, 'appendLog', message)` and then call
`debug.append(message)`. Migrated apps should append through
`labkit.ui.view.appendLog(ui, "log", message)` or the app's chosen log-panel
id, then call `debug.append(message)`. Debug-mode apps attach the Log tab text
area, emit a startup trace line, pass `debug.trace` into reusable tools through
`onTrace`, and call `debug.instrumentFigure(fig)` after controls are built.

Trace lines include timestamp plus stable `app=...`, `component=...`, `event=...`, and `reason=...` fields. Default instrumentation skips low-level pointer, drag, and scroll callbacks.

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

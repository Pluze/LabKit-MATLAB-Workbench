# UI Library

`labkit.ui` is the reusable MATLAB GUI foundation. It is now split into four app-facing facade packages:

| Facade | Owns | Main APIs |
| --- | --- | --- |
| `labkit.ui.app` | Figure shell, tabs, request dispatch, busy state. | `createShell`, `tab`, `dispatchRequest`, `runBusy`. |
| `labkit.ui.view` | Sections, forms, component panels, axes rendering, and app-neutral UI state updates. | `section`, `form`, `panel`, `axes`, `draw`, `update`, `place`. |
| `labkit.ui.tool` | Reusable composed image tools and interaction runtime. | `createRuntime`, `anchorEditor`, `scaleBar`, `scaleBarCalibration`. |
| `labkit.ui.diag` | Debug launch context, visible trace, callback instrumentation. | `createContext`. |

The root `labkit.ui.*` flat helper surface has been removed. Apps should call the facade that owns the behavior they need. Private implementation details live under each facade's `private/` folder.

## Standard Shell

Every app should start from `labkit.ui.app.createShell`:

```matlab
opts = struct('rightKind', 'dualPlot');
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
    {180, 220, 260, 140}, ...
    struct('resizeRows', [1 2 3]));
```

The shell owns split panes, scrollable tab grids, and row resize handles. Apps own the controls placed inside returned grids.

## Views And Forms

Use `labkit.ui.view.section` for titled app-defined sections:

```matlab
section = labkit.ui.view.section(layFA, 'Analysis Settings', 2, [3 2]);
grid = section.grid;
```

Use `labkit.ui.view.form` as the single public control entry point. It replaces separate labeled spinner/dropdown/edit/read-only helpers:

```matlab
[lblMode, ddMode] = labkit.ui.view.form(grid, 'dropdown', ...
    'Mode:', 'Items', {'Auto', 'Manual'}, 'Value', 'Auto', ...
    'ValueChangedFcn', @onModeChanged);

[lblN, edN] = labkit.ui.view.form(grid, 'spinner', ...
    'Samples:', 'Value', 10, 'Limits', [1 Inf], 'Step', 1);

txtStatus = labkit.ui.view.form(grid, 'readonly', ...
    'Value', 'No file loaded');

txtMetric = labkit.ui.view.form(grid, 'info', 3, 'Current value:');
```

`form` also accepts a section spec with `title`, `row`, `layout`, and `controls`. The returned struct exposes `controls`, `labels`, `setValue(id,value,reason)`, and `getValue(id)`. `setValue` no-ops for unchanged values and suppresses app-facing semantic callbacks for internal/programmatic updates.

When manually placing a component in a shell tab grid, use `labkit.ui.view.place(component, parentGrid, logicalRow)`. App code should not depend on physical row indices inserted by row-resize handles.

Use `labkit.ui.view.panel` for reusable component groups such as file panels, log panels, read-only text panels, result tables, plot option panels, and top/bottom plot controls:

```matlab
fileUi = labkit.ui.view.panel(layFA, 'files', labels, callbacks);
logUi = labkit.ui.view.panel(layLog, 'log', 1, {'Ready.'});
tableUi = labkit.ui.view.panel(laySR, 'table', 'Batch Results', 2, columns);
```

Use `labkit.ui.view.update` for state changes on existing component handles:

```matlab
labkit.ui.view.update(logUi.textArea, 'appendLog', 'Loaded file.');
[value, idx] = labkit.ui.view.update(fileUi.listbox, ...
    'listSelection', names, previousSelection);
labkit.ui.view.update(plotControls, 'swapPlotSelections');
```

## Axes And Rendering

Use view helpers for app-neutral rendering boilerplate:

```matlab
ax = labkit.ui.view.axes(parent, 1, 'Preview', 'X', 'Y');
labkit.ui.view.draw(ax, 'reset', 'Preview', true);
hImage = labkit.ui.view.draw(ax, 'image', imageData, 'Reference');
info = labkit.ui.view.draw(ax, 'xy', x, y, labels, opts);
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

The runtime owns exclusive sessions, pointer callbacks, drag capture, scroll ownership, and restoration. Apps should not set `WindowScrollWheelFcn`, `WindowButtonMotionFcn`, `WindowButtonUpFcn`, or image-tool `ButtonDownFcn` directly.

Use `labkit.ui.tool.anchorEditor(runtime, imageSize, opts)` for generic anchor editing. Use `labkit.ui.tool.scaleBar(parent, row, runtime, opts)` for calibration controls, reference-pixel editing, unit normalization, final scale-bar placement, and overlay drawing. Apps still own image loading, redraw order, scientific calculations, result summaries, alerts, logs, and exports.

`labkit.ui.tool.scaleBarCalibration(referencePixels, referenceLength, unitName, opts)` is the GUI-free calibration struct helper used by apps and app-private calculations.

## Diagnostics

Apps route internal test/debug launch through:

```matlab
[handled, outputs, debug] = labkit.ui.app.dispatchRequest( ...
    appName, varargin, nargout, handlers);
```

Debug contexts are created by dispatch for normal app entry points. Apps with nonstandard request paths may call `labkit.ui.diag.createContext(appName, opts)` directly.

Debug launches support:

```matlab
[fig, debug] = appName("__labkit_debug__", opts);
[fig, debug] = appName("debug", opts);
[fig, debug] = appName("--debug", opts);
```

App-local `addLog` functions should append to the visible UI log with `labkit.ui.view.update(txtLog, 'appendLog', message)` and then call `debug.append(message)`. Debug-mode apps attach the Log tab text area, emit a startup trace line, pass `debug.trace` into reusable tools through `onTrace`, and call `debug.instrumentFigure(fig)` after controls are built.

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

Reusable UI contracts are covered by:

```bash
scripts/run_matlab_tests.sh --suite labkit/ui --gui
scripts/run_matlab_tests.sh --suite project
```

Automated GUI tests validate launch, layout, callback wiring, and trace plumbing. Full interactive drawing, file selection, visual inspection, and workflow feel still require manual MATLAB GUI validation.

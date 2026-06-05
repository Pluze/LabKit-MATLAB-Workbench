# UI Library

`labkit.ui.*` is the reusable MATLAB GUI foundation. It provides a standard app-shell shape and domain-neutral UI helpers for lab-internal tools.

The UI library should stay small and app-neutral. It owns reusable layout and interaction mechanics; apps own scientific workflow, wording, result definitions, plotting choices, and exports.

## Layer Map

`labkit.ui` is organized around app-facing layers:

| Layer | Owns | Main APIs |
| --- | --- | --- |
| Shell | Figure shell, tabs, split panes, left/right layout, row resizing. | `createAppShell`, `tabSpec`, `layoutRow`, `addRowResizeHandle`. |
| Controls | Labeled controls, read-only fields, file panels, tables, log panels. | `createFileSelectionPanel`, `createPanelGrid`, labeled/read-only helpers, `createResultTablePanel`, `createLogPanel`. |
| Axes | Axes creation/reset, prepared image/plot display, popout. | `createAxes`, `hardResetAxis`, `showImageAxes`, `plotXY`, `enableAxesPopout`, `popoutAxes`. |
| Runtime | Exclusive interaction sessions, callback ownership, busy state. | `createInteractionRuntime`, `runWithBusyState`. |
| Tools | App-neutral composed tools. | `createAnchorCurveEditor`, `createScaleBarTool`, `createScaleBarPanel`, `scaleBarCalibration`. |
| Diagnostics | Debug launch, visible trace, request dispatch, callback instrumentation. | `dispatchAppRequest`, `createDebugContext`. |

Stable app-facing APIs are documented in this file. `createWorkbench`, `createImageAxesRuntime`, `createAppDebugLog`, and `handleAppRequest` remain as deprecated compatibility surface for one migration cycle; new app code should not call them.

## Standard App Shell

Every app should start from the same basic shell:

```text
left side:  resizable tabbed controls
right side: live plots, images, tables, or primary output
```

The default left tabs are:

```text
Files + Analysis
Summary + Results
Log
```

Apps may pass custom tab specs when a workflow needs different pages. The app still owns the controls inside each tab.
The left tab host and each tab content grid are scrollable, so app-specific sections can extend below the visible window without hiding controls.
Tabs can also declare draggable row boundaries through `resizeRows`; this is a shell-level behavior, and app code should continue to use logical grid row numbers.

## Core Entry Point

Use `labkit.ui.createAppShell` for both small and large apps:

```matlab
opts = struct();
opts.rightTitle = 'Plots';
opts.rightGridSize = [1 1];
opts.rightRowHeight = {'1x'};
ui = labkit.ui.createAppShell(struct( ...
    'title', titleText, ...
    'position', position, ...
    'leftWidth', leftWidth, ...
    'options', opts));

dualOpts = struct('rightKind', 'dualPlot');
ui = labkit.ui.createAppShell(struct( ...
    'title', titleText, ...
    'position', position, ...
    'leftWidth', leftWidth, ...
    'options', dualOpts));

imageOpts = struct('rightKind', 'dualPlot', 'showPlotControls', false);
ui = labkit.ui.createAppShell(struct( ...
    'title', titleText, ...
    'position', position, ...
    'leftWidth', leftWidth, ...
    'options', imageOpts));
```

Use `opts.rightKind = 'dualPlot'` for the common top/bottom live-plot layout. By default it includes small top/bottom control panels for axis selectors and plot options. Set `opts.showPlotControls = false` for image/overlay apps that only need the two output axes; this avoids empty control rows compressing the plot area.

For custom right-side arrangements, pass `rightGridSize`, `rightRowHeight`, and `rightRowSpacing`.

App files should not rebuild split-pane layout plumbing, own their own separator-drag behavior, or introduce compatibility shell wrappers around `createAppShell`.

### `createAppShell` Spec

| Field | Type | Default | Valid values / meaning |
| --- | --- | --- | --- |
| `title` | char/string | required | Figure title. |
| `position` | numeric 1-by-4 | required | MATLAB figure position `[x y width height]`. |
| `leftWidth` | scalar | required | Initial left controls width in pixels. |
| `options` | struct | empty | Shell options below. |

### Shell Options

| Option | Type | Default | Valid values / meaning |
| --- | --- | --- | --- |
| `rightKind` | string | `custom` | `custom` or `dualPlot`. |
| `rightGridSize` | numeric row vector | `[1 1]` | Right output grid size for custom right panes. |
| `rightRowHeight` | cell row | `{'1x'}` | Right output grid row heights for custom right panes. |
| `rightRowSpacing` | scalar | `8`, or `10` for `dualPlot` | Right output grid row spacing. |
| `showPlotControls` | logical | `true` | `dualPlot` only; false uses two plot rows without option panels. |
| `controlsTitle` | char/string | `Controls` | Left panel title. |
| `rightTitle` | char/string | `Plots` | Right panel title. |
| `topPlotTitle` | char/string | `Top Plot` | `dualPlot` top controls/axes title. |
| `bottomPlotTitle` | char/string | `Bottom Plot` | `dualPlot` bottom controls/axes title. |
| `tabs` | tabSpec array | standard three tabs | Custom left-tab definitions. |

Custom left-tab sizing is declared in the tab spec:

```matlab
opts.tabs = labkit.ui.tabSpec( ...
    'filesAnalysis', 'Files + Analysis', [4 1], ...
    {240, 210, 330, 170}, ...
    struct('resizeRows', [1 2 3]));
```

Here `resizeRows = [1 2 3]` means the user can drag the boundaries after logical rows 1, 2, and 3. The framework may create internal handle rows, but app code still places sections in rows 1 through 4 through LabKit layout helpers.

### `tabSpec` Options

| Option | Type | Default | Valid values / meaning |
| --- | --- | --- | --- |
| `columnWidth` | cell row | all `{'1x'}` | Column widths for the tab content grid. |
| `resizeRows` | numeric row vector | `[]` | Logical rows after which draggable height handles are inserted. |
| `resizeOptions` | struct | empty | Passed to row resize handle creation. |
| `padding` | numeric 1-by-4 | `[8 8 8 8]` | Tab content grid padding. |
| `rowSpacing` | scalar | `10` | Tab content grid row spacing. |
| `columnSpacing` | scalar | MATLAB default | Tab content grid column spacing. |

## Common Helpers

Construction helpers:

```matlab
labkit.ui.createFileSelectionPanel(parent, labels, callbacks, opts);
labkit.ui.createPanelGrid(parent, titleText, row, gridSize, opts);
labkit.ui.createPlotOptionsPanel(parent, numRows, row);
labkit.ui.createTopBottomPlotControls(topPanel, bottomPanel, xItems, yItems, topDefaults, bottomDefaults, onChange);
labkit.ui.createLabeledDropdown(parent, labelText, ...);
labkit.ui.createLabeledEditField(parent, labelText, style, ...);
labkit.ui.createLabeledSpinner(parent, labelText, ...);
labkit.ui.createReadOnlyTextField(parent, ...);
labkit.ui.createReadOnlyTextPanel(parent, titleText, row, lines, opts);
labkit.ui.createResultTablePanel(parent, titleText, row, columnNames, initialData);
labkit.ui.createLogPanel(parent, row, initialValue);
runtime = labkit.ui.createInteractionRuntime(ax, opts);
labkit.ui.createAnchorCurveEditor(runtime, imageSize, opts);
labkit.ui.createScaleBarPanel(parent, row, opts);
labkit.ui.createScaleBarTool(parent, row, runtime, opts);
labkit.ui.runWithBusyState(fig, workFcn, opts);
labkit.ui.dispatchAppRequest(appName, args, nout, handlers);
labkit.ui.createDebugContext(appName, opts);
```

State and rendering helpers:

```matlab
labkit.ui.appendLog(txtLog, message);
[value, idx] = labkit.ui.refreshListboxSelection(lbFiles, names, preferredSelection, opts);
info = labkit.ui.plotXY(ax, x, y, labels, opts);
cal = labkit.ui.scaleBarCalibration(referencePixels, referenceLength, unitName);
labkit.ui.enableAxesPopout(ax);
fig = labkit.ui.popoutAxes(ax);
hImage = labkit.ui.showImageAxes(ax, imageData, titleText);
```

Use `createPanelGrid` for app-defined sections that only need the standard panel/grid styling. Fixed-height parent tab rows are automatically grown when the declared height is smaller than the section's estimated control height, so default app startup layouts should avoid clipping controls while still allowing user row resizing and scrolling. Use `createLabeledSpinner` for numeric settings that should support click/step adjustment, `createReadOnlyTextField` for single-line status or path display, and `createReadOnlyTextPanel` for app-owned usage notes, file previews, or other read-only multiline text. Use `refreshListboxSelection` for generic single- or multi-select listbox state updates.

### `createPanelGrid` Options

| Option | Type | Default | Valid values / meaning |
| --- | --- | --- | --- |
| `rowHeight` | cell row | all `{'fit'}` | Child grid row heights. |
| `columnWidth` | cell row | all `{'1x'}` | Child grid column widths. |
| `padding` | numeric 1-by-4 | `[8 8 8 8]` | Child grid padding. |
| `rowSpacing` | scalar | `8` | Child grid row spacing. |
| `columnSpacing` | scalar | `8` | Child grid column spacing. |
| `autoGrowParentRow` | logical | `true` | Grows undersized fixed parent tab rows. |
| `minPanelHeight` | scalar | estimated from child grid | Minimum height used by parent-row auto growth. |

Axes created through `labkit.ui.createAxes`, app-shell dual-plot panes, or reset with `labkit.ui.hardResetAxis` get a standard right-click context action named `Open axes in new figure`. The same context menu is attached to plotted child objects such as images, lines, overlays, and ROI previews so image-heavy apps do not block the action. MATLAB does not reliably propagate axes context menus to graphics children created later, so app-local renderers that create new image or overlay objects should call `labkit.ui.enableAxesPopout(ax)` after drawing. It copies the current axes contents, labels, scales, grid state, and basic styling into a separate MATLAB figure for manual editing or export. The copied axes use automatic data and plot-box aspect-ratio modes so the standalone figure can be freely resized. Apps should not implement their own plot-popout behavior unless they need a domain-specific export workflow.

Use `showImageAxes` for app-neutral image display boilerplate: it draws an image, uses image-style axes limits, hides ticks, enables standard image navigation, and refreshes the axes popout menu onto the image object. Apps still own how image arrays, overlays, masks, and annotations are computed.

Use `createInteractionRuntime` before attaching interactive image tools to an axes. The runtime owns figure/axes callback lifecycle for image tools: app-default scroll behavior, exclusive tool sessions, temporary drag callbacks, hit testing, and restoration when a tool deactivates. Apps with special preview scroll or other axes behavior register those callbacks in the runtime spec instead of setting `WindowScrollWheelFcn`, `WindowButtonMotionFcn`, `WindowButtonUpFcn`, or `ButtonDownFcn` directly.

Use `runWithBusyState` around long synchronous callbacks that should give immediate feedback and prevent repeat button clicks. The helper sets a busy pointer, optionally shows an indeterminate progress dialog, disables the controls supplied in `opts.controls`, runs the callback, then restores the prior control states even if the callback errors. Apps still own which controls are passed in and should refresh any final enable/disable state after the helper returns when a computation changes available actions.

Use `tabSpec(..., struct('resizeRows', ...))` when a left tab contains several stacked app-defined sections that may need manual height adjustment. When manually placing a component directly into an app-shell tab grid, map the logical row through `labkit.ui.layoutRow(parentGrid, row)`. Most app code should use helpers such as `createPanelGrid`, `createResultTablePanel`, `createLogPanel`, and `createAxes`, which apply that mapping for their parent row. `labkit.ui.addRowResizeHandle` remains a lower-level helper for unusual app-local grids that intentionally reserve a physical handle row.

Use `createAnchorCurveEditor` when an app or higher-level UI tool needs image anchor editing: double-click blank image space to add or insert anchors, drag anchors to move them, double-click anchors to delete them, switch between curve and straight-line preview, constrain the maximum point count for tools such as two-endpoint reference lines, and optionally install scroll-wheel zoom through the runtime while active. For open paths, new anchors near either endpoint usually extend that endpoint for sequential tracing, while clicks close to an existing visible segment insert correction anchors into the middle. Endpoint extensions that would self-intersect the visible path also become insertions when there is a nearby visible segment. The helper owns generic interaction, runtime sessions, hit testing, and preview graphics. Callers own the higher-level workflow that consumes the edited points.

Use `createScaleBarTool` when an image app needs the common scale-bar workflow. The tool owns the fixed controls, unit normalization, typed or two-endpoint reference-pixel calibration, pixels-per-unit readout, final scale-bar placement, black/white overlay drawing, and reference-edit mode state. The default units are `m`, `cm`, `mm`, `um`, and `nm`; the default position is `Bottom right`; the default color is `Black`; the default reference length and scale-bar length are both `1`.

Apps should pass the interaction runtime into the tool, call `setImageSize` after loading a new image, call `setBackground` with the image graphics handle after redrawing, call `renderOverlay` from the app-local image renderer, and read `calibration()` before app-owned measurements. Pass `opts.onTrace` to capture verbose scale-bar state changes and reference-editor lifecycle messages during debug launches. The calibration struct has `referencePixels`, `referenceLength`, `unit`, `pixelsPerUnit`, `isCalibrated`, and `referenceLine`. Apps still own image loading/redrawing, edit-mode coordination, scientific calculations, result summaries, alerts/log wording, exports, and CSV/table schemas.

`createScaleBarPanel` remains the lower-level reusable control panel for callers that need to own reference drawing or overlay rendering themselves. The returned scale-bar spec includes a two-point `line`, `label`, RGB `color`, `labelPosition`, `verticalAlignment`, `pixelsPerUnit`, `unit`, `barLength`, `position`, and `colorName`.

### `createInteractionRuntime` Options

| Option | Type | Default | Valid values / meaning |
| --- | --- | --- | --- |
| `figure` | figure handle | `ancestor(ax,'figure')` | Owning figure for scroll and drag callbacks. |
| `defaultScrollFcn` | function handle or empty | `[]` | App-default scroll behavior restored when no scroll-owning tool session is active. |
| `onInteractionChanged` | function handle or empty | `[]` | Called as `callback(active, name)` when a runtime session activates or deactivates. |
| `onTrace` | function handle or empty | `[]` | Called as `callback(message)` for verbose debug messages about default scroll ownership and session lifecycle. |

The returned runtime struct exposes `axes`, `figure`, `setDefaultScrollFcn`, `setTraceCallback`, `installDefaultCallbacks`, `createSession`, `isInteractionActive`, and `delete`. App code normally passes the runtime to public tools rather than creating sessions directly.

### `createAnchorCurveEditor` Options

| Option | Type | Default | Valid values / meaning |
| --- | --- | --- | --- |
| `closed` | logical | `false` | True for closed ROI boundaries. |
| `style` | string | `Curve` | `Curve` or `Straight lines`. |
| `installScrollWheel` | logical | `true` | True temporarily uses editor zoom while active; false preserves runtime default scroll behavior. |
| `maxPoints` | positive integer or `Inf` | `Inf` | Maximum number of anchors. |
| `onChanged` | function handle | `[]` | Called after point edits. |
| `onTrace` | function handle or empty | `[]` | Called as `callback(message)` for verbose debug messages about editor lifecycle and pointer interactions. |

The returned editor struct exposes `start`, `setActive`, `setPoints`, `getPoints`, `clearPoints`, `undoLast`, `insertPoint`, `setStyle`, `setImageSize`, `setBackground`, `refresh`, `curvePoints`, and `delete`.

## Callback Lifecycle Policy

Reusable UI helpers and composed tools must keep three callback classes separate:

| Callback class | Purpose |
| --- | --- |
| User semantic callbacks | Notify the app that the user changed app-relevant state. |
| Internal refresh callbacks | Keep controls, graphics, and derived readouts synchronized without re-entering app semantics. |
| Programmatic callbacks | Apply app-initiated state changes and report source as programmatic when exposed through trace. |

All `setX(value)` style APIs should no-op when the requested value is already current. Internal synchronization should not fire app-facing semantic callbacks. Composed tools should trace callback reason/source as `user`, `internal`, or `programmatic` when the event crosses the app/tool boundary. Tools that own pointer, drag, scroll, or hit testing must acquire that ownership through a `createInteractionRuntime` session and restore callbacks when the session ends.

## Internal App Hooks

Apps may use the shared internal hook helpers for tests and maintenance debug logging. These hooks are not user-facing launch APIs.

Canonical test calls use:

```matlab
appName("__labkit_test__", "commandName", arg1, arg2, ...)
```

Apps pass a handler struct array to `labkit.ui.dispatchAppRequest(appName, varargin, nargout, handlers)`. Each handler has `command`, `minArgs`, `maxArgs`, `maxOutputs`, and `run`. The `run` function receives command arguments as a cell array and returns outputs as a cell array. Unsupported commands and invalid requests use app-scoped error IDs such as `<appName>:UnknownTestCommand` and `<appName>:InvalidTestArguments`.

Debug calls use either the compatibility hook or a maintainer-friendly debug alias:

```matlab
[fig, debug] = appName("__labkit_debug__", opts);
[fig, debug] = appName("debug", opts);
[fig, debug] = appName("--debug", opts);
```

`opts.logFile` optionally mirrors appended and trace log lines to a text file, `opts.logCallback` optionally receives each captured line, `opts.traceCallback` optionally receives trace lines, and `opts.traceEnabled` controls verbose trace logging. App-local `addLog` functions should append to the visible UI log and then call `debug.append(message)`. Apps that want visible verbose debug output call `debug.attachTextLog(txtLog)` after creating their Log tab text area, emit a startup trace line, pass `debug.trace` into reusable image-interaction tools through `onTrace`, and call `debug.instrumentFigure(fig)` after controls are built to trace common component callbacks. Trace lines include timestamp plus stable `app=...`, `component=...`, `event=...`, and `reason=...` fields. One-argument `debug.trace(message)` calls use `component=app` and `reason=internal`; composed tools may call `debug.trace(component, event, reason)` with reason/source such as `user`, `internal`, or `programmatic`. The default instrumentation intentionally skips low-level pointer, drag, and scroll callbacks so reading or scrolling the Log tab does not generate more log lines; callers can pass `callbackProperties` explicitly for a narrow low-level trace. Normal `appName()` launches receive a disabled debug log internally and keep existing behavior.

## Ownership Boundary

`labkit.ui.*` may provide:

- app shell creation
- tab specification helpers
- file-selection panels
- log panels and log append helpers
- internal app test/debug hook dispatch and visible trace diagnostics
- panel/grid construction
- row-resize handles for stacked app-defined sections
- interaction runtime ownership for default scroll, exclusive tool modes, drag callbacks, and hit testing
- anchor-curve editing on image axes
- image scale-bar calibration, reference editing, and overlay placement
- plot axes creation, reset, prepared-X/Y plotting, and app-neutral axes popout
- app-neutral image display boilerplate for prepared image arrays
- result table panels
- listbox selection refresh
- busy-state feedback for long synchronous callbacks
- small labeled controls, read-only text surfaces, and domain-neutral state helpers

`labkit.ui.*` should not own:

- experiment names
- formulas, thresholds, or analysis definitions
- parser calls or file-format assumptions
- result field definitions
- export schemas
- app-specific callback choreography

Apps pass labels, callbacks, prepared vectors, table data, and option values into the GUI helpers. Reusable GUI helpers exist to remove MATLAB UI boilerplate, not to hide the domain workflow.

Do not add a UI helper only because one app got large. Extract UI code when the behavior is generic, stable across real apps, and easier to test as a domain-neutral helper than as app-local code.

## UI Validation

Reusable UI helper and shell contracts are covered by the `labkit/ui` suite. Add `--gui` when checking noninteractive layout and callback wiring:

```bash
scripts/run_matlab_tests.sh --suite labkit/ui --gui
scripts/run_matlab_tests.sh --suite gui
```

These checks require MATLAB graphics/uifigure support and are not part of the default GitHub Actions job. The CI job runs the non-GUI suite; final interactive behavior is validated manually in the app windows.

# API Usage Guide

This guide describes the app-facing API surface. New app code should compose `labkit.ui.*` and `labkit.dta.*`; parser, item/session, analysis, utility, and app-helper internals should stay hidden.

## Startup

From MATLAB:

```matlab
startup_labkit
```

This adds the repository root, `apps/`, and normal nested app category folders to the MATLAB path.

## DTA API

Use `labkit.dta.*` for GUI-free DTA discovery, loading, sessions, pulse detection, and parsed table/curve access.

Common loading calls:

```matlab
filepaths = labkit.dta.findFiles(folder);
[item, status] = labkit.dta.loadFile(filepath, "chrono");
[items, report] = labkit.dta.loadFiles(filepaths, "auto");
[items, report] = labkit.dta.loadFolder(folder, "auto");
kind = labkit.dta.detectType(filepath);
```

Supported expected kinds:

```text
"auto"
"chrono"
"eis"
"cvct"
```

Expected kinds are trimmed, case-insensitive, and blank strings default to `"auto"`. Invalid expected kinds raise `labkit:dta:InvalidKind` before loading starts.

Use the smallest loading API that matches the workflow:

```text
One explicit file:        labkit.dta.loadFile
Known list of files:      labkit.dta.loadFiles
Script/prototype folder:  labkit.dta.loadFolder
GUI session app:          labkit.dta.addFilesToSession
```

Session helpers:

```matlab
session = labkit.dta.makeSession('new_experiment');
[session, report] = labkit.dta.addFilesToSession(session, files, "chrono", callbacks);
[selectedItems, idx] = labkit.dta.selectSessionItems(session, selectedNames);
[session, report] = labkit.dta.removeSelectedItemsFromSession(session, selectedNames, callbacks);
labkit.dta.saveSession(session, filepath);
session = labkit.dta.loadSession(filepath);
```

Parsed table and curve helpers:

```matlab
[curve, ok, msg] = labkit.dta.getMainCurve(item.tables);
[zcurve, ok, msg] = labkit.dta.getZCurve(item.tables);
values = labkit.dta.getColumn(curve, 'Vf');
[x, y, xName, yName] = labkit.dta.getCurveXY(curve, 'T', 'Im');
```

Pulse detection:

```matlab
[pulse, message] = labkit.dta.detectPulses(t, Im, meta, "Metadata first, then auto");
```

Chrono loading also exposes the experiment control mode inferred from DTA step metadata:

```matlab
[item, status] = labkit.dta.loadFile(filepath, "chrono");
item.controlMode   % "current", "voltage", or "unknown"
```

Lower-level recursive discovery, parser functions, item construction, session mutation, and pulse internals are private DTA implementation details. Apps should not call `labkit.io.*`, `labkit.data.*`, `labkit.analysis.*`, or `labkit.util.*`.

## GUI API

Use `labkit.ui.*` for domain-neutral GUI structure and rendering helpers. Apps provide labels, callbacks, prepared values, and experiment-specific behavior.

Common shell and control helpers:

```matlab
opts = struct();
opts.rightTitle = 'Plots';
opts.rightGridSize = [1 1];
opts.rightRowHeight = {'1x'};
ui = labkit.ui.createWorkbench(titleText, position, leftWidth, opts);

dualOpts = struct('rightKind', 'dualPlot');
ui = labkit.ui.createWorkbench(titleText, position, leftWidth, dualOpts);

labkit.ui.createFileSelectionPanel(parent, labels, callbacks, opts);
labkit.ui.createPanelGrid(parent, titleText, row, gridSize, opts);
labkit.ui.createPlotOptionsPanel(parent, numRows, row);
labkit.ui.createTopBottomPlotControls(topPanel, bottomPanel, xItems, yItems, topDefaults, bottomDefaults, onChange);
labkit.ui.createResultTablePanel(parent, titleText, row, columnNames, initialData);
labkit.ui.createLogPanel(parent, row, initialValue);
```

Common state/render helpers:

```matlab
labkit.ui.appendLog(txtLog, message);
labkit.ui.refreshListboxItems(lbFiles, names);
[value, idx] = labkit.ui.refreshListboxSelection(lbFiles, names, preferredSelection, opts);
info = labkit.ui.plotXY(ax, x, y, labels, opts);
```

The default app shell is a resizable left/right workbench layout: left controls live in tabbed pages and the right side is reserved for live plots, curves, images, or other primary outputs. Use `createWorkbench` for both small and large apps. The default tabs are `Files + Analysis`, `Summary + Results`, and `Log`; apps may pass custom tab specs when a workflow needs different tab pages.

Use `opts.rightKind = 'dualPlot'` for the common top/bottom live-plot layout. For custom right-side arrangements, pass `rightGridSize`, `rightRowHeight`, and `rightRowSpacing`. Compatibility wrappers such as `createStandardWorkbenchShell` and `createTabbedDualPlotShell` remain available for older code, but new app entry points should call `createWorkbench` directly.

All DTA-facing apps should use `createFileSelectionPanel` for file actions. Use `opts.multiselect = 'on'` and `opts.showRemoveSelected = true` for overlay apps that operate on selected subsets; omit those options for single-current-file apps such as CIC and VT.

Use `createPanelGrid` for app-defined scientific sections that only need the standard panel/grid styling. The panel title and all controls remain app-owned. Use `refreshListboxSelection` for generic single- or multi-select listbox state updates; loading, analysis, refresh ordering, alerts, and log wording remain app-owned.

GUI helpers should not contain experiment names, formulas, thresholds, result columns, parser calls, or export formats.

## Templates

Template source files live under `templates/` and are copy-only starting points, not runtime app entry points:

```text
templates/gui_only_app_template.m       GUI helpers only
templates/dta_only_script_template.m    DTA facade only
templates/gui_dta_app_template.m        GUI helpers plus DTA facade
```

Copy one into an `apps/<category>/` folder only when starting a real experiment app. Keep the copied app explicit and local; do not create a helper package just because two callbacks look similar.

## App Layout

Keep new experiment apps as explicit single files, organized roughly in this order:

```text
1. Entry validation and optional test hook
2. App state and GUI construction
3. Nested callbacks for file/session actions
4. Nested refresh/render/export callbacks that touch UI handles
5. End of the public app function
6. App-local analysis functions
7. App-local table/export functions
8. App-local plotting annotation helpers
9. Small formatting, parsing, interpolation, and numeric utilities
```

Nested functions may read and update GUI handles or app state. Local functions after the app `end` should be GUI-free when practical so tests can call them through narrow app test hooks.

The app owns:

- accepted DTA kind
- scientific options and defaults
- analysis formulas and result fields
- plot labels and annotations
- summary text
- result table columns and export formatting
- failed-row behavior

Move code into `+labkit` only when it is reusable without experiment vocabulary.

## New App Checklist

Define these before adding controls or helpers:

```text
1. Accepted DTA kind and parser requirements
2. Session kind and loaded item shape
3. Scientific options and defaults
4. Analysis result fields
5. Plot axes, labels, and annotations
6. Summary fields shown in the GUI
7. Result table columns and units
8. Export format and failed-row behavior
9. Validation fixture or synthetic test case
10. GUI shell type and file-selection mode
```

Prefer `labkit.ui.createWorkbench` even when the app has only one small control page. This keeps daily app interaction consistent as `apps/<category>/` grows while leaving scientific tab content under app ownership.

Add focused tests for parser/DTA facade behavior, item/result fields, analysis values, export tables, and app entrypoint boundaries. Run `scripts/run_matlab_tests.sh`; add `--gui` when entrypoints, layout construction, callbacks, or GUI helpers change.

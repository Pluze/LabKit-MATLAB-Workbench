# API Usage Guide

This guide describes the app-facing API surface. New app code should compose `gamrywb.ui.*` and `gamrywb.dta.*`; parser, item/session, analysis, utility, and app-helper internals should stay hidden.

## Startup

From MATLAB:

```matlab
startup_gamrywb
```

This adds the repository root, `apps/`, and normal nested app category folders to the MATLAB path.

## DTA API

Use `gamrywb.dta.*` for GUI-free DTA discovery, loading, sessions, pulse detection, and parsed table/curve access.

Common loading calls:

```matlab
filepaths = gamrywb.dta.findFiles(folder);
[item, status] = gamrywb.dta.loadFile(filepath, "chrono");
[items, report] = gamrywb.dta.loadFiles(filepaths, "auto");
[items, report] = gamrywb.dta.loadFolder(folder, "auto");
kind = gamrywb.dta.detectType(filepath);
```

Supported expected kinds:

```text
"auto"
"chrono"
"eis"
"cvct"
```

Expected kinds are trimmed, case-insensitive, and blank strings default to `"auto"`. Invalid expected kinds raise `gamrywb:dta:InvalidKind` before loading starts.

Use the smallest loading API that matches the workflow:

```text
One explicit file:        gamrywb.dta.loadFile
Known list of files:      gamrywb.dta.loadFiles
Script/prototype folder:  gamrywb.dta.loadFolder
GUI session app:          gamrywb.dta.addFilesToSession
```

Session helpers:

```matlab
session = gamrywb.dta.makeSession('new_experiment');
[session, report] = gamrywb.dta.addFilesToSession(session, files, "chrono", callbacks);
[selectedItems, idx] = gamrywb.dta.selectSessionItems(session, selectedNames);
[session, report] = gamrywb.dta.removeSelectedItemsFromSession(session, selectedNames, callbacks);
gamrywb.dta.saveSession(session, filepath);
session = gamrywb.dta.loadSession(filepath);
```

Parsed table and curve helpers:

```matlab
[curve, ok, msg] = gamrywb.dta.getMainCurve(item.tables);
[zcurve, ok, msg] = gamrywb.dta.getZCurve(item.tables);
values = gamrywb.dta.getColumn(curve, 'Vf');
[x, y, xName, yName] = gamrywb.dta.getCurveXY(curve, 'T', 'Im');
```

Pulse detection:

```matlab
[pulse, message] = gamrywb.dta.detectPulses(t, Im, meta, "Metadata first, then auto");
```

Chrono loading also exposes the experiment control mode inferred from DTA step metadata:

```matlab
[item, status] = gamrywb.dta.loadFile(filepath, "chrono");
item.controlMode   % "current", "voltage", or "unknown"
```

Lower-level recursive discovery, parser functions, item construction, session mutation, and pulse internals are private DTA implementation details. Apps should not call `gamrywb.io.*`, `gamrywb.data.*`, `gamrywb.analysis.*`, or `gamrywb.util.*`.

## GUI API

Use `gamrywb.ui.*` for domain-neutral GUI structure and rendering helpers. Apps provide labels, callbacks, prepared values, and experiment-specific behavior.

Common shell and control helpers:

```matlab
ui = gamrywb.ui.createTwoPaneShell(titleText, position, leftWidth, rightTitle, rowCount, rowHeights, spacing);
ui = gamrywb.ui.createTabbedDualPlotShell(titleText, position, leftWidth, startDragFcn, labels);

gamrywb.ui.createFilePanel(parent, labels, callbacks);
gamrywb.ui.createSingleSelectFilePanel(parent, labels, callbacks);
gamrywb.ui.createPlotOptionsPanel(parent, numRows);
gamrywb.ui.createTopBottomPlotControls(topPanel, bottomPanel, xItems, yItems, topDefaults, bottomDefaults, onChange);
gamrywb.ui.createResultTablePanel(parent, titleText, row, columnNames, initialData);
gamrywb.ui.createLogPanel(parent, row, initialValue);
```

Common state/render helpers:

```matlab
gamrywb.ui.appendLog(txtLog, message);
gamrywb.ui.refreshListboxItems(lbFiles, names);
info = gamrywb.ui.plotXY(ax, x, y, labels, opts);
```

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

Move code into `+gamrywb` only when it is reusable without experiment vocabulary.

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

Add focused tests for parser/DTA facade behavior, item/result fields, analysis values, export tables, and app entrypoint boundaries. Run `scripts/run_matlab_tests.sh`; add `--gui` when entrypoints, layout construction, callbacks, or GUI helpers change.

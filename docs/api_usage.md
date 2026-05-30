# API Usage Guide

This guide shows how future single-file apps should compose the reusable `+gamrywb` APIs.

The intended shape is:

```text
apps/gamrywb_NewExperiment_app.m
  calls +gamrywb GUI APIs
  calls +gamrywb Gamry/DTA APIs
  owns experiment-specific analysis, plots, summaries, and exports
```

Do not create a new reusable app framework unless repeated real apps prove that it is clearer than explicit app code.

## Startup

From MATLAB:

```matlab
startup_gamrywb
```

This adds the repository root and `apps/` to the MATLAB path.

## Gamry/DTA API

Use `+gamrywb/+dta` when app code needs GUI-free DTA discovery or loading.

Recursive DTA discovery:

```matlab
filepaths = gamrywb.dta.findFiles(folder);
```

`folder` may be a character vector or scalar string and must name an existing folder.

```matlab
[item, status] = gamrywb.dta.loadFile(filepath, "chrono");
if ~status.ok
    error('%s', char(status.message));
end
```

Supported expected kinds:

```text
"auto"
"chrono"
"eis"
"cvct"
```

Expected kinds are normalized consistently across `loadFile`, `loadFiles`, and `loadFolder`: surrounding whitespace is trimmed, case is ignored, and a blank string defaults to `"auto"`.
Invalid expected kinds are programmer errors and raise `gamrywb:dta:InvalidKind` before loading starts, including empty batch and empty-folder loads.

Batch loading:

```matlab
[items, report] = gamrywb.dta.loadFiles(filepaths, "auto");
```

Empty file lists are valid and return no items plus a zero-count report.

Folder loading:

```matlab
[items, report] = gamrywb.dta.loadFolder(folder, "auto");
```

Folders with no DTA files return no items and a zero-count report.

Type detection:

```matlab
kind = gamrywb.dta.detectType(filepath);
```

Chrono pulse detection:

```matlab
[pulse, message] = gamrywb.dta.detectPulses(t, Im, meta, "Metadata first, then auto");
```

Lower-level discovery and parser functions remain available for parser tests and format work:

```matlab
filepaths = gamrywb.io.findDTAFilesRecursive(folder);
[meta, tables] = gamrywb.io.parseChronoDTA(filepath);
[meta, tables] = gamrywb.io.parseEISDTA(filepath);
[scanRate, curves] = gamrywb.io.parseCVCTDTA(filepath);
```

Prefer the DTA facade in apps. Use direct IO discovery or parsers only when changing parser behavior, adding a DTA family, or writing parser-level tests.

Choose the smallest loading API that matches the workflow:

```text
One explicit file:        gamrywb.dta.loadFile
Known list of files:      gamrywb.dta.loadFiles
Script/prototype folder:  gamrywb.dta.loadFolder
GUI session app:          gamrywb.dta.addFilesToSession
Parser development:       gamrywb.io.parse* and gamrywb.io.findDTAFilesRecursive
```

Use `loadFolder` for scripts and prototypes that do not need duplicate handling or GUI callback timing. Use the DTA session helpers in apps that maintain loaded-file state, listboxes, logs, or remove/clear workflows.

## DTA Session Facade

New DTA-backed apps should normally start with these app-facing helpers:

```matlab
session = gamrywb.dta.makeSession('new_experiment');
[session, report] = gamrywb.dta.addFilesToSession(session, files, "chrono", callbacks);
[selectedItems, idx] = gamrywb.dta.selectSessionItems(session, selectedNames);
[session, report] = gamrywb.dta.removeSelectedItemsFromSession(session, selectedNames, callbacks);
```

This keeps normal app code on the DTA surface instead of exposing the lower-level loader callback used by `+gamrywb/+data`.

`addFilesToSession` reports:

```text
added, skipped, failed, nAdded, nSkipped, nFailed
```

The app still owns `refreshPlots`, `addLog`, export behavior, alerts, and any app-specific reset/default-selection behavior. Do not move that choreography into `+gamrywb/+ui` unless multiple real apps prove that a generic helper is clearer.

## Lower-Level Data API

Use `+gamrywb/+data` only when app code genuinely needs parsed table/curve access:

```matlab
[curve, ok, msg] = gamrywb.data.getMainCurve(item.tables);
[zcurve, ok, msg] = gamrywb.data.getZCurve(item.tables);
values = gamrywb.data.getColumn(curve, 'Vf');
[x, y] = gamrywb.data.getCurveXY(curve, 'T', 'Im');
```

Apps should not call lower-level session or item-construction helpers.
Use the DTA session facade for those workflows.

Session structs are plain structs. Do not convert them to MATLAB classes without an explicit design change and tests.

## GUI API

Use `+gamrywb/+ui` for reusable interface structure. GUI helpers should be domain-neutral.

Common shell helpers:

```matlab
ui = gamrywb.ui.createTwoPaneShell(titleText, position, leftWidth, rightTitle, rowCount, rowHeights, spacing);
ui = gamrywb.ui.createTabbedDualPlotShell(titleText, position, leftWidth, startDragFcn, labels);
```

Common controls and panels:

```matlab
gamrywb.ui.createFilePanel(parent, labels, callbacks);
gamrywb.ui.createSingleSelectFilePanel(parent, labels, callbacks);
gamrywb.ui.createPlotOptionsPanel(parent, numRows);
gamrywb.ui.createTopBottomPlotControls(topPanel, bottomPanel, xItems, yItems, topDefaults, bottomDefaults, onChange);
gamrywb.ui.createResultTablePanel(parent, titleText, row, columnNames, initialData);
gamrywb.ui.createLogPanel(parent, row, initialValue);
```

Apps own domain-specific labels such as "Open DTA file(s)" or export-button text and pass them through `labels`; reusable GUI helpers should not encode Gamry/DTA wording.

Multi-file panel labels:

```matlab
labels = struct( ...
    'panelTitle', 'Files', ...
    'openFiles', 'Open DTA file(s)', ...
    'openFolder', 'Open folder recursively', ...
    'removeSelected', 'Remove selected', ...
    'clearAll', 'Clear all', ...
    'export', 'Export curves CSV');
```

Single-select file panel labels:

```matlab
labels = struct( ...
    'panelTitle', 'Files', ...
    'openFiles', 'Open DTA file(s)', ...
    'openFolder', 'Open folder recursively', ...
    'clearAll', 'Clear all', ...
    'export', 'Export results CSV', ...
    'loadedText', 'No files loaded');
```

Tabbed dual-plot shell labels:

```matlab
labels = struct( ...
    'controlsPanel', 'Controls', ...
    'filesAnalysisTab', 'Files + Analysis', ...
    'summaryResultsTab', 'Summary + Results', ...
    'logTab', 'Log', ...
    'plotsPanel', 'Plots', ...
    'topPlot', 'Top Plot', ...
    'bottomPlot', 'Bottom Plot');
```

Common state helpers:

```matlab
gamrywb.ui.appendLog(txtLog, message);
gamrywb.ui.refreshListboxItems(lbFiles, names);
[x, y, xName, yName] = gamrywb.data.getCurveXY(curve, 'T', 'Im');
labels = struct('title', curve.name, 'x', xName, 'y', yName);
info = gamrywb.ui.plotXY(ax, x, y, labels, opts);
```

GUI helpers should not contain experiment names, formulas, thresholds, result columns, or export formats.
They should also receive prepared values from the app or data layer rather than calling parser, DTA, session, or analysis APIs themselves.

## Internal Helpers

New apps should not call `+gamrywb/+util`, `+gamrywb/+io`, or any internal helper package directly.
Those functions are lower-level implementation surfaces for the GUI, DTA, and data APIs.
If a new app seems to need one of them, first check whether the behavior belongs behind `gamrywb.dta.*`, `gamrywb.ui.*`, or a small app-local helper.

## Template Programs

Template source files live under `templates/` and are not runtime app entry points:

```text
templates/gui_only_app_template.m       GUI helpers only
templates/dta_only_script_template.m    DTA facade only
templates/gui_dta_app_template.m        GUI helpers plus DTA facade
```

Copy one into `apps/` only when starting a real experiment app. Keep the copied app explicit and local; do not create a helper package just because the template has repeated callback shape.

## Single-File App Template

Use this as a starting shape, not as a framework contract:

```matlab
function varargout = gamrywb_NewExperiment_app(varargin)
%GAMRYWB_NEWEXPERIMENT_APP Launch the new experiment app.

    if nargin > 0
        error('gamrywb_NewExperiment_app:UnsupportedInput', ...
            'gamrywb_NewExperiment_app does not accept input arguments.');
    end
    if nargout > 1
        error('gamrywb_NewExperiment_app:TooManyOutputs', ...
            'gamrywb_NewExperiment_app returns at most the app figure handle.');
    end

    S = struct();
    S.session = gamrywb.dta.makeSession('new_experiment');

    ui = gamrywb.ui.createTwoPaneShell( ...
        'New Experiment', [80 60 1400 850], 360, ...
        'Plot', [1 1], {'1x'}, 8);
    fig = ui.fig;

    if nargout == 1
        varargout{1} = fig;
    end

    function item = loadOne(filepath)
        [item, status] = gamrywb.dta.loadFile(filepath, "chrono");
        if ~status.ok
            error('%s', char(status.message));
        end
    end

    function R = analyzeItem(item, opts)
        % Keep experiment-specific formulas and result fields local.
        R = struct();
        R.ok = false;
        R.message = 'Not implemented';
    end
end
```

For a folder-processing script or an early analysis prototype, the app shell is unnecessary:

```matlab
[items, report] = gamrywb.dta.loadFolder(folder, "chrono");
results = cellfun(@(item) analyzeItem(item, opts), items, 'UniformOutput', false);
```

The app owns:

- accepted DTA kind
- analysis options and formulas
- result struct fields
- plot labels and annotations
- export column names and formatting
- summary text

## New App Checklist

Define these before adding controls or helpers:

```text
1. Accepted DTA kind and parser requirements
2. Session kind and loaded item shape
3. Scientific options and defaults
4. Analysis result struct fields
5. Plot axes, labels, and annotations
6. Summary fields shown in the GUI
7. Result table columns and units
8. Export format and failed-row behavior
9. Validation fixture or synthetic test case
10. GUI shell type and file-selection mode
```

Keep those decisions local to the app file. Move code into `+gamrywb` only when it is reusable without experiment vocabulary.

## Testing Expectations

For a new app or DTA family, add focused tests for:

- parser or DTA facade behavior
- item/result struct fields
- analysis values against a fixture or synthetic case
- export table or CSV format
- app entrypoint boundary checks

Keep app-specific workflow code local to the owning public app file. Do not introduce an app-specific helper package just to make a local function public to tests; use narrow app test hooks only when direct numerical/export coverage is needed and the behavior belongs to one app.

Run:

```bash
scripts/run_matlab_tests.sh
```

Run GUI checks when app entrypoints, layout construction, callbacks, or GUI helper behavior change:

```bash
scripts/run_matlab_tests.sh --gui
```

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

Batch loading:

```matlab
[items, report] = gamrywb.dta.loadFiles(filepaths, "auto");
```

Folder loading:

```matlab
[items, report] = gamrywb.dta.loadFolder(folder, "auto");
```

Type detection:

```matlab
kind = gamrywb.dta.detectType(filepath);
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
GUI session app:          gamrywb.data.loadFilesIntoSession or addFilesToSession
Parser development:       gamrywb.io.parse* and gamrywb.io.findDTAFilesRecursive
```

Use `loadFolder` for scripts and prototypes that do not need duplicate handling or GUI callback timing. Use the session helpers in apps that maintain loaded-file state, listboxes, logs, or remove/clear workflows.

## Data And Session API

Use `+gamrywb/+data` for struct construction and table/curve access:

```matlab
session = gamrywb.data.makeSession('new_experiment');
[session, report] = gamrywb.data.addFilesToSession(session, files, @loader);
[session, report] = gamrywb.data.loadFilesIntoSession(session, files, @loader, callbacks);
[session, report] = gamrywb.data.removeSelectedItemsFromSession(session, selectedNames, callbacks);

[curve, ok, msg] = gamrywb.data.getMainCurve(item.tables);
[zcurve, ok, msg] = gamrywb.data.getZCurve(item.tables);
values = gamrywb.data.getColumn(curve, 'Vf');
[x, y] = gamrywb.data.getCurveXY(curve, 'T', 'Im');
items = gamrywb.data.selectItemsByNames(session.items, selectedNames);
summary = gamrywb.data.summarizeBatchResults(session.items);
```

Session structs are plain structs. Do not convert them to MATLAB classes without an explicit design change and tests.

For a GUI app that owns a loaded-file list, keep the callback choreography local and use the data/session helpers for the GUI-free parts:

```matlab
S.session = gamrywb.data.makeSession('new_experiment');
S.items = S.session.items;

function loadFiles(filepaths)
    if isempty(filepaths)
        return;
    end

    callbacks = struct();
    callbacks.onAdded = @(filepath, ~) addLog(sprintf('Loaded: %s', filepath));
    callbacks.onSkipped = @(filepath) addLog(sprintf('Skipped already loaded: %s', filepath));
    callbacks.onFailed = @(filepath, message) addLog(sprintf('Failed: %s | %s', filepath, message));

    [S.session, report] = gamrywb.data.loadFilesIntoSession( ...
        S.session, filepaths, @loadOne, callbacks);
    S.items = S.session.items;

    refreshFileList();
    refreshPlots();

    if ~isempty(report.failed)
        firstError = report.failed(1);
        uialert(fig, sprintf('Failed to load:\n%s\n\n%s', ...
            firstError.filepath, firstError.message), 'Load error');
    end
end

function refreshFileList()
    if isempty(S.items)
        gamrywb.ui.refreshListboxItems(lbFiles, {});
    else
        gamrywb.ui.refreshListboxItems(lbFiles, {S.items.name});
    end
end

function onOpenFiles(~, ~)
    [names, folder] = uigetfile( ...
        {'*.DTA;*.dta', 'Gamry DTA (*.DTA)'; '*.*', 'All files'}, ...
        'Select one or more DTA files', ...
        'MultiSelect', 'on');
    if isequal(names, 0)
        addLog('Open cancelled.');
        return;
    end

    if ischar(names) || isstring(names)
        names = {char(names)};
    end
    loadFiles(cellfun(@(name) fullfile(folder, name), names, 'UniformOutput', false));
end

function onOpenFolder(~, ~)
    folder = uigetdir(pwd, 'Select a folder to recursively scan for .DTA files');
    if isequal(folder, 0)
        addLog('Folder selection cancelled.');
        return;
    end

    filepaths = gamrywb.dta.findFiles(folder);
    if isempty(filepaths)
        addLog(sprintf('No DTA files found under: %s', folder));
        uialert(fig, sprintf('No .DTA files found under:\n%s', folder), 'No files found');
        return;
    end

    addLog(sprintf('Found %d DTA file(s) under %s', numel(filepaths), folder));
    loadFiles(filepaths);
end

function onRemoveSelected(~, ~)
    callbacks = struct();
    callbacks.onRemoved = @(name, ~) addLog(sprintf('Removed: %s', name));
    [S.session, ~] = gamrywb.data.removeSelectedItemsFromSession( ...
        S.session, lbFiles.Value, callbacks);
    S.items = S.session.items;
    refreshFileList();
    refreshPlots();
end

function onClearAll(~, ~)
    S.session = gamrywb.data.makeSession('new_experiment');
    S.items = S.session.items;
    refreshFileList();
    refreshPlots();
    addLog('Cleared all files.');
end
```

The app still owns `refreshPlots`, `addLog`, export behavior, alerts, and any app-specific reset/default-selection behavior. Do not move that choreography into `+gamrywb/+ui` unless multiple real apps prove that a generic helper is clearer.

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
info = gamrywb.ui.plotCurveXY(ax, curve, 'T', 'Im', opts);
```

GUI helpers should not contain experiment names, formulas, thresholds, result columns, or export formats.

## Utility API

Use `+gamrywb/+util` only for small cross-cutting helpers:

```matlab
name = gamrywb.util.shortName(filepath);
escaped = gamrywb.util.csvEscape(textValue);
fieldName = gamrywb.util.sanitizeFieldName(rawName);
value = gamrywb.util.parsePositiveScalar(textValue);
idx = gamrywb.util.nearestIndex(t, targetTime);
value = gamrywb.util.interp1Safe(t, y, targetTime);
```

Do not move code into `+util` just because it is short. It must be useful across layers and explainable without experiment vocabulary.

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
    S.session = gamrywb.data.makeSession('new_experiment');
    S.items = S.session.items;

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

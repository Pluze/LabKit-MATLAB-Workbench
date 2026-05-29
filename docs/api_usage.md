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

Use `+gamrywb/+dta` when app code needs a GUI-free loader.

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

Type detection:

```matlab
kind = gamrywb.dta.detectType(filepath);
```

Lower-level parser functions remain available for parser tests and format work:

```matlab
[meta, tables] = gamrywb.io.parseChronoDTA(filepath);
[meta, tables] = gamrywb.io.parseEISDTA(filepath);
[scanRate, curves] = gamrywb.io.parseCVCTDTA(filepath);
```

Prefer the DTA facade in apps. Use direct parsers only when changing parser behavior, adding a DTA family, or writing parser-level tests.

## Data And Session API

Use `+gamrywb/+data` for struct construction and table/curve access:

```matlab
session = gamrywb.data.makeSession('new_experiment');
[session, report] = gamrywb.data.addFilesToSession(session, files, @loader);

[curve, ok, msg] = gamrywb.data.getMainCurve(item.tables);
[zcurve, ok, msg] = gamrywb.data.getZCurve(item.tables);
values = gamrywb.data.getColumn(curve, 'Vf');
[x, y] = gamrywb.data.getCurveXY(curve, 'T', 'Im');
summary = gamrywb.data.summarizeBatchResults(session.items);
```

Session structs are plain structs. Do not convert them to MATLAB classes without an explicit design change and tests.

## GUI API

Use `+gamrywb/+ui` for reusable interface structure. GUI helpers should be domain-neutral.

Common shell helpers:

```matlab
ui = gamrywb.ui.createTwoPaneShell(titleText, position, leftWidth, rightTitle, rowCount, rowHeights, spacing);
ui = gamrywb.ui.createTabbedDualPlotShell(titleText, position, leftWidth, startDragFcn);
```

Common controls and panels:

```matlab
gamrywb.ui.createFilePanel(parent, exportButtonText, callbacks);
gamrywb.ui.createSingleSelectFilePanel(parent, exportButtonText, callbacks);
gamrywb.ui.createPlotOptionsPanel(parent, numRows);
gamrywb.ui.createTopBottomPlotControls(topPanel, bottomPanel, xItems, yItems, topDefaults, bottomDefaults, onChange);
gamrywb.ui.createResultTablePanel(parent, titleText, row, columnNames, initialData);
gamrywb.ui.createLogPanel(parent, row, initialValue);
```

Common state helpers:

```matlab
gamrywb.ui.appendLog(txtLog, message);
gamrywb.ui.refreshFileListbox(lbFiles, items);
gamrywb.ui.refreshSingleSelectFileListbox(lbFiles, items, selectedIndex);
items = gamrywb.ui.selectItemsByNames(session.items, selectedNames);
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

The app owns:

- accepted DTA kind
- analysis options and formulas
- result struct fields
- plot labels and annotations
- export column names and formatting
- summary text

## Testing Expectations

For a new app or DTA family, add focused tests for:

- parser or DTA facade behavior
- item/result struct fields
- analysis values against a fixture or synthetic case
- export table or CSV format
- app entrypoint boundary checks

When an app-specific helper package is kept only so pure functions remain directly testable, whitelist its `.m` files in the app-boundary tests. Do not let `apps/+gamrywb_apps` grow into a reusable framework. Once an app can keep its workflow local without losing meaningful tests, remove the helper package.

Run:

```bash
scripts/run_matlab_tests.sh
```

Run GUI checks when app entrypoints, layout construction, callbacks, or GUI helper behavior change:

```bash
scripts/run_matlab_tests.sh --gui
```

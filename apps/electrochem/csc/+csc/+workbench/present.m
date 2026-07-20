% App-owned implementation for csc.workbench.present within the csc product workflow.
function view = present(applicationState)
%PRESENT Adapt CSC runtime state into choices, comparison, and named axes.
items = applicationState.session.cache.items;
parameters = applicationState.project.parameters;
selection = applicationState.session.selection;
choices = csc.analysisRun.analysisChoices();
index = selectedIndex(selection.files, numel(items));

[item, curveLabels, curveIndex, columns] = selectedCurve( ...
    items, index, selection.currentCurve, choices);
[axisValues, axisChoices] = effectiveAxes(parameters, columns, choices);
[tableData, tableColumns, analysis, readout] = comparisonPresentation( ...
    item, curveIndex, parameters, choices);
model = struct( ...
    "top", axisModel(item, curveIndex, axisValues, parameters, ...
        "top", analysis), ...
    "bottom", axisModel(item, curveIndex, axisValues, parameters, ...
        "bottom", analysis));

view = labkit.app.view.Snapshot() ...
    .choices("curve", curveLabels) ...
    .value("curve", curveLabels(max(1, curveIndex + 1))) ...
    .tableData("cycleResults", tableData, Columns=tableColumns) ...
    .renderPlot("plotAxes", model) ...
    .text("filePath", itemPath(item)) ...
    .text("scanRate", scanRateText(item));
for id = ["topX", "topY", "bottomX", "bottomY"]
    view = view.choices(id, axisChoices).value(id, axisValues.(id));
end
view = view.text("qct", readout.qctText) ...
    .text("qcv", readout.qcvText) ...
    .text("diff", readout.diffText) ...
    .text("relativeDiff", readout.relText) ...
    .text("dtError", readout.dtErrText) ...
    .text("status", readout.statusText);
end

function [item, labels, curveIndex, columns] = selectedCurve( ...
        items, itemIndex, requestedCurve, choices)
item = [];
labels = choices.empty;
curveIndex = 0;
columns = choices.empty;
if itemIndex == 0
    return
end
item = items(itemIndex);
labels = choices.allCycles;
for k = 1:numel(item.curves)
    labels(end + 1) = string(sprintf("%s (%d rows)", ...
        item.curves(k).name, size(item.curves(k).data, 1)));
end
if isempty(item.curves)
    labels = choices.empty;
    return
end
position = find(labels == string(requestedCurve), 1);
if ~isempty(position)
    curveIndex = position - 1;
end
sourceIndex = max(1, curveIndex);
curve = item.curves(sourceIndex);
columns = string(curve.headers(curve.numericMask));
if isempty(columns)
    columns = choices.empty;
end
end

function [values, columns] = effectiveAxes(parameters, columns, choices)
columns = reshape(string(columns), 1, []);
if isempty(columns)
    columns = choices.empty;
end
defaults = csc.analysisRun.defaultPlotSelections(cellstr(columns));
values = struct();
for id = ["topX", "topY", "bottomX", "bottomY"]
    requested = string(parameters.(id));
    if ~any(columns == requested)
        requested = string(defaults.(id));
    end
    if strlength(requested) == 0
        requested = columns(1);
    end
    values.(id) = requested;
end
end

function [data, columns, analysis, readout] = comparisonPresentation( ...
        item, curveIndex, parameters, choices)
columns = string(csc.analysisRun.cycleResultsColumnNames(parameters.mode));
data = cell(0, numel(columns));
analysis = struct();
readout = emptyReadout();
if isempty(item)
    return
end
options = comparisonOptions(item, parameters);
results = csc.resultFiles.buildResultsTable(item, options);
data = csc.analysisRun.cycleResultsTableData(results, parameters.mode);
if curveIndex == 0
    readout.qctText = "See all-cycle table";
    readout.qcvText = "See all-cycle table";
    readout.diffText = "See all-cycle table";
    readout.relText = "See all-cycle table";
    readout.dtErrText = maxDtErrorText(results);
    readout.statusText = sprintf( ...
        "Showing %d cycle result(s).", height(results));
    return
end
analysis = csc.analysisRun.computeCSC( ...
    item.curves(curveIndex), options);
readout = csc.analysisRun.comparisonReadout( ...
    analysis, choices.modes( ...
        find(choices.modes == string(parameters.mode), 1)));
end

function model = axisModel(item, curveIndex, values, parameters, axisId, analysis)
model = struct( ...
    "valid", false, "axisId", axisId, ...
    "title", upperFirst(axisId) + " Plot", ...
    "curves", struct([]), "curveIndex", 0, ...
    "xSelection", values.(axisId + "X"), ...
    "ySelection", values.(axisId + "Y"), ...
    "showGrid", logical(parameters.(axisId + "Grid")), ...
    "holdPlot", logical(parameters.(axisId + "Hold")), ...
    "showTrim", logical(parameters.(axisId + "Trim")), ...
    "analysis", analysis, "curveIndices", []);
if isempty(item) || isempty(item.curves)
    return
end
model.valid = true;
model.curves = item.curves;
model.curveIndex = curveIndex;
model.curveIndices = plottedCurveIndices( ...
    numel(item.curves), parameters.ignoreEdgeCycles);
end

function options = comparisonOptions(item, parameters)
options = struct( ...
    "mode", char(parameters.mode), ...
    "scanRate", item.scanRate, ...
    "area_cm2", parameters.area, ...
    "ignoreEdgeCycles", logical(parameters.ignoreEdgeCycles));
end

function value = emptyReadout()
value = struct("qctText", "", "qcvText", "", "diffText", "", ...
    "relText", "", "dtErrText", "", "statusText", "Ready");
end

function text = maxDtErrorText(results)
text = "";
if ~isempty(results) && height(results) > 0 && ...
        any(isfinite(results.DtError_s))
    text = sprintf("max %.12e s", ...
        max(results.DtError_s, [], "omitnan"));
end
end

function indices = plottedCurveIndices(count, ignoreEdges)
indices = 1:count;
if ignoreEdges && count > 0
    indices = indices(indices ~= 1 & indices ~= count);
end
end

function value = itemPath(item)
value = "";
if ~isempty(item) && isfield(item, "filepath")
    value = string(item.filepath);
end
end

function value = scanRateText(item)
value = "";
if isempty(item)
    return
end
if isfinite(item.scanRate)
    value = sprintf("%.6f V/s (%.3f mV/s)", ...
        item.scanRate, item.scanRate * 1000);
else
    value = "Not found";
end
end

function index = selectedIndex(selection, count)
index = 0;
if count > 0
    index = 1;
    if ~isempty(selection.Indices)
        index = min(max(1, selection.Indices(1)), count);
    end
end
end

function text = upperFirst(value)
text = char(value);
text(1) = upper(text(1));
text = string(text);
end

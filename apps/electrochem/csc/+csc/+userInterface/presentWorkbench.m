% Expected caller: Runtime V2. Input is canonical CSC state. Output is one
% deterministic files/curve/comparison/two-axis presentation with no UI or IO.
function view = presentWorkbench(state)
    items = state.session.cache.items;
    parameters = state.project.parameters;
    index = boundedIndex(state.session.selection.currentIndex, numel(items));
    choices = csc.userInterface.analysisChoices();

    view = struct();
    view.controls.files = filePanelSpec(items, index);
    if index == 0
        view = presentEmpty(view, parameters, choices);
        view = presentAxes(view, emptyAxisModel("top"), ...
            emptyAxisModel("bottom"));
        return;
    end

    item = items(index);
    curveLabels = labelsForCurves(item.curves, choices);
    selectedCurve = selectedCurveIndex( ...
        state.session.selection.currentCurve, curveLabels);
    columns = numericColumns(item.curves, selectedCurve, choices);
    view.controls.filePath = struct("Value", string(item.filepath));
    view.controls.scanRate = struct("Value", scanRateText(item.scanRate));
    view.controls.curve = struct( ...
        "Items", {cellstr(curveLabels)}, ...
        "Value", curveLabels(selectedCurve + 1));
    view = presentPlotChoices(view, columns, parameters);

    opts = comparisonOptions(item, parameters);
    results = csc.resultFiles.buildResultsTable(item, opts);
    view.controls.cycleResults = struct( ...
        "ColumnName", {csc.userInterface.cycleResultsColumnNames( ...
            parameters.mode)}, ...
        "Data", {csc.userInterface.cycleResultsTableData( ...
            results, parameters.mode)});
    [view, analysis] = presentComparison( ...
        view, item, selectedCurve, results, opts, choices);
    top = axisModel(item, selectedCurve, parameters, "top", analysis);
    bottom = axisModel(item, selectedCurve, parameters, "bottom", analysis);
    view = presentAxes(view, top, bottom);
end

function view = presentEmpty(view, parameters, choices)
    view.controls.filePath = struct("Value", "");
    view.controls.scanRate = struct("Value", "");
    view.controls.curve = struct( ...
        "Items", {{char(choices.empty)}}, "Value", choices.empty);
    view = presentPlotChoices(view, choices.empty, parameters);
    view.controls.cycleResults = struct( ...
        "ColumnName", {csc.userInterface.cycleResultsColumnNames( ...
            parameters.mode)}, "Data", {cell(0, 6)});
    view = setReadouts(view, "", "", "", "", "", "Ready");
end

function view = presentPlotChoices(view, columns, parameters)
    columns = string(columns(:)).';
    if isempty(columns)
        columns = csc.userInterface.analysisChoices().empty;
    end
    ids = ["topX", "topY", "bottomX", "bottomY"];
    for id = ids
        value = string(parameters.(id));
        if ~any(columns == value)
            value = columns(1);
        end
        view.controls.(id) = struct( ...
            "Items", {cellstr(columns)}, "Value", value);
    end
end

function [view, analysis] = presentComparison( ...
        view, item, selectedCurve, results, opts, choices)
    analysis = struct();
    if selectedCurve == 0
        view = setReadouts(view, ...
            "See all-cycle table", "See all-cycle table", ...
            "See all-cycle table", "See all-cycle table", ...
            maxDtErrorText(results), sprintf( ...
            'Showing %d cycle result(s) normalized by %s', ...
            height(results), areaStatusText(opts.area_cm2)));
        return;
    end
    analysis = csc.analysisRun.computeCSC( ...
        item.curves(selectedCurve), opts);
    readout = csc.userInterface.comparisonReadout(analysis, opts.mode);
    view = setReadouts(view, readout.qctText, readout.qcvText, ...
        readout.diffText, readout.relText, readout.dtErrText, ...
        readout.statusText);
end

function view = setReadouts(view, qct, qcv, difference, relative, dt, status)
    ids = ["qct", "qcv", "diff", "relativeDiff", "dtError", "status"];
    values = {qct, qcv, difference, relative, dt, status};
    for k = 1:numel(ids)
        view.controls.(ids(k)) = struct("Value", values{k});
    end
end

function view = presentAxes(view, top, bottom)
    view.previews.plotAxes.Axes.top = struct( ...
        "Renderer", "cscAxis", "Model", top);
    view.previews.plotAxes.Axes.bottom = struct( ...
        "Renderer", "cscAxis", "Model", bottom);
end

function model = axisModel(item, curveIndex, p, axisId, analysis)
    model = emptyAxisModel(axisId);
    if isempty(item.curves)
        return;
    end
    model.valid = true;
    model.curves = item.curves;
    model.curveIndex = curveIndex;
    model.xSelection = string(p.(axisId + "X"));
    model.ySelection = string(p.(axisId + "Y"));
    model.showGrid = logical(p.(axisId + "Grid"));
    model.holdPlot = logical(p.(axisId + "Hold"));
    model.showTrim = logical(p.(axisId + "Trim"));
    model.analysis = analysis;
    model.curveIndices = plottedCurveIndices( ...
        numel(item.curves), p.ignoreEdgeCycles);
end

function model = emptyAxisModel(axisId)
    model = struct( ...
        "valid", false, "axisId", axisId, ...
        "title", upperFirst(axisId) + " Plot", ...
        "curves", struct([]), "curveIndex", 0, ...
        "xSelection", "", "ySelection", "", ...
        "showGrid", true, "holdPlot", false, "showTrim", false, ...
        "analysis", struct(), "curveIndices", []);
end

function spec = filePanelSpec(items, index)
    files = struct("id", {}, "path", {}, "status", {});
    for k = 1:numel(items)
        files(end + 1) = struct( ...
            "id", "item" + string(k), ...
            "path", string(items(k).filepath), "status", "");
    end
    selection = strings(0, 1);
    if index > 0
        selection = "item" + string(index);
    end
    status = "No files loaded";
    if ~isempty(items)
        status = string(numel(items)) + " file(s) loaded";
    end
    spec = struct("Files", files, "Selection", selection, "Status", status);
end

function labels = labelsForCurves(curves, choices)
    labels = choices.allCycles;
    for k = 1:numel(curves)
        labels(end + 1) = string(sprintf('%s (%d rows)', ...
            curves(k).name, size(curves(k).data, 1)));
    end
    if isempty(curves)
        labels = choices.empty;
    end
end

function index = selectedCurveIndex(value, labels)
    position = find(labels == string(value), 1);
    if isempty(position)
        index = 0;
    else
        index = position - 1;
    end
end

function columns = numericColumns(curves, selectedCurve, choices)
    if isempty(curves)
        columns = choices.empty;
        return;
    end
    index = selectedCurve;
    if index < 1 || index > numel(curves)
        index = 1;
    end
    curve = curves(index);
    columns = string(curve.headers(curve.numericMask));
    if isempty(columns)
        columns = choices.empty;
    end
end

function opts = comparisonOptions(item, parameters)
    opts = struct( ...
        "mode", char(parameters.mode), ...
        "scanRate", item.scanRate, ...
        "area_cm2", parameters.area, ...
        "ignoreEdgeCycles", logical(parameters.ignoreEdgeCycles));
end

function text = scanRateText(scanRate)
    if isnan(scanRate)
        text = "Not found";
    else
        text = string(sprintf('%.6f V/s (%.3f mV/s)', ...
            scanRate, scanRate * 1000));
    end
end

function indices = plottedCurveIndices(count, ignoreEdges)
    indices = 1:count;
    if ignoreEdges && count > 0
        indices = indices(indices ~= 1 & indices ~= count);
    end
end

function text = maxDtErrorText(results)
    if isempty(results) || height(results) == 0 || all(isnan(results.DtError_s))
        text = "";
    else
        text = string(sprintf('max %.12e s', ...
            max(results.DtError_s, [], 'omitnan')));
    end
end

function text = areaStatusText(area)
    parsed = str2double(strtrim(char(string(area))));
    if isnumeric(area)
        parsed = area;
    end
    if isscalar(parsed) && isfinite(parsed) && parsed > 0
        text = sprintf('%.6g cm^2', parsed);
    else
        text = 'charge only (area not set)';
    end
end

function text = upperFirst(value)
    text = string(value);
    chars = char(text);
    chars(1) = upper(chars(1));
    text = string(chars);
end

function index = boundedIndex(index, count)
    if count == 0
        index = 0;
    else
        index = min(max(1, round(double(index))), count);
    end
end

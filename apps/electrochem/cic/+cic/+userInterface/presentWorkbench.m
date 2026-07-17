% Expected caller: Runtime V2. Input is canonical CIC state. Output is one
% deterministic control/table/summary/two-axis presentation with no UI
% registry access or side effects.
function view = presentWorkbench(state)
    items = state.session.cache.items;
    sources = state.project.inputs.sources;
    parameters = state.project.parameters;
    index = boundedIndex(state.session.selection.currentIndex, numel(sources));
    itemIndex = loadedItemIndex(items, sources, index);
    [~, unitLabel] = cic.userInterface.displayUnit(parameters.cicUnit);
    [tableData, columns] = cic.userInterface.buildBatchTableData( ...
        items, unitLabel);
    summary = cic.userInterface.buildCurrentSummary( ...
        items, itemIndex, parameters.cicMode, parameters.cicUnit);

    view = struct();
    view.controls.files = filePanelSpec(sources, items, index);
    view.controls.results = struct();
    view.controls.results.Data = tableData;
    view.controls.results.ColumnName = columns;
    view = applySummary(view, summary);
    view.previews.plotAxes.Axes.top = struct( ...
        "Renderer", "cicAxis", ...
        "Model", axisModel(items, itemIndex, parameters, "top"));
    view.previews.plotAxes.Axes.bottom = struct( ...
        "Renderer", "cicAxis", ...
        "Model", axisModel(items, itemIndex, parameters, "bottom"));
end

function spec = filePanelSpec(sources, items, index)
    files = struct("id", {}, "path", {}, "status", {});
    paths = labkit.ui.runtime.sourcePaths(sources);
    for k = 1:numel(paths)
        files(end + 1) = struct( ...
            "id", "item" + string(k), ...
            "path", paths(k), ...
            "status", pathStatus(items, paths(k)));
    end
    selection = strings(0, 1);
    if index > 0
        selection = "item" + string(index);
    end
    spec = struct( ...
        "Files", files, ...
        "Selection", selection, ...
        "Status", fileStatus(numel(paths)));
end

function value = pathStatus(items, filepath)
    itemIndex = find(string({items.filepath}) == filepath, 1);
    if isempty(itemIndex)
        value = "deferred";
    else
        value = analysisStatus(items(itemIndex));
    end
end

function value = analysisStatus(item)
    value = "";
    if isfield(item, 'analysis') && isstruct(item.analysis) && ...
            isfield(item.analysis, 'ok') && ~item.analysis.ok
        value = "analysis failed";
    end
end

function value = fileStatus(count)
    if count == 0
        value = "No files loaded";
    else
        value = string(count) + " file(s) registered";
    end
end

function view = applySummary(view, summary)
    fields = ["controlMode", "detect", "delay", "areaSummary", ...
        "emc", "ema", "qc", "qa", "qt", "safe", "best"];
    values = {summary.controlMode, summary.detect, summary.delay, ...
        summary.area, summary.emc, summary.ema, summary.qc, summary.qa, ...
        summary.qt, summary.safe, summary.bestSafe};
    for k = 1:numel(fields)
        view.controls.(fields(k)) = struct("Value", values{k});
    end
end

function model = axisModel(items, index, parameters, whichAxis)
    model = struct( ...
        "valid", false, ...
        "message", "", ...
        "title", axisTitle(whichAxis), ...
        "request", struct(), ...
        "analysis", struct(), ...
        "showMarkers", logical(parameters.showMarkers), ...
        "showLimits", logical(parameters.showLimits), ...
        "showShading", logical(parameters.showShading), ...
        "showGrid", axisGrid(parameters, whichAxis));
    if index == 0
        return;
    end
    item = items(index);
    if isempty(item.analysis) || ~item.analysis.ok
        model.message = "No valid analysis";
        return;
    end
    [xChoice, yChoice] = axisChoices(parameters, whichAxis);
    model.valid = true;
    model.request = cic.userInterface.plotRequest( ...
        item.analysis, item.name, xChoice, yChoice);
    model.analysis = item.analysis;
end

function [xChoice, yChoice] = axisChoices(parameters, whichAxis)
    if whichAxis == "top"
        xChoice = parameters.topX;
        yChoice = parameters.topY;
    else
        xChoice = parameters.bottomX;
        yChoice = parameters.bottomY;
    end
end

function value = axisGrid(parameters, whichAxis)
    if whichAxis == "top"
        value = logical(parameters.topGrid);
    else
        value = logical(parameters.bottomGrid);
    end
end

function value = axisTitle(whichAxis)
    if whichAxis == "top"
        value = "Top Plot";
    else
        value = "Bottom Plot";
    end
end

function index = boundedIndex(index, count)
    if count == 0
        index = 0;
    else
        index = min(max(1, round(double(index))), count);
    end
end

function itemIndex = loadedItemIndex(items, sources, sourceIndex)
    itemIndex = 0;
    if sourceIndex == 0 || isempty(items)
        return;
    end
    paths = labkit.ui.runtime.sourcePaths(sources);
    match = find(string({items.filepath}) == paths(sourceIndex), 1);
    if ~isempty(match)
        itemIndex = match;
    end
end

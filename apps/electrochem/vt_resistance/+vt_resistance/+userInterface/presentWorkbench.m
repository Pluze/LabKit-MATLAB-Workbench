% Expected caller: Runtime V2. Input is canonical VT Resistance state. Output
% is one deterministic control/table/summary/two-axis presentation with no UI
% registry access or side effects.
function view = presentWorkbench(state)
    items = state.session.cache.items;
    parameters = state.project.parameters;
    index = boundedIndex(state.session.selection.currentIndex, numel(items));

    view = struct();
    view.controls.files = filePanelSpec(items, index);
    view.controls.results = struct();
    view.controls.results.Data = ...
        vt_resistance.userInterface.buildBatchTableData(items);
    view = applySummary(view, currentSummary(items, index));
    view.previews.plotAxes.Axes.top = struct( ...
        "Renderer", "resistanceAxis", ...
        "Model", axisModel(items, index, parameters, "top"));
    view.previews.plotAxes.Axes.bottom = struct( ...
        "Renderer", "resistanceAxis", ...
        "Model", axisModel(items, index, parameters, "bottom"));
end

function spec = filePanelSpec(items, index)
    files = struct("id", {}, "path", {}, "status", {});
    for k = 1:numel(items)
        files(end + 1) = struct( ...
            "id", "item" + string(k), ...
            "path", string(items(k).filepath), ...
            "status", analysisStatus(items(k)));
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

function value = analysisStatus(item)
    value = "";
    if isfield(item, 'analysis') && isstruct(item.analysis) && ...
            isfield(item.analysis, 'ok') && ~item.analysis.ok
        value = "analysis failed";
    end
end

function summary = currentSummary(items, index)
    fields = ["controlMode", "detect", "window", "cathIV", "anodIV", ...
        "cathBase", "anodBase", "cathBaseWindow", "anodBaseWindow", ...
        "cathR", "anodR", "averageR", "status"];
    summary = cell2struct(repmat({'-'}, 1, numel(fields)), ...
        cellstr(fields), 2);
    if index == 0
        return;
    end
    item = items(index);
    summary.controlMode = chronoControlModeText(item);
    if isempty(item.analysis) || ~item.analysis.ok
        if ~isempty(item.analysis) && isfield(item.analysis, 'message')
            summary.status = item.analysis.message;
        else
            summary.status = 'No valid analysis';
        end
        return;
    end
    a = item.analysis;
    summary.detect = sprintf('%s | %s', a.detectMode, a.detectMsg);
    summary.window = sprintf('%s | %s', a.windowMode, a.voltageMode);
    summary.cathIV = sprintf('I=%.6e A | Vss=%.6f V | dV=%.6f V', ...
        a.Ic_est_A, a.Vc_ss_V, a.dVc_V);
    summary.anodIV = sprintf('I=%.6e A | Vss=%.6f V | dV=%.6f V', ...
        a.Ia_est_A, a.Va_ss_V, a.dVa_V);
    summary.cathBase = sprintf('%.6f V', a.Vc_baseline_V);
    summary.anodBase = sprintf('%.6f V', a.Va_baseline_V);
    summary.cathBaseWindow = ...
        vt_resistance.userInterface.formatDurationUs(a.cathBaselineWindow_s);
    summary.anodBaseWindow = ...
        vt_resistance.userInterface.formatDurationUs(a.anodBaselineWindow_s);
    summary.cathR = sprintf('%.6g ohm (signed %.6g)', ...
        a.Rc_abs_ohm, a.Rc_ohm);
    summary.anodR = sprintf('%.6g ohm (signed %.6g)', ...
        a.Ra_abs_ohm, a.Ra_ohm);
    summary.averageR = sprintf('%.6g ohm', a.Ravg_abs_ohm);
    summary.status = a.message;
end

function view = applySummary(view, summary)
    fields = string(fieldnames(summary));
    for k = 1:numel(fields)
        view.controls.(fields(k)) = struct( ...
            "Value", summary.(fields(k)));
    end
end

function out = chronoControlModeText(item)
    out = 'Unknown chrono control mode';
    if ~isfield(item, 'controlMode')
        return;
    end
    switch string(item.controlMode)
        case "current"
            out = 'Current-controlled chrono';
        case "voltage"
            out = 'Voltage-controlled chrono';
    end
end

function model = axisModel(items, index, parameters, whichAxis)
    model = struct( ...
        "valid", false, "message", "", "title", axisTitle(whichAxis), ...
        "analysis", struct(), "itemName", "", "xChoice", "", ...
        "yChoice", "", "showMarkers", logical(parameters.showMarkers), ...
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
    model.valid = true;
    model.analysis = item.analysis;
    model.itemName = string(item.name);
    if whichAxis == "top"
        model.xChoice = string(parameters.topX);
        model.yChoice = string(parameters.topY);
    else
        model.xChoice = string(parameters.bottomX);
        model.yChoice = string(parameters.bottomY);
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

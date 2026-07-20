% App-owned implementation for vt_resistance.workbench.present within the vt_resistance product workflow.
function view = present(applicationState)
%PRESENT Adapt VT state into its table, summary, and named plot models.
items = applicationState.session.cache.items;
parameters = applicationState.project.parameters;
selection = applicationState.session.selection.files;
index = selectedIndex(selection, numel(items));
tableData = vt_resistance.analysisRun.buildBatchTableData(items);
summary = currentSummary(items, index);
model = struct("top", axisModel(items, index, parameters, "top"), ...
    "bottom", axisModel(items, index, parameters, "bottom"));
columns = ["File", "Ic (A)", "Ia (A)", "Vc ss (V)", "Va ss (V)", ...
    "R cath (ohm)", "R anod (ohm)", "R avg (ohm)", "Detection"];
view = labkit.app.view.Snapshot() ...
    .tableData("results", tableData, Columns=columns) ...
    .renderPlot("plotAxes", model);
ids = string(fieldnames(summary));
for k = 1:numel(ids)
    view = view.text(ids(k), string(summary.(ids(k))));
end
end

function model = axisModel(items, index, p, whichAxis)
model = struct("valid", false, "message", "", ...
    "title", upperFirst(whichAxis) + " Plot", ...
    "analysis", struct(), "itemName", "", "xChoice", "", "yChoice", "", ...
    "showMarkers", logical(p.showMarkers), ...
    "showShading", logical(p.showShading), "showGrid", true);
if index == 0 || isempty(items(index).analysis) || ~items(index).analysis.ok
    return
end
model.valid = true;
model.analysis = items(index).analysis;
model.itemName = string(items(index).name);
if whichAxis == "top"
    model.xChoice = string(p.topX);
    model.yChoice = string(p.topY);
    model.showGrid = logical(p.topGrid);
else
    model.xChoice = string(p.bottomX);
    model.yChoice = string(p.bottomY);
    model.showGrid = logical(p.bottomGrid);
end
end

function value = upperFirst(value)
value = char(string(value));
value(1) = upper(value(1));
value = string(value);
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

function summary = currentSummary(items, index)
names = ["controlMode", "detect", "window", "cathIV", "anodIV", ...
    "cathBase", "anodBase", "cathBaseWindow", "anodBaseWindow", ...
    "cathR", "anodR", "averageR", "status"];
summary = cell2struct(repmat({'-'}, 1, numel(names)), cellstr(names), 2);
if index == 0
    return
end
item = items(index);
summary.controlMode = controlModeText(item);
if isempty(item.analysis) || ~item.analysis.ok
    if ~isempty(item.analysis) && isfield(item.analysis, "message")
        summary.status = item.analysis.message;
    else
        summary.status = "No valid analysis";
    end
    return
end
a = item.analysis;
summary.detect = sprintf("%s | %s", a.detectMode, a.detectMsg);
summary.window = sprintf("%s | %s", a.windowMode, a.voltageMode);
summary.cathIV = sprintf("I=%.6e A | Vss=%.6f V | dV=%.6f V", ...
    a.Ic_est_A, a.Vc_ss_V, a.dVc_V);
summary.anodIV = sprintf("I=%.6e A | Vss=%.6f V | dV=%.6f V", ...
    a.Ia_est_A, a.Va_ss_V, a.dVa_V);
summary.cathBase = sprintf("%.6f V", a.Vc_baseline_V);
summary.anodBase = sprintf("%.6f V", a.Va_baseline_V);
summary.cathBaseWindow = ...
    vt_resistance.analysisRun.formatDurationUs(a.cathBaselineWindow_s);
summary.anodBaseWindow = ...
    vt_resistance.analysisRun.formatDurationUs(a.anodBaselineWindow_s);
summary.cathR = sprintf("%.6g ohm (signed %.6g)", ...
    a.Rc_abs_ohm, a.Rc_ohm);
summary.anodR = sprintf("%.6g ohm (signed %.6g)", ...
    a.Ra_abs_ohm, a.Ra_ohm);
summary.averageR = sprintf("%.6g ohm", a.Ravg_abs_ohm);
summary.status = a.message;
end

function text = controlModeText(item)
text = "Unknown chrono control mode";
if ~isfield(item, "controlMode")
    return
end
if string(item.controlMode) == "current"
    text = "Current-controlled chrono";
elseif string(item.controlMode) == "voltage"
    text = "Voltage-controlled chrono";
end
end

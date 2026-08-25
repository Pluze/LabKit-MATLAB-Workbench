%PRESENT Build axis controls and the editable per-tick table.
function view = present(editor, hasFigure)
view = labkit.app.view.Snapshot();
if isempty(editor.document.panels)
    panel = emptyPanel();
    axisValue = emptyAxis();
else
    panelIndex = find(string({editor.document.panels.id}) == ...
        editor.activePanelId, 1);
    if isempty(panelIndex), panelIndex = 1; end
    panel = editor.document.panels(panelIndex);
    axisName = figure_studio.axisEditing.axisField(editor.axisTarget);
    if ~isfield(panel.axes, axisName)
        editor.axisTarget = "X";
        axisName = "x";
    end
    axisValue = panel.axes.(char(axisName));
end
view = view.value("figureTitle", panel.text.title) ...
    .value("figureSubtitle", panel.text.subtitle) ...
    .value("xAxisLabel", panel.text.xLabel) ...
    .value("yAxisLabel", panel.text.yLabel) ...
    .value("rightYAxisLabel", textFieldValue(panel.text, "yRightLabel")) ...
    .choices("axisTarget", availableAxes(panel)) ...
    .value("axisTarget", editor.axisTarget) ...
    .value("axisScale", axisValue.scale) ...
    .value("axisDirection", axisValue.direction) ...
    .value("axisMinimum", axisValue.limits(1)) ...
    .value("axisMaximum", axisValue.limits(2)) ...
    .value("axisLocation", locationValue(axisValue.location)) ...
    .value("tickLocator", locatorDisplay(axisValue.locator.mode)) ...
    .value("tickCount", axisValue.locator.count) ...
    .value("tickStep", displayStep(axisValue.locator.step)) ...
    .value("tickFormatter", formatterDisplay(axisValue.formatter.mode)) ...
    .value("tickPrecision", displayPrecision(axisValue.formatter.precision)) ...
    .value("tickPrefix", axisValue.formatter.prefix) ...
    .value("tickSuffix", axisValue.formatter.suffix) ...
    .tableData("tickTable", tickTable(axisValue.ticks), ...
        Columns=["Value", "Label", "Show", "Level", "Rotation", ...
            "Font size", "Weight", "Color"], ...
        RowNames=string(1:numel(axisValue.ticks))) ...
    .tableCellSelection("tickTable", ...
        labkit.app.event.TableCellSelection(selectionCells(editor.selectedTickRows)));
ids = ["figureTitle", "figureSubtitle", "xAxisLabel", "yAxisLabel", ...
    "rightYAxisLabel", ...
    "axisTarget", "axisScale", "axisDirection", "axisMinimum", ...
    "axisMaximum", "axisLocation", "tickLocator", ...
    "tickCount", "tickStep", "tickFormatter", "tickPrecision", ...
    "tickPrefix", "tickSuffix", "tickTable", "addTick"];
for id = ids
    view = view.enabled(id, hasFigure);
end
view = view.enabled("undoFigureEdit", hasFigure && ~isempty(editor.history.past)) ...
    .enabled("redoFigureEdit", hasFigure && ~isempty(editor.history.future)) ...
    .enabled("deleteTicks", hasFigure && ~isempty(editor.selectedTickRows));
end

function value = locationValue(value)
value = string(value);
if strlength(value) == 0, value = "auto"; end
end

function values = availableAxes(panel)
values = ["X", "Y"];
if isfield(panel.axes, "yRight")
    values(end + 1) = "Right Y";
end
values(end + 1) = "Z";
end

function value = textFieldValue(owner, name)
if isstruct(owner) && isfield(owner, name)
    value = owner.(name);
else
    value = "";
end
end

function data = tickTable(ticks)
data = cell(numel(ticks), 8);
for k = 1:numel(ticks)
    data{k, 1} = ticks(k).value;
    data{k, 2} = char(ticks(k).label);
    data{k, 3} = logical(ticks(k).visible);
    data{k, 4} = char(ticks(k).level);
    data{k, 5} = ticks(k).rotation;
    data{k, 6} = overrideValue(ticks(k).fontOverride, "FontSize", []);
    data{k, 7} = char(string(overrideValue( ...
        ticks(k).fontOverride, "FontWeight", "")));
    data{k, 8} = char(colorText(overrideValue( ...
        ticks(k).fontOverride, "Color", [])));
end
end

function value = overrideValue(owner, name, fallback)
if isstruct(owner) && isfield(owner, name)
    value = owner.(name);
else
    value = fallback;
end
end

function value = colorText(color)
if isnumeric(color) && numel(color) == 3
    value = join(compose("%.3g", color(:).'), " ");
else
    value = "";
end
end

function cells = selectionCells(rows)
rows = unique(double(rows(:)));
rows = rows(isfinite(rows) & rows >= 1 & rows == fix(rows));
cells = [rows ones(numel(rows), 1)];
end

function value = displayStep(value)
if isempty(value) || ~isscalar(value) || ~isfinite(value) || value <= 0
    value = 1;
end
end

function value = displayPrecision(value)
if isempty(value), value = 6; end
end

function value = locatorDisplay(value)
switch lower(string(value))
    case {"auto", "source"}, value = "Auto";
    case "nice-count", value = "Nice count";
    case "fixed-step", value = "Fixed step";
    otherwise, value = "Explicit";
end
end

function value = formatterDisplay(value)
value = lower(string(value));
if any(value == ["auto", "source"]), value = "Auto";
elseif value == "fixed", value = "Fixed";
elseif value == "scientific", value = "Scientific";
elseif value == "engineering", value = "Engineering";
elseif value == "percent", value = "Percent";
else, value = "Explicit";
end
end

function panel = emptyPanel()
panel = struct("text", struct("title", "", "subtitle", "", ...
    "xLabel", "", "yLabel", "", "zLabel", ""), ...
    "axes", struct("x", emptyAxis(), "y", emptyAxis(), "z", emptyAxis()));
end

function value = emptyAxis()
value = struct("scale", "linear", "direction", "normal", ...
    "limits", [0 1], "location", "", ...
    "locator", struct("mode", "auto", "count", 5, "step", []), ...
    "formatter", struct("mode", "auto", "precision", [], ...
        "prefix", "", "suffix", ""), ...
    "ticks", struct("value", {}, "label", {}, "visible", {}, ...
        "level", {}, "rotation", {}, "fontOverride", {}));
end

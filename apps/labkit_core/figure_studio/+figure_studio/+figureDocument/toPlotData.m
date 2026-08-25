%TOPLOTDATA Materialize one panel as the existing portable renderer contract.
function plotData = toPlotData(document, panelId)
if isempty(document.panels)
    plotData = [];
    return;
end
if nargin < 2 || strlength(string(panelId)) == 0
    panelIndex = 1;
else
    panelIndex = find(string({document.panels.id}) == string(panelId), 1);
end
if isempty(panelIndex)
    error("figure_studio:figureDocument:UnknownPanel", ...
        "Unknown panel: %s", string(panelId));
end
panel = document.panels(panelIndex);
plotData = struct( ...
    "schema", "figure_studio.resultFiles.axesData.v1", ...
    "createdAt", datetime("now", "TimeZone", "local"), ...
    "axes", axesMetadata(panel), ...
    "objects", emptyObjects(), ...
    "warnings", document.warnings);
indices = find(string({document.nodes.panelId}) == panel.id & ...
    string({document.nodes.kind}) ~= "group");
for index = reshape(indices, 1, [])
    node = document.nodes(index);
    object = objectTemplate();
    object.type = node.kind;
    object.displayName = node.name;
    object.x = node.data.x;
    object.y = node.data.y;
    object.z = node.data.z;
    object.c = node.data.c;
    object.alpha = node.data.alpha;
    object.style = figure_studio.figureDocument.effectiveStyle( ...
        document, node.id);
    object.metadata = node.metadata;
    object.metadata.handleVisibility = onOff(node.legendVisible);
    object.metadata.visible = onOff(node.visible);
    plotData.objects(end + 1, 1) = object;
end
end

function meta = axesMetadata(panel)
meta = struct();
meta.title = panel.text.title;
meta.subtitle = panel.text.subtitle;
meta.xLabel = panel.text.xLabel;
meta.yLabel = panel.text.yLabel;
meta.zLabel = panel.text.zLabel;
for axisName = ["x", "y", "z"]
    axisValue = panel.axes.(char(axisName));
    meta.(char(axisName + "Scale")) = axisValue.scale;
    meta.(char(axisName + "Dir")) = axisValue.direction;
    meta.(char(axisName + "Lim")) = axisValue.limits;
    meta.(char(axisName + "Exponent")) = axisValue.exponent;
    visible = [axisValue.ticks.visible];
    ticks = axisValue.ticks(visible);
    meta.(char(axisName + "Tick")) = [ticks.value];
    meta.(char(axisName + "TickLabel")) = string({ticks.label});
    if isempty(ticks)
        rotation = 0;
    else
        rotations = [ticks.rotation];
        rotation = rotations(1);
    end
    meta.(char(axisName + "TickLabelRotation")) = rotation;
    if strlength(axisValue.location) > 0
        meta.(char(axisName + "AxisLocation")) = axisValue.location;
    end
end
if isfield(panel.axes, "yRight")
    meta.yAxes = [rulerMetadata(panel.axes.y, panel.text.yLabel, "left"); ...
        rulerMetadata(panel.axes.yRight, rightYLabel(panel), "right")];
end
meta.tickLabelInterpreter = "none";
meta.cLim = panel.color.limits;
meta.colormap = panel.color.colormap;
meta.colorbar = panel.color.bar;
meta.legend = panel.legend;
end

function value = rulerMetadata(axisValue, label, side)
visible = [axisValue.ticks.visible];
ticks = axisValue.ticks(visible);
value = struct("side", side, "scale", axisValue.scale, ...
    "direction", axisValue.direction, "limits", axisValue.limits, ...
    "tickValues", [ticks.value], "tickLabels", string({ticks.label}), ...
    "exponent", axisValue.exponent, "label", label, ...
    "color", fieldValue(axisValue, "color", []));
end

function value = rightYLabel(panel)
value = "";
if isfield(panel.text, "yRightLabel")
    value = panel.text.yRightLabel;
end
end

function value = fieldValue(owner, name, fallback)
name = char(name);
if isstruct(owner) && isfield(owner, name)
    value = owner.(name);
else
    value = fallback;
end
end

function objects = emptyObjects()
objects = objectTemplate();
objects(:) = [];
end

function object = objectTemplate()
object = struct("type", "", "displayName", "", ...
    "x", [], "y", [], "z", [], "c", [], "alpha", [], ...
    "style", struct(), "metadata", struct());
end

function value = onOff(tf)
if tf
    value = "on";
else
    value = "off";
end
end

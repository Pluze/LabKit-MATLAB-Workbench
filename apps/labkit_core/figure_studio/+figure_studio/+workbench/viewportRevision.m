% Expected caller: Figure Studio workbench presentation and direct tests.
% Source, panel, coordinate domain, and explicit refit actions own viewport
% fitting. Styling, labels, ticks, layers, and annotation edits preserve zoom.
function revision = viewportRevision( ...
        sources, activePanelId, plotData, explicitRevision)
sourceIds = strings(1, 0);
if ~isempty(sources)
    sourceIds = reshape(string({sources.id}), 1, []);
end
revision = string(jsonencode(struct( ...
    "sourceIds", {sourceIds}, ...
    "panelId", string(activePanelId), ...
    "domain", coordinateDomain(plotData), ...
    "explicitRevision", explicitRevision)));
end

function value = coordinateDomain(plotData)
value = struct("xScale", "", "xDir", "", "xLim", [], ...
    "yScale", "", "yDir", "", "yLim", [], ...
    "zScale", "", "zDir", "", "zLim", [], ...
    "yAxes", struct([]));
if isempty(plotData) || ~isstruct(plotData) || ~isfield(plotData, "axes")
    return
end
axesValue = plotData.axes;
for name = ["xScale", "xDir", "xLim", "yScale", "yDir", "yLim", ...
        "zScale", "zDir", "zLim"]
    if isfield(axesValue, name)
        value.(char(name)) = axesValue.(char(name));
    end
end
if isfield(axesValue, "yAxes")
    value.yAxes = coordinateRulers(axesValue.yAxes);
end
end

function values = coordinateRulers(rulers)
values = repmat(struct("side", "", "scale", "", ...
    "direction", "", "limits", []), size(rulers));
for index = 1:numel(rulers)
    for name = ["side", "scale", "direction", "limits"]
        if isfield(rulers, name)
            values(index).(char(name)) = rulers(index).(char(name));
        end
    end
end
end

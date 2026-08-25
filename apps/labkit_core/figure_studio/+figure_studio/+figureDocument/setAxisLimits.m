%SETAXISLIMITS Set finite limits and refresh non-explicit tick locators.
function document = setAxisLimits(document, panelId, axisName, limits)
limits = double(limits(:).');
if numel(limits) ~= 2 || any(~isfinite(limits)) || limits(1) >= limits(2)
    error("figure_studio:figureDocument:InvalidAxisLimits", ...
        "Axis limits must be two increasing finite values.");
end
panelIndex = find(string({document.panels.id}) == string(panelId), 1);
if isempty(panelIndex)
    error("figure_studio:figureDocument:UnknownPanel", ...
        "Unknown panel: %s", string(panelId));
end
axisName = lower(string(axisName));
if ~any(axisName == ["x", "y", "z"])
    error("figure_studio:figureDocument:UnknownAxis", ...
        "Axis name must be x, y, or z.");
end
axisValue = document.panels(panelIndex).axes.(char(axisName));
if lower(string(axisValue.scale)) == "log" && limits(1) <= 0
    error("figure_studio:figureDocument:InvalidLogLimits", ...
        "Logarithmic axis limits must be positive.");
end
axisValue.limits = limits;
if lower(string(axisValue.locator.mode)) == "source"
    axisValue.locator.mode = "auto";
    axisValue.formatter.mode = "auto";
end
if ~any(lower(string(axisValue.locator.mode)) == ["explicit", "category"])
    axisValue.ticks = figure_studio.figureDocument.planTicks(axisValue);
end
document.panels(panelIndex).axes.(char(axisName)) = axisValue;
document.revision = document.revision + 1;
end

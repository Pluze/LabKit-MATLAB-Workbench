function draw(axesById, model)
%DRAW Update time-series and force-versus-travel plots without rebuilding axes.
updateTimeSeries(axesById.timeSeries, model);
updateForceTravel(axesById.forceTravel, model);
end

function updateTimeSeries(ax, model)
travelLine = findobj(ax, "Type", "line", "Tag", "mark10TimeTravel");
forceLine = findobj(ax, "Type", "line", "Tag", "mark10TimeForce");
if isempty(travelLine) || isempty(forceLine)
    cla(ax);
    [travelTime, travelData] = ...
        visiblePointData(model.time_s, model.travel_mm);
    [forceTime, forceData] = ...
        visiblePointData(model.time_s, model.force_N);
    yyaxis(ax, "left");
    travelLine = line(ax, "XData", travelTime, "YData", travelData, ...
        "LineWidth", 1.2, "Color", [0, 0.4470, 0.7410], ...
        "Tag", "mark10TimeTravel", "DisplayName", "Travel", ...
        "HitTest", "off", "PickableParts", "none", "Clipping", "on");
    ylabel(ax, "Travel (mm)");
    yyaxis(ax, "right");
    forceLine = line(ax, "XData", forceTime, "YData", forceData, ...
        "LineWidth", 1.2, "Color", [0.8500, 0.3250, 0.0980], ...
        "Tag", "mark10TimeForce", "DisplayName", "Force", ...
        "HitTest", "off", "PickableParts", "none", "Clipping", "on");
    ylabel(ax, "Force (N)");
    xlabel(ax, "Time (s)");
    title(ax, "Travel and Force vs Time");
    grid(ax, "on");
    legend(ax, [travelLine, forceLine], ["Travel", "Force"], ...
        "Location", "best");
    configureNavigation(ax);
else
    set(travelLine, "XData", model.time_s, "YData", model.travel_mm);
    set(forceLine, "XData", model.time_s, "YData", model.force_N);
end
if requestsFit(ax, model)
    xlim(ax, model.limits.time_s);
    yyaxis(ax, "left");
    ylim(ax, model.limits.travel_mm);
    yyaxis(ax, "right");
    ylim(ax, model.limits.force_N);
    recordFit(ax, model);
end
end

function updateForceTravel(ax, model)
curve = findobj(ax, "Type", "line", "Tag", "mark10ForceTravel");
stationaryPoints = findobj(ax, "Type", "line", ...
    "Tag", "mark10ForceTravelStationaryPoints");
[travel, force, pointTravel, pointForce] = ...
    segmentedForceTravel(model.travel_mm, model.force_N);
if isempty(curve) || isempty(stationaryPoints)
    cla(ax);
    curve = plot(ax, travel, force, "LineWidth", 1.2, ...
        "Tag", "mark10ForceTravel", "HitTest", "off", ...
        "PickableParts", "none", "Clipping", "on");
    hold(ax, "on");
    [displayTravel, displayForce] = visiblePointData(pointTravel, pointForce);
    stationaryPoints = line(ax, "XData", displayTravel, ...
        "YData", displayForce, "Marker", ".", "MarkerSize", 5, ...
        "LineStyle", "none", "Color", [0, 0.4470, 0.7410], ...
        "Tag", "mark10ForceTravelStationaryPoints", ...
        "HitTest", "off", "PickableParts", "none", "Clipping", "on");
    hold(ax, "off");
    xlabel(ax, "Travel (mm)");
    ylabel(ax, "Force (N)");
    title(ax, "Force vs Travel");
    grid(ax, "on");
    configureNavigation(ax);
else
    set(curve, "XData", travel, "YData", force);
    [displayTravel, displayForce] = visiblePointData(pointTravel, pointForce);
    set(stationaryPoints, "XData", displayTravel, "YData", displayForce);
end
if requestsFit(ax, model)
    xlim(ax, model.limits.travel_mm);
    ylim(ax, model.limits.force_N);
    recordFit(ax, model);
end
end

function configureNavigation(ax)
% Keep traces clipped and expose MATLAB's standard axes navigation tools.
ax.Clipping = "on";
if isprop(ax, "ClippingStyle")
    ax.ClippingStyle = "rectangle";
end
if isprop(ax, "Interactions")
    ax.Interactions = [panInteraction, zoomInteraction, dataTipInteraction];
end
end

function [xLine, yLine, xPoints, yPoints] = segmentedForceTravel(x, y)
% UIAxes can extend exactly vertical line segments outside the plot box.
% Preserve both samples as points while disconnecting only equal-travel
% neighbors in the continuous trace. Measurement arrays remain unchanged.
x = x(:);
y = y(:);
breaks = isfinite(x(1:end-1)) & isfinite(x(2:end)) & ...
    isfinite(y(1:end-1)) & isfinite(y(2:end)) & ...
    x(1:end-1) == x(2:end) & y(1:end-1) ~= y(2:end);
breakIndices = find(breaks);
pointIndices = unique([breakIndices; breakIndices + 1]);
xPoints = x(pointIndices);
yPoints = y(pointIndices);
originalPositions = (1:numel(x)).' + [0; cumsum(breaks)];
xLine = nan(numel(x) + nnz(breaks), 1);
yLine = xLine;
xLine(originalPositions) = x;
yLine(originalPositions) = y;
end

function [x, y] = visiblePointData(x, y)
if isempty(x)
    x = NaN;
    y = NaN;
end
end

function tf = requestsFit(ax, model)
if ~isfield(model, "limitRevision")
    tf = isfield(model, "fitViewport") && logical(model.fitViewport);
    return;
end
tf = ~isappdata(ax, "mark10LimitRevision") || ...
    getappdata(ax, "mark10LimitRevision") ~= model.limitRevision;
end

function recordFit(ax, model)
if isfield(model, "limitRevision")
    setappdata(ax, "mark10LimitRevision", model.limitRevision);
end
end

function draw(axesById, model)
%DRAW Update time-series and force-versus-travel plots without rebuilding axes.
if ~isfield(model,"reconstructed_mm"), model.reconstructed_mm=nan(size(model.time_s)); end
if ~isfield(model,"travelLabel"), model.travelLabel="Travel (mm)"; end
updateTimeSeries(axesById.timeSeries, model);
updateForceTravel(axesById.forceTravel, model);
filename = "";
if isfield(model, "filename"), filename = model.filename; end
title(axesById.timeSeries, mark10_monitor.plotTitle( ...
    "Travel and Force vs Time", filename), Interpreter="none");
title(axesById.forceTravel, mark10_monitor.plotTitle( ...
    "Force vs Travel", filename), Interpreter="none");
end

function updateTimeSeries(ax, model)
travelLine = findobj(ax, "Type", "line", "Tag", "mark10TimeTravel");
forceLine = findobj(ax, "Type", "line", "Tag", "mark10TimeForce");
reconstructedLine = findobj(ax,"Type","line","Tag","mark10TimeReconstructed");
if isempty(travelLine) || isempty(forceLine) || isempty(reconstructedLine)
    cla(ax);
    [travelTime, travelData] = ...
        visiblePointData(model.time_s, model.travel_mm);
    [forceTime, forceData] = ...
        visiblePointData(model.time_s, model.force_N);
    [linearTime, linearTravel] = visiblePointData(model.time_s,model.reconstructed_mm);
    yyaxis(ax, "left");
    travelLine = line(ax, "XData", travelTime, "YData", travelData, ...
        "LineWidth", 1.2, "Color", [0, 0.4470, 0.7410], ...
        "Tag", "mark10TimeTravel", "DisplayName", "Travel", ...
        "HitTest", "off", "PickableParts", "none", "Clipping", "on");
    reconstructedLine = line(ax,"XData",linearTime,"YData",linearTravel, ...
        "LineWidth",1.6,"Color",[.10 .55 .32],"Tag","mark10TimeReconstructed", ...
        "HitTest","off","PickableParts","none","Clipping","on");
    yyaxis(ax, "right");
    forceLine = line(ax, "XData", forceTime, "YData", forceData, ...
        "LineWidth", 1.2, "Color", [0.8500, 0.3250, 0.0980], ...
        "Tag", "mark10TimeForce", "DisplayName", "Force", ...
        "HitTest", "off", "PickableParts", "none", "Clipping", "on");
    ylabel(ax, "Force (N)");
    xlabel(ax, "Time (s)");
    grid(ax, "on");
    legend(ax, [travelLine, reconstructedLine, forceLine], ["Measured travel", "Linear travel", "Force"], ...
        "Location", "northeast", "AutoUpdate", "off");
    configureNavigation(ax);
else
    set(travelLine, "XData", model.time_s, "YData", model.travel_mm);
    set(forceLine, "XData", model.time_s, "YData", model.force_N);
    set(reconstructedLine,"XData",model.time_s,"YData",model.reconstructed_mm);
end
if requestsFit(ax, model)
    xlim(ax, model.limits.time_s);
    yyaxis(ax, "left");
    ylim(ax, model.limits.travel_mm);
    yyaxis(ax, "right");
    ylim(ax, model.limits.force_N);
    recordFit(ax, model);
end
yyaxis(ax,"left");
ylabel(ax,model.travelLabel);
yyaxis(ax,"right");
end

function updateForceTravel(ax, model)
curve = findobj(ax, "Type", "line", "Tag", "mark10ForceTravel");
stationaryPoints = findobj(ax, "Type", "line", ...
    "Tag", "mark10ForceTravelStationaryPoints");
[travel, force, pointTravel, pointForce] = ...
    segmentedForceTravel(model.travel_mm, model.force_N);
reconstructedCurve = findobj(ax,"Type","line","Tag","mark10ForceReconstructed");
if isempty(curve) || isempty(stationaryPoints) || isempty(reconstructedCurve)
    cla(ax);
    [displayTravel, displayForce] = visiblePointData(travel,force);
    curve = plot(ax, displayTravel, displayForce, "LineWidth", 1.2, ...
        "Tag", "mark10ForceTravel", "HitTest", "off", ...
        "PickableParts", "none", "Clipping", "on");
    hold(ax, "on");
    [displayTravel, displayForce] = visiblePointData(pointTravel, pointForce);
    line(ax, "XData", displayTravel, ...
        "YData", displayForce, "Marker", ".", "MarkerSize", 5, ...
        "LineStyle", "none", "Color", [0, 0.4470, 0.7410], ...
        "Tag", "mark10ForceTravelStationaryPoints", ...
        "HitTest", "off", "PickableParts", "none", "Clipping", "on");
    [linearTravel, linearForce] = visiblePointData(model.reconstructed_mm,model.force_N);
    reconstructedCurve = line(ax,"XData",linearTravel,"YData",linearForce, ...
        "LineWidth",1.6,"Color",[.10 .55 .32],"Tag","mark10ForceReconstructed", ...
        "HitTest","off","PickableParts","none","Clipping","on");
    hold(ax, "off");
    legend(ax,[curve reconstructedCurve],["Measured travel","Linear travel"], ...
        "Location","northeast","AutoUpdate","off");
    ylabel(ax, "Force (N)");
    grid(ax, "on");
    configureNavigation(ax);
else
    set(curve, "XData", travel, "YData", force);
    set(reconstructedCurve,"XData",model.reconstructed_mm,"YData",model.force_N);
    [displayTravel, displayForce] = visiblePointData(pointTravel, pointForce);
    set(stationaryPoints, "XData", displayTravel, "YData", displayForce);
end
if requestsFit(ax, model)
    xlim(ax, model.limits.travel_mm);
    ylim(ax, model.limits.force_N);
    recordFit(ax, model);
end
xlabel(ax,model.travelLabel);
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

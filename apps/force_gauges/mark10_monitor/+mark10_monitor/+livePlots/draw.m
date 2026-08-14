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
    yyaxis(ax, "left");
    travelLine = plot(ax, NaN, NaN, "LineWidth", 1.2, ...
        "Tag", "mark10TimeTravel", "DisplayName", "Travel");
    ylabel(ax, "Travel (mm)");
    yyaxis(ax, "right");
    forceLine = plot(ax, NaN, NaN, "LineWidth", 1.2, ...
        "Tag", "mark10TimeForce", "DisplayName", "Force");
    ylabel(ax, "Force (N)");
    xlabel(ax, "Time (s)");
    title(ax, "Travel and Force vs Time");
    grid(ax, "on");
    legend(ax, [travelLine, forceLine], ["Travel", "Force"], ...
        "Location", "best");
end
set(travelLine, "XData", model.time_s, "YData", model.travel_mm);
set(forceLine, "XData", model.time_s, "YData", model.force_N);
end

function updateForceTravel(ax, model)
curve = findobj(ax, "Type", "line", "Tag", "mark10ForceTravel");
if isempty(curve)
    cla(ax);
    curve = plot(ax, NaN, NaN, "LineWidth", 1.2, ...
        "Tag", "mark10ForceTravel");
    xlabel(ax, "Travel (mm)");
    ylabel(ax, "Force (N)");
    title(ax, "Force vs Travel");
    grid(ax, "on");
end
set(curve, "XData", model.travel_mm, "YData", model.force_N);
end

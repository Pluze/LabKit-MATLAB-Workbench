function draw(axesById, model)
%DRAW Redraw bounded live force and travel snapshots.
drawSignal(axesById.force, model.time_s, model.force_N, "Force (N)");
drawSignal(axesById.travel, model.time_s, model.travel_mm, "Travel (mm)");
end

function drawSignal(ax, time, values, label)
cla(ax);
if isempty(time)
    title(ax, "Waiting for samples");
else
    plot(ax, time, values, "LineWidth", 1.2);
    title(ax, label);
end
xlabel(ax, "Time (s)");
ylabel(ax, label);
grid(ax, "on");
end

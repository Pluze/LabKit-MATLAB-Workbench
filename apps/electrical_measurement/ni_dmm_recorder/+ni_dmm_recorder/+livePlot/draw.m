function draw(axesById, model)
%DRAW Render the latest retained NI-DMM measurement window.
axesHandle = axesById.measurement;
cla(axesHandle);
if isempty(model.Time_s)
    text(axesHandle, 0.5, 0.5, "Start recording to view measurements.", ...
        "Units", "normalized", "HorizontalAlignment", "center");
    return;
end
plot(axesHandle, model.Time_s, model.Value, "LineWidth", 1.2);
xlabel(axesHandle, "Elapsed time (s)");
ylabel(axesHandle, "Measurement (" + model.Unit + ")");
grid(axesHandle, "on");
end

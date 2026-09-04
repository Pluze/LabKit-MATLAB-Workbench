function drawPowerSpectrum(axesById, model)
%DRAWPOWERSPECTRUM Render one cached ECG analysis-stage Welch PSD.
targetAxes = axesById.(model.axisId);
labkit.app.plot.clearAxes(targetAxes, ResetScale=true);
title(targetAxes, model.title, "Interpreter", "none");
xlabel(targetAxes, "Frequency (Hz)");
ylabel(targetAxes, model.yLabel, "Interpreter", "none");
grid(targetAxes, "on");
if ~model.ok
    return;
end
plot(targetAxes, model.frequency, model.powerDb, ...
    "Color", [0.122 0.467 0.706], "LineWidth", 1.25);
xlim(targetAxes, [0 model.frequency(end)]);
end

% Expected caller: ECG Print's Filter Details plot areas.
function drawFilterDetails(axesById, model)
if isfield(axesById, "magnitude")
    drawFrequencyAxes(axesById, model);
end
if isfield(axesById, "groupDelay")
    drawTimeAxes(axesById, model);
end
end

function drawFrequencyAxes(axesById, model)
magnitudeAxes = axesById.magnitude;
phaseAxes = axesById.phase;
prepareAxes(magnitudeAxes, "Magnitude response · FIR", ...
    "Frequency (Hz)", "Magnitude (dB)");
prepareAxes(phaseAxes, "Continuous phase response", ...
    "Frequency (Hz)", "Phase (rad)");
if ~model.ok
    return;
end
plotFrequencyResponses(magnitudeAxes, model, "magnitudeDb");
plotFrequencyResponses(phaseAxes, model, "phase");
ylim(magnitudeAxes, [-120 6]);
xlim(magnitudeAxes, [0 0.5 * model.sampleRate]);
xlim(phaseAxes, [0 0.5 * model.sampleRate]);
drawResponseKey(magnitudeAxes, model);
end

function drawTimeAxes(axesById, model)
delayAxes = axesById.groupDelay;
impulseAxes = axesById.impulse;
prepareAxes(delayAxes, "Group delay", ...
    "Frequency (Hz)", "Delay (samples)");
prepareAxes(impulseAxes, "Impulse response", ...
    "Time (s)", "Amplitude");
if ~model.ok
    return;
end
plotFrequencyResponses(delayAxes, model, "groupDelay");
plotImpulseResponses(impulseAxes, model);
xlim(delayAxes, [0 0.5 * model.sampleRate]);
end

function prepareAxes(targetAxes, plotTitle, xLabel, yLabel)
labkit.app.plot.clearAxes(targetAxes, ResetScale=true);
title(targetAxes, plotTitle);
xlabel(targetAxes, xLabel);
ylabel(targetAxes, yLabel);
grid(targetAxes, "on");
end

function plotFrequencyResponses(targetAxes, model, fieldName)
colors = lines(3);
plot(targetAxes, model.frequency, model.first.(fieldName), ...
    "Color", colors(1, :), "LineWidth", 1.5, ...
    "DisplayName", responseLabel( ...
    "Analysis", model.analysisBand, model.first.tapCount));
hold(targetAxes, "on");
if ~model.usesAnalysisBand
    plot(targetAxes, model.frequency, model.second.(fieldName), "--", ...
        "Color", colors(2, :), "LineWidth", 1.25, ...
        "DisplayName", responseLabel( ...
        "Peak detection", model.detectionBand, model.second.tapCount));
    plot(targetAxes, model.frequency, model.cascade.(fieldName), ":", ...
        "Color", colors(3, :), "LineWidth", 1.75, ...
        "DisplayName", sprintf("Cascade: %d taps", ...
        model.cascade.tapCount));
end
hold(targetAxes, "off");
end

function plotImpulseResponses(targetAxes, model)
colors = lines(3);
plot(targetAxes, model.first.impulseTime, model.first.impulse, ...
    "Color", colors(1, :), "LineWidth", 1.5, ...
    "DisplayName", responseLabel( ...
    "Analysis", model.analysisBand, model.first.tapCount));
hold(targetAxes, "on");
if ~model.usesAnalysisBand
    plot(targetAxes, model.second.impulseTime, model.second.impulse, "--", ...
        "Color", colors(2, :), "LineWidth", 1.25, ...
        "DisplayName", responseLabel( ...
        "Peak detection", model.detectionBand, model.second.tapCount));
    plot(targetAxes, model.cascade.impulseTime, model.cascade.impulse, ":", ...
        "Color", colors(3, :), "LineWidth", 1.75, ...
        "DisplayName", sprintf("Cascade: %d taps", ...
        model.cascade.tapCount));
end
hold(targetAxes, "off");
end

function label = responseLabel(name, band, tapCount)
label = sprintf("%s: %.6g-%.6g Hz · %d taps", ...
    name, band, tapCount);
end

function drawResponseKey(targetAxes, model)
labels = responseLabel("Analysis", ...
    model.analysisBand, model.first.tapCount);
if ~model.usesAnalysisBand
    labels = labels + newline + responseLabel("Peak detection", ...
        model.detectionBand, model.second.tapCount) + newline + ...
        sprintf("Cascade: %d taps", model.cascade.tapCount);
end
text(targetAxes, 0.98, 0.96, labels, "Units", "normalized", ...
    "HorizontalAlignment", "right", "VerticalAlignment", "top", ...
    "BackgroundColor", "white", "EdgeColor", [0.7 0.7 0.7], ...
    "Margin", 4, "FontSize", 9, "Interpreter", "none");
end

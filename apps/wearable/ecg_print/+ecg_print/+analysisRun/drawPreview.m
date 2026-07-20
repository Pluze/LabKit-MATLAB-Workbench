% Expected caller: App SDK registered renderer and waveform PNG export.
% Inputs are one axes and an app-owned axis model. Side effects are limited to
% redrawing that axes; no runtime controls or app state are read.
function drawPreview(axesById, model)
    if isgraphics(axesById, "axes")
        labkit.app.plot.clearAxes(axesById, ResetScale=true);
        drawOne(axesById, model);
        return;
    end
    axisIds = ["wave", "noise", "snr", "template"];
    for k = 1:numel(axisIds)
        ax = axesById.(axisIds(k));
        labkit.app.plot.clearAxes(ax, ResetScale=true);
        drawOne(ax, model(k));
    end
end

function drawOne(ax, model)
    switch string(model.kind)
        case "wave"
            drawWave(ax, model.request);
        case "noise"
            drawMetric(ax, model.analysis, model.smoothBeats, "noise");
        case "snr"
            drawMetric(ax, model.analysis, model.smoothBeats, "snr");
        case "template"
            drawTemplate(ax, model.request);
    end
    makeDisplayGraphicsNonPickable(ax);
end

function drawWave(ax, request)
    title(ax, request.title);
    xlabel(ax, request.xLabel);
    ylabel(ax, request.yLabel);
    if ~request.ok
        return;
    end
    plot(ax, request.x, request.y, "Color", request.lineColor, ...
        "LineWidth", 1);
    hold(ax, "on");
    if ~isempty(request.peakX)
        scatter(ax, request.peakX, request.peakY, 24, ...
            request.peakColor, "filled");
    end
    hold(ax, "off");
    grid(ax, "on");
end

function drawMetric(ax, analysis, smoothBeats, kind)
    if kind == "noise"
        title(ax, sprintf("Template Noise RMS Over Time | Smooth=%d beats", ...
            smoothBeats));
        ylabel(ax, "Noise RMS");
    else
        title(ax, sprintf("Template SNR Over Time | Smooth=%d beats", ...
            smoothBeats));
        ylabel(ax, "SNR (dB)");
    end
    xlabel(ax, "Time (s)");
    if height(analysis) == 0
        return;
    end
    if kind == "noise"
        raw = analysis.NoiseRMS;
        smooth = analysis.NoiseRMS_smooth;
        colors = [0.20 0.45 0.72; 0.05 0.20 0.45];
    else
        raw = analysis.SNRdB;
        smooth = analysis.SNRdB_smooth;
        colors = [0.18 0.55 0.32; 0.05 0.32 0.16];
    end
    plot(ax, analysis.EventTime, raw, ".", "MarkerSize", 12, ...
        "Color", colors(1, :));
    hold(ax, "on");
    plot(ax, analysis.EventTime, smooth, "-", "LineWidth", 1.5, ...
        "Color", colors(2, :));
    hold(ax, "off");
    grid(ax, "on");
end

function drawTemplate(ax, request)
    title(ax, request.title);
    xlabel(ax, request.xLabel);
    ylabel(ax, request.yLabel);
    if ~request.ok
        return;
    end
    hold(ax, "on");
    if request.showSegments
        plot(ax, request.timeOffset, request.segments(:, request.showIndex), ...
            "Color", [0.78 0.84 0.92], "LineWidth", 0.5);
    else
        fill(ax, [request.timeOffset; flipud(request.timeOffset)], ...
            [request.upper; flipud(request.lower)], [0.20 0.20 0.20], ...
            "FaceAlpha", 0.15, "EdgeColor", "none");
    end
    plot(ax, request.timeOffset, request.template, "k-", "LineWidth", 2);
    xline(ax, 0, "--r", "R");
    shadeWindows(ax, request);
    hold(ax, "off");
    grid(ax, "on");
end

function shadeWindows(ax, request)
    if isempty(request.signalWindowSec)
        return;
    end
    limits = ax.YLim;
    drawWindow(ax, request.signalWindowSec, limits, [1.00 0.20 0.20]);
    for k = 1:size(request.noiseWindowsSec, 1)
        drawWindow(ax, request.noiseWindowsSec(k, :), ...
            limits, [0.00 0.45 1.00]);
    end
end

function drawWindow(ax, windowSec, limits, color)
    fill(ax, [windowSec(1) windowSec(2) windowSec(2) windowSec(1)], ...
        [limits(1) limits(1) limits(2) limits(2)], color, ...
        "FaceAlpha", 0.08, "EdgeColor", "none", ...
        "HitTest", "off", "PickableParts", "none");
end

function makeDisplayGraphicsNonPickable(ax)
graphics = allchild(ax);
for k = 1:numel(graphics)
    if isprop(graphics(k), "HitTest")
        graphics(k).HitTest = "off";
    end
    if isprop(graphics(k), "PickableParts")
        graphics(k).PickableParts = "none";
    end
end
end

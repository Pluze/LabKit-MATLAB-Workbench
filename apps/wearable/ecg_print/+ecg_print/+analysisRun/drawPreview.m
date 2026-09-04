% Expected caller: App SDK registered renderer and waveform PNG export.
% Inputs are one axes and an app-owned axis model. Side effects are limited to
% redrawing that axes; no runtime controls or app state are read.
function drawPreview(axesById, model)
    if isgraphics(axesById, "axes")
        labkit.app.plot.clearAxes(axesById, ResetScale=true);
        drawOne(axesById, model);
        return;
    end
    currentIds = string(fieldnames(axesById));
    if isscalar(currentIds) && currentIds == "wave"
        timeAxes = findTimeAxes(axesById.(currentIds(1)));
        if hasAllTimeAxes(timeAxes)
            ecg_print.analysisRun.linkTimeAxes(timeAxes, "remove");
        end
    end
    for k = 1:numel(model)
        ax = axesById.(model(k).axisId);
        labkit.app.plot.clearAxes(ax, ResetScale=true);
        drawOne(ax, model(k));
    end
    if isscalar(currentIds) && currentIds == "snr"
        timeAxes = findTimeAxes(axesById.(currentIds(1)));
        if hasAllTimeAxes(timeAxes)
            ecg_print.analysisRun.linkTimeAxes(timeAxes, "install");
        end
    end
end

function drawOne(ax, model)
    switch string(model.kind)
        case "wave"
            drawWave(ax, model.request);
        case "noise"
            drawMetric(ax, model.analysis, model.smoothBeats, ...
                "noise", model.unit);
        case "peak"
            drawMetric(ax, model.analysis, model.smoothBeats, ...
                "peak", model.unit);
        case "snr"
            drawMetric(ax, model.analysis, model.smoothBeats, ...
                "snr", model.unit);
        case "template"
            drawTemplate(ax, model.request);
    end
    styleAxis(ax, model);
    makeDisplayGraphicsNonPickable(ax);
end

function drawWave(ax, request)
    title(ax, request.title, 'Interpreter', 'none');
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

function drawMetric(ax, analysis, smoothBeats, kind, unit)
    if kind == "noise"
        title(ax, sprintf("Noise RMS · %d-beat median", smoothBeats));
        ylabel(ax, "RMS (" + unit + ")");
    elseif kind == "peak"
        title(ax, sprintf("Peak-to-peak · %d-beat median", smoothBeats));
        ylabel(ax, "P-P (" + unit + ")");
    else
        title(ax, sprintf("SNR · %d-beat median", smoothBeats));
        ylabel(ax, "SNR (dB)");
    end
    if height(analysis) == 0
        return;
    end
    if kind == "noise"
        raw = analysis.NoiseRMS;
        smooth = analysis.NoiseRMS_smooth;
        colors = [0.20 0.45 0.72; 0.05 0.20 0.45];
    elseif kind == "peak"
        raw = analysis.SignalP2P;
        smooth = analysis.SignalP2P_smooth;
        colors = [0.72 0.42 0.16; 0.45 0.20 0.05];
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

function styleAxis(ax, model)
    ax.FontSize = 10;
    ax.Title.FontSize = 11;
    ax.Title.FontWeight = "normal";
    showXLabel = true;
    if isfield(model, "showXLabel")
        showXLabel = model.showXLabel;
    end
    if showXLabel
        if string(model.kind) == "template"
            xlabel(ax, model.request.xLabel);
        else
            xlabel(ax, "Time (s)");
        end
    else
        xlabel(ax, "");
        ax.XTickLabel = [];
    end
end

function axesById = findTimeAxes(seed)
    figureHandle = ancestor(seed, "figure");
    areaIds = ["waveAxes", "noiseAxes", "peakAxes", "snrAxes"];
    axisIds = ["wave", "noise", "peak", "snr"];
    axesById = struct();
    for k = 1:numel(axisIds)
        match = findall(figureHandle, "Tag", areaIds(k) + "." + axisIds(k));
        if isscalar(match) && isgraphics(match, "axes")
            axesById.(axisIds(k)) = match;
        end
    end
end

function tf = hasAllTimeAxes(axesById)
    tf = all(isfield(axesById, {'wave', 'noise', 'peak', 'snr'}));
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

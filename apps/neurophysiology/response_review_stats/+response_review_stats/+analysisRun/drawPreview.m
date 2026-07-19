% Expected caller: Runtime V2 registered renderer. Inputs are a UI axes handle
% and presentation model. Side effect is redrawing summary/aligned waveforms.
function drawPreview(axesById, S)
%DRAWSTATSPREVIEW Draw response-review metrics or aligned segments.

    ax = axesById.main;
    resetAxes(ax);
    mode = string(fieldOrDefault(S, "previewMode", "Summary"));
    aligned = fieldOrDefault(S, "aligned", []);

    if mode == "Aligned" && hasAlignedValues(aligned)
        drawAligned(ax, aligned);
        return;
    end
    drawSummary(ax, fieldOrDefault(S, "summary", table()), ...
        fieldOrDefault(S, "metrics", table()));
end

function drawAligned(ax, aligned)
    timeSec = double(aligned.timeSec(:));
    values = double(aligned.values);
    names = string(aligned.segmentNames(:));
    nTraces = size(values, 2);
    if nTraces == 0
        drawEmpty(ax, "No aligned segments");
        return;
    end

    colors = lines(max(nTraces, 1));
    hold(ax, "on");
    for k = 1:nTraces
        plot(ax, timeSec, values(:, k), "LineWidth", 1.0, ...
            "Color", colors(k, :), ...
            "DisplayName", char(labelFor(names, k)));
    end
    hold(ax, "off");
    xlabel(ax, "Time (s)");
    ylabel(ax, "Signal");
    title(ax, "Aligned Segments");
    if nTraces <= 8
        legend(ax, "Location", "northeastoutside", "Interpreter", "none");
    end
    styleWaveAxes(ax);
end

function drawSummary(ax, summary, metrics)
    if ~istable(summary) || height(summary) == 0 || ...
            (~istable(metrics) || height(metrics) == 0)
        drawEmpty(ax, "Choose an analysis JSON or segment CSV");
        title(ax, "Metric Summary");
        return;
    end

    values = double(summary.MeanPeakToPeak(:));
    if all(~isfinite(values))
        values = double(summary.Count(:));
        yLabel = "Segments";
    else
        yLabel = "Mean peak-to-peak";
    end
    values(~isfinite(values)) = 0;
    b = bar(ax, values, "FaceColor", [0.18 0.38 0.58], ...
        "EdgeColor", "none");
    if isprop(b, "BaseLine")
        b.BaseLine.LineStyle = "-";
    end
    ax.XTick = 1:height(summary);
    ax.XTickLabel = cellstr(string(summary.Group));
    ax.XTickLabelRotation = 20;
    ylabel(ax, yLabel);
    title(ax, "Metric Summary");
    styleBarAxes(ax);
end

function drawEmpty(ax, message)
    text(ax, 0.5, 0.5, string(message), ...
        "HorizontalAlignment", "center", ...
        "VerticalAlignment", "middle", ...
        "Color", [0.30 0.30 0.30]);
    xlim(ax, [0 1]);
    ylim(ax, [0 1]);
end

function tf = hasAlignedValues(aligned)
    tf = isstruct(aligned) && isfield(aligned, "values") && ...
        isfield(aligned, "timeSec") && ~isempty(aligned.values) && ...
        ~isempty(aligned.timeSec);
end

function label = labelFor(names, index)
    if index <= numel(names) && strlength(names(index)) > 0
        label = names(index);
    else
        label = "Segment " + index;
    end
end

function resetAxes(ax)
    delete(allchild(ax));
    cla(ax);
    ax.Color = "white";
    ax.Box = "off";
    ax.XGrid = "on";
    ax.YGrid = "on";
    ax.GridAlpha = 0.18;
end

function styleWaveAxes(ax)
    ax.Color = "white";
    ax.Box = "off";
    ax.XGrid = "on";
    ax.YGrid = "on";
    ax.GridAlpha = 0.18;
end

function styleBarAxes(ax)
    ax.Color = "white";
    ax.Box = "off";
    ax.YGrid = "on";
    ax.XGrid = "off";
    ax.GridAlpha = 0.18;
end

function value = fieldOrDefault(S, fieldName, defaultValue)
    value = defaultValue;
    if isstruct(S) && isfield(S, fieldName)
        value = S.(fieldName);
    end
end

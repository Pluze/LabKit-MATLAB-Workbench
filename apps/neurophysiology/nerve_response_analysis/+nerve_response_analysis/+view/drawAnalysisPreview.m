% Expected caller: nerve_response_analysis.run. Inputs are a UI axes handle
% and app state. Side effect is redrawing the axes with analysis counts.
function drawAnalysisPreview(ax, S)
%DRAWANALYSISPREVIEW Draw a compact nerve-response analysis preview.

    resetAxes(ax);
    analysis = fieldOrDefault(S, "analysis", struct());
    mode = string(fieldOrDefault(S, "previewMode", "Counts"));

    if ~isstruct(analysis) || ~isfield(analysis, "events")
        text(ax, 0.5, 0.5, "Choose a filter record, then analyze", ...
            "HorizontalAlignment", "center", ...
            "VerticalAlignment", "middle", ...
            "Color", [0.30 0.30 0.30]);
        xlim(ax, [0 1]);
        ylim(ax, [0 1]);
        title(ax, "Analysis Counts");
        return;
    end

    if mode == "Issues"
        drawIssuePreview(ax, fieldOrDefault(analysis, "issues", table()));
    else
        drawCountPreview(ax, analysis);
    end
end

function drawCountPreview(ax, analysis)
    counts = [
        tableHeight(fieldOrDefault(analysis, "events", table()))
        tableHeight(fieldOrDefault(analysis, "trains", table()))
        tableHeight(fieldOrDefault(analysis, "metrics", table()))
        tableHeight(fieldOrDefault(analysis, "issues", table()))];
    b = bar(ax, counts, "FaceColor", "flat", "EdgeColor", "none");
    b.CData = [0.18 0.36 0.58; 0.16 0.48 0.34; ...
        0.55 0.36 0.62; 0.72 0.26 0.18];
    ax.XTick = 1:4;
    ax.XTickLabel = {'Events', 'Trains', 'Metrics', 'Issues'};
    ylabel(ax, "Rows");
    title(ax, "Analysis Counts");
    styleAxes(ax);
end

function drawIssuePreview(ax, issues)
    if ~istable(issues) || height(issues) == 0
        text(ax, 0.5, 0.5, "No analysis issues", ...
            "HorizontalAlignment", "center", ...
            "VerticalAlignment", "middle", ...
            "Color", [0.22 0.42 0.28]);
        xlim(ax, [0 1]);
        ylim(ax, [0 1]);
        title(ax, "Analysis Issues");
        return;
    end

    if ismember("severity", issues.Properties.VariableNames)
        severity = string(issues.severity);
    else
        severity = repmat("issue", height(issues), 1);
    end
    labels = unique(severity, "stable");
    counts = zeros(numel(labels), 1);
    for k = 1:numel(labels)
        counts(k) = sum(severity == labels(k));
    end
    b = bar(ax, counts, "FaceColor", [0.72 0.26 0.18], ...
        "EdgeColor", "none");
    if isprop(b, "BaseLine")
        b.BaseLine.LineStyle = "-";
    end
    ax.XTick = 1:numel(labels);
    ax.XTickLabel = cellstr(labels);
    ylabel(ax, "Issues");
    title(ax, "Analysis Issues");
    styleAxes(ax);
end

function n = tableHeight(value)
    if istable(value)
        n = height(value);
    else
        n = 0;
    end
end

function resetAxes(ax)
    cla(ax);
    ax.Color = "white";
    ax.Box = "off";
    ax.XGrid = "on";
    ax.YGrid = "on";
    ax.GridAlpha = 0.18;
end

function styleAxes(ax)
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

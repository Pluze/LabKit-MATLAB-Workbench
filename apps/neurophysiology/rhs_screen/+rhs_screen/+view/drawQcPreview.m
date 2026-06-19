% Expected caller: rhs_screen.run. Inputs are a UI axes handle and app state.
% Side effect is redrawing the axes with a compact QC summary.
function drawQcPreview(ax, S)
%DRAWQCPREVIEW Draw a simple RHS screening QC preview.

    resetAxes(ax);
    mode = string(fieldOrDefault(S, "previewMode", "QC"));
    report = fieldOrDefault(S, "report", struct());

    if mode == "Groups" && hasGroups(S)
        drawGroups(ax, S.session.groups);
        return;
    end

    counts = [
        double(fieldOrDefault(report, "keptCount", ...
            fieldOrDefault(report, "acceptedCount", 0)))
        double(fieldOrDefault(report, "needsReviewCount", 0))
        double(fieldOrDefault(report, "failedCount", 0))];
    if sum(counts) == 0
        text(ax, 0.5, 0.5, "Choose an RHS folder to scan", ...
            "HorizontalAlignment", "center", ...
            "VerticalAlignment", "middle", ...
            "Color", [0.30 0.30 0.30]);
        xlim(ax, [0 1]);
        ylim(ax, [0 1]);
        title(ax, "RHS QC");
        return;
    end

    b = bar(ax, counts, "FaceColor", "flat", "EdgeColor", "none");
    b.CData = [0.15 0.45 0.30; 0.78 0.50 0.12; 0.70 0.18 0.16];
    ax.XTick = 1:3;
    ax.XTickLabel = {'Kept', 'Review', 'Failed'};
    ylabel(ax, "Recordings");
    title(ax, "RHS QC");
    styleAxes(ax);
end

function drawGroups(ax, groups)
    if height(groups) == 0
        text(ax, 0.5, 0.5, "No channel groups yet", ...
            "HorizontalAlignment", "center", ...
            "VerticalAlignment", "middle", ...
            "Color", [0.30 0.30 0.30]);
        xlim(ax, [0 1]);
        ylim(ax, [0 1]);
        title(ax, "RHS Groups");
        return;
    end
    counts = double(groups.recordingCount(:));
    b = bar(ax, counts, "FaceColor", [0.18 0.38 0.58], ...
        "EdgeColor", "none");
    if isprop(b, "BaseLine")
        b.BaseLine.LineStyle = "-";
    end
    ax.XTick = 1:numel(counts);
    ax.XTickLabel = compactLabels(groups.channelSignature);
    ax.XTickLabelRotation = 25;
    ylabel(ax, "Recordings");
    title(ax, "Channel Signature Groups");
    styleAxes(ax);
end

function labels = compactLabels(values)
    values = string(values(:));
    labels = cellstr(values);
    for k = 1:numel(labels)
        if strlength(values(k)) > 24
            labels{k} = char(extractBefore(values(k), 22) + "...");
        end
    end
end

function tf = hasGroups(S)
    tf = isstruct(S) && isfield(S, "session") && isstruct(S.session) && ...
        isfield(S.session, "groups") && istable(S.session.groups);
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

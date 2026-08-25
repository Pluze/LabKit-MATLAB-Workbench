%APPLYSTYLEDTICKS Render per-tick typography unsupported by MATLAB rulers.
function applyStyledTicks(document, panelId, ax)
delete(findall(ax, "Type", "text", "Tag", "figureStudioStyledTick"));
panelIndex = find(string({document.panels.id}) == string(panelId), 1);
if isempty(panelIndex), panelIndex = 1; end
panel = document.panels(panelIndex);
applyAxis(ax, panel.axes.x, "x", "left");
applyAxis(ax, panel.axes.y, "y", "left");
if isfield(panel.axes, "yRight")
    applyAxis(ax, panel.axes.yRight, "y", "right");
    yyaxis(ax, "left");
end
end

function applyAxis(ax, axisValue, dimension, side)
rows = axisValue.ticks([axisValue.ticks.visible]);
if isempty(rows), return; end
custom = false(size(rows));
for k = 1:numel(rows)
    custom(k) = ~isempty(fieldnames(rows(k).fontOverride)) || ...
        rows(k).rotation ~= rows(1).rotation || rows(k).level == "minor";
end
labels = string({rows.label});
labels(custom) = "";
if dimension == "x"
    ax.XTick = [rows.value];
    ax.XTickLabel = labels;
else
    if numel(ax.YAxis) > 1 || side == "right", yyaxis(ax, char(side)); end
    ax.YTick = [rows.value];
    ax.YTickLabel = labels;
end
for index = reshape(find(custom), 1, [])
    position = normalizedPosition(rows(index).value, axisValue);
    if dimension == "x"
        x = position;
        if axisValue.location == "top", y = 1.035; vertical = "bottom";
        else, y = -0.035; vertical = "top"; end
        horizontal = "center";
    else
        y = position;
        if side == "right", x = 1.025; horizontal = "left";
        else, x = -0.025; horizontal = "right"; end
        vertical = "middle";
    end
    handle = text(ax, x, y, rows(index).label, Units="normalized", ...
        Interpreter="none", HorizontalAlignment=horizontal, ...
        VerticalAlignment=vertical, Rotation=rows(index).rotation, ...
        FontName=ax.FontName, FontSize=ax.FontSize, Clipping="off", ...
        HitTest="off", PickableParts="none", HandleVisibility="off", ...
        Tag="figureStudioStyledTick");
    for name = string(fieldnames(rows(index).fontOverride)).'
        try
            handle.(char(name)) = rows(index).fontOverride.(char(name));
        catch
        end
    end
end
end

function position = normalizedPosition(value, axisValue)
limits = double(axisValue.limits);
value = double(value);
if axisValue.scale == "log"
    limits = log10(limits);
    value = log10(value);
end
position = (value - limits(1)) / diff(limits);
if axisValue.direction == "reverse", position = 1 - position; end
end

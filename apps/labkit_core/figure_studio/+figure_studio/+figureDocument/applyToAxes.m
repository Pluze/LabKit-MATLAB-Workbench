%APPLYTOAXES Apply semantic edits to a native or portable rendered axes.
% The caller first applies the selected base preset. This function then applies
% category and object overrides, visibility, labels, limits, and explicit ticks.
function applyToAxes(document, panelId, ax)
if isempty(document) || isempty(document.panels) || ...
        ~isgraphics(ax, "axes")
    return;
end
panelIndex = find(string({document.panels.id}) == string(panelId), 1);
if isempty(panelIndex)
    panelIndex = 1;
end
panel = document.panels(panelIndex);
applyPanel(panel, ax);
[nodes, graphics] = figure_studio.figureDocument.nodeGraphics(document, panel.id, ax);
for k = 1:numel(nodes)
    if isgraphics(graphics(k)), applyNode(document, nodes(k), graphics(k)); end
end
figure_studio.figureDocument.applyStyledTicks(document, panel.id, ax);
end

function applyPanel(panel, ax)
title(ax, panel.text.title, Interpreter="none");
if isprop(ax, "Subtitle")
    ax.Subtitle.String = panel.text.subtitle;
    ax.Subtitle.Interpreter = "none";
end
xlabel(ax, panel.text.xLabel, Interpreter="none");
if isfield(panel.axes, "yRight")
    yyaxis(ax, "left");
end
ylabel(ax, panel.text.yLabel, Interpreter="none");
zlabel(ax, panel.text.zLabel, Interpreter="none");
for axisName = ["x", "y", "z"]
    axisValue = panel.axes.(char(axisName));
    prefix = upper(axisName);
    safeSet(ax, prefix + "Scale", axisValue.scale);
    safeSet(ax, prefix + "Dir", axisValue.direction);
    safeSet(ax, prefix + "Lim", axisValue.limits);
    visible = [axisValue.ticks.visible];
    rows = axisValue.ticks(visible);
    safeSet(ax, prefix + "Tick", [rows.value]);
    safeSet(ax, prefix + "TickLabel", string({rows.label}));
    if ~isempty(rows)
        safeSet(ax, prefix + "TickLabelRotation", rows(1).rotation);
    end
    if strlength(axisValue.location) > 0
        safeSet(ax, prefix + "AxisLocation", axisValue.location);
    end
end
if isfield(panel.axes, "yRight")
    yyaxis(ax, "right");
    applyYAxis(panel.axes.yRight, ax);
    if isfield(panel.text, "yRightLabel")
        ylabel(ax, panel.text.yRightLabel, Interpreter="none");
    end
    yyaxis(ax, "left");
    applyYAxis(panel.axes.y, ax);
end
safeSet(ax, "CLim", panel.color.limits);
if ~isempty(panel.color.colormap)
    colormap(ax, panel.color.colormap);
end
applyColorbar(panel.color.bar, ax);
end

function applyColorbar(meta, ax)
if ~logical(meta.enabled)
    try
        if ~isempty(ax.Colorbar), delete(ax.Colorbar); end
    catch
    end
    return;
end
bar = colorbar(ax, char(meta.location));
bar.Label.String = meta.label;
bar.Label.Interpreter = "none";
safeSet(bar, "Limits", meta.limits);
safeSet(bar, "Ticks", meta.ticks);
safeSet(bar, "TickLabels", meta.tickLabels);
safeSet(bar, "FontName", meta.fontName);
safeSet(bar, "FontSize", meta.fontSize);
end

function applyYAxis(axisValue, ax)
safeSet(ax, "YScale", axisValue.scale);
safeSet(ax, "YDir", axisValue.direction);
safeSet(ax, "YLim", axisValue.limits);
visible = [axisValue.ticks.visible];
rows = axisValue.ticks(visible);
safeSet(ax, "YTick", [rows.value]);
safeSet(ax, "YTickLabel", string({rows.label}));
if ~isempty(rows)
    safeSet(ax, "YTickLabelRotation", rows(1).rotation);
end
if isfield(axisValue, "color") && ~isempty(axisValue.color)
    try
        ax.YAxis(end).Color = axisValue.color;
    catch
    end
end
end

function applyNode(document, node, handle)
safeSet(handle, "Visible", onOff(node.visible));
safeSet(handle, "HandleVisibility", onOff(node.legendVisible));
properties = resolvedOverrides(document, node);
for name = string(fieldnames(properties)).'
    safeSet(handle, name, properties.(char(name)));
end
if node.kind == "text" && isfield(node.metadata, "text")
    safeSet(handle, "String", node.metadata.text);
end
end

function properties = resolvedOverrides(document, node)
properties = struct();
scopes = ["document", "kind", "role", "group", "object"];
targets = ["*", node.kind, node.role, node.groupId, node.id];
for level = 1:numel(scopes)
    if strlength(targets(level)) == 0
        continue;
    end
    matches = string({document.styleRules.scope}) == scopes(level) & ...
        string({document.styleRules.target}) == targets(level);
    for index = reshape(find(matches), 1, [])
        properties = merge(properties, ...
            document.styleRules(index).properties);
    end
end
properties = merge(properties, node.overrides);
end

function destination = merge(destination, source)
for name = string(fieldnames(source)).'
    destination.(char(name)) = source.(char(name));
end
end

function safeSet(handle, property, value)
property = char(property);
try
    if isprop(handle, property)
        handle.(property) = value;
    end
catch
end
end

function value = onOff(tf)
if tf
    value = "on";
else
    value = "off";
end
end

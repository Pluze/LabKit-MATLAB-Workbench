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
nodes = document.nodes(string({document.nodes.panelId}) == panel.id & ...
    string({document.nodes.kind}) ~= "group");
graphics = supportedGraphics(ax);
nodeIndex = 1;
for graphicsIndex = 1:numel(graphics)
    handle = graphics(graphicsIndex);
    if nodeIndex > numel(nodes)
        break;
    end
    node = nodes(nodeIndex);
    if ~matchesNode(handle, node)
        continue;
    end
    applyNode(document, node, handle);
    nodeIndex = nodeIndex + 1;
end
end

function applyPanel(panel, ax)
title(ax, panel.text.title, Interpreter="none");
if isprop(ax, "Subtitle")
    ax.Subtitle.String = panel.text.subtitle;
    ax.Subtitle.Interpreter = "none";
end
xlabel(ax, panel.text.xLabel, Interpreter="none");
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
safeSet(ax, "CLim", panel.color.limits);
if ~isempty(panel.color.colormap)
    colormap(ax, panel.color.colormap);
end
end

function graphics = supportedGraphics(ax)
children = flipud(allchild(ax));
for property = ["Title", "Subtitle", "XLabel", "YLabel", "ZLabel"]
    if isprop(ax, property)
        children(children == ax.(char(property))) = [];
    end
end
children = expandGroups(children);
supported = false(size(children));
for k = 1:numel(children)
    supported(k) = any(graphicsKind(children(k)) == [ ...
        "line", "bar", "errorbar", "area", "scatter", "image", ...
        "surface", "patch", "text", "constantline", "rectangle", ...
        "boxchart"]);
end
graphics = children(supported);
end

function children = expandGroups(children)
chunks = cell(numel(children), 1);
for k = 1:numel(children)
    if isgraphics(children(k), "hggroup")
        chunks{k} = expandGroups(flipud(allchild(children(k))));
    else
        chunks{k} = children(k);
    end
end
if isempty(chunks)
    children = gobjects(0, 1);
else
    children = vertcat(chunks{:});
end
end

function tf = matchesNode(handle, node)
tf = graphicsKind(handle) == node.kind;
end

function kind = graphicsKind(handle)
kind = lower(string(handle.Type));
className = lower(string(class(handle)));
if contains(className, "boxchart")
    kind = "boxchart";
elseif contains(className, "constantline")
    kind = "constantline";
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

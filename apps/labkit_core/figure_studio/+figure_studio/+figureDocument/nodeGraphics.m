function [nodes, handles] = nodeGraphics(document, panelId, ax)
%NODEGRAPHICS Match document primitives to their rendered counterparts.
% Called by semantic overrides and legend rendering after source copy/render.
% Handles align with nodes; an unsupported or missing primitive has no handle.
nodes = document.nodes(string({document.nodes.panelId}) == panelId & ...
    string({document.nodes.kind}) ~= "group");
handles = gobjects(numel(nodes), 1);
graphics = supportedGraphics(ax);
nodeIndex = 1;
for k = 1:numel(graphics)
    if nodeIndex > numel(nodes), break; end
    if ~matchesNode(graphics(k), nodes(nodeIndex)), continue; end
    handles(nodeIndex) = graphics(k);
    nodeIndex = nodeIndex + 1;
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

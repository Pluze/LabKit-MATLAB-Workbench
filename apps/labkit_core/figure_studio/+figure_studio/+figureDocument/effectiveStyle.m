%EFFECTIVESTYLE Resolve source, document, kind, role, group, and object styles.
function [style, sources] = effectiveStyle(document, nodeId)
index = find(string({document.nodes.id}) == string(nodeId), 1);
if isempty(index)
    error("figure_studio:figureDocument:UnknownNode", ...
        "Unknown figure node: %s", string(nodeId));
end
node = document.nodes(index);
style = node.sourceStyle;
sources = sourceMap(style, "source");
scopes = ["document", "kind", "role", "group", "object"];
targets = ["*", node.kind, node.role, node.groupId, node.id];
for level = 1:numel(scopes)
    if strlength(targets(level)) == 0
        continue;
    end
    matches = string({document.styleRules.scope}) == scopes(level) & ...
        string({document.styleRules.target}) == targets(level);
    ruleIndices = find(matches);
    for ruleIndex = reshape(ruleIndices, 1, [])
        [style, sources] = mergeProperties(style, sources, ...
            document.styleRules(ruleIndex).properties, ...
            scopes(level) + ":" + targets(level));
    end
end
[style, sources] = mergeProperties(style, sources, node.overrides, ...
    "override:" + node.id);
end

function sources = sourceMap(style, source)
sources = struct();
for name = string(fieldnames(style)).'
    sources.(char(name)) = source;
end
end

function [style, sources] = mergeProperties(style, sources, properties, source)
if ~isstruct(properties) || ~isscalar(properties)
    return;
end
for name = string(fieldnames(properties)).'
    style.(char(name)) = properties.(char(name));
    sources.(char(name)) = source;
end
end

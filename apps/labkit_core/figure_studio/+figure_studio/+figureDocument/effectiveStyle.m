%EFFECTIVESTYLE Resolve source, document, kind, role, group, and object styles.
function style = effectiveStyle(document, nodeId)
index = find(string({document.nodes.id}) == string(nodeId), 1);
if isempty(index)
    error("figure_studio:figureDocument:UnknownNode", ...
        "Unknown figure node: %s", string(nodeId));
end
node = document.nodes(index);
style = node.sourceStyle;
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
        style = mergeProperties(style, document.styleRules(ruleIndex).properties);
    end
end
style = mergeProperties(style, node.overrides);
end

function style = mergeProperties(style, properties)
if ~isstruct(properties) || ~isscalar(properties)
    return;
end
for name = string(fieldnames(properties)).'
    style.(char(name)) = properties.(char(name));
end
end

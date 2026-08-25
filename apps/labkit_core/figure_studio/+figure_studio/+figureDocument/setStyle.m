%SETSTYLE Set a category, group, or object presentation property.
function document = setStyle(document, scope, target, property, value)
scope = lower(string(scope));
target = string(target);
property = string(property);
if ~any(scope == ["document", "kind", "role", "group", "object"])
    error("figure_studio:figureDocument:UnknownStyleScope", ...
        "Unknown style scope: %s", scope);
end
if ~isvarname(char(property))
    error("figure_studio:figureDocument:InvalidStyleProperty", ...
        "Style property must be a valid MATLAB field name.");
end
if scope == "object"
    index = find(string({document.nodes.id}) == target, 1);
    if isempty(index)
        error("figure_studio:figureDocument:UnknownNode", ...
            "Unknown figure node: %s", target);
    end
    document.nodes(index).overrides.(char(property)) = value;
else
    matches = string({document.styleRules.scope}) == scope & ...
        string({document.styleRules.target}) == target;
    index = find(matches, 1, "last");
    if isempty(index)
        rule = struct("id", scope + "-" + string(numel(document.styleRules) + 1), ...
            "scope", scope, "target", target, "properties", struct());
        document.styleRules(end + 1, 1) = rule;
        index = numel(document.styleRules);
    end
    document.styleRules(index).properties.(char(property)) = value;
end
document.revision = document.revision + 1;
end

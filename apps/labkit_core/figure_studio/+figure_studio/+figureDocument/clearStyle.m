%CLEARSTYLE Remove one inherited rule or object override property.
function document = clearStyle(document, scope, target, property)
scope = lower(string(scope));
target = string(target);
property = char(string(property));
if scope == "object"
    index = find(string({document.nodes.id}) == target, 1);
    if isempty(index)
        error("figure_studio:figureDocument:UnknownNode", ...
            "Unknown figure node: %s", target);
    end
    if isfield(document.nodes(index).overrides, property)
        document.nodes(index).overrides = rmfield( ...
            document.nodes(index).overrides, property);
    end
else
    matches = string({document.styleRules.scope}) == scope & ...
        string({document.styleRules.target}) == target;
    for index = reshape(find(matches), 1, [])
        if isfield(document.styleRules(index).properties, property)
            document.styleRules(index).properties = rmfield( ...
                document.styleRules(index).properties, property);
        end
    end
end
document.revision = document.revision + 1;
end

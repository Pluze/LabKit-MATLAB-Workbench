%PROPERTYSTATE Return uniform or mixed effective values for selected nodes.
function state = propertyState(document, nodeIds, property)
nodeIds = string(nodeIds(:));
property = char(string(property));
if isempty(nodeIds)
    state = struct("kind", "empty", "value", [], "sources", strings(0, 1));
    return;
end
values = cell(numel(nodeIds), 1);
sources = strings(numel(nodeIds), 1);
present = false(numel(nodeIds), 1);
for k = 1:numel(nodeIds)
    [style, sourceMap] = figure_studio.figureDocument.effectiveStyle( ...
        document, nodeIds(k));
    if isfield(style, property)
        values{k} = style.(property);
        present(k) = true;
        if isfield(sourceMap, property)
            sources(k) = string(sourceMap.(property));
        end
    end
end
if ~all(present)
    state = struct("kind", "mixed", "value", [], "sources", sources);
    return;
end
first = values{1};
uniform = all(cellfun(@(value) isequaln(value, first), values));
if uniform
    kind = "uniform";
    value = first;
else
    kind = "mixed";
    value = [];
end
state = struct("kind", kind, "value", value, "sources", sources);
end

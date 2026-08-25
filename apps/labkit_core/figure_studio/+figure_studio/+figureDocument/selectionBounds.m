%SELECTIONBOUNDS Return [x y width height] for editable selected descendants.
function [bounds, available] = selectionBounds(document, ids)
ids = string(ids(:));
changed = true;
while changed
    children = string({document.nodes.parentId}).';
    expanded = unique([ids; string({document.nodes( ...
        ismember(children, ids)).id}).'], 'stable');
    changed = numel(expanded) > numel(ids);
    ids = expanded;
end
indices = find(ismember(string({document.nodes.id}), ids));
indices = indices(string({document.nodes(indices).kind}) ~= "group" & ...
    ~[document.nodes(indices).dataLocked]);
available = ~isempty(indices);
if ~available
    bounds = [0 0 1 1];
    return;
end
values = zeros(numel(indices), 4);
for k = 1:numel(indices)
    values(k, :) = nodeBounds(document.nodes(indices(k)));
end
left = min(values(:, 1));
bottom = min(values(:, 2));
right = max(values(:, 3));
top = max(values(:, 4));
bounds = [left bottom max(right-left, eps) max(top-bottom, eps)];
end

function bounds = nodeBounds(node)
if node.kind == "rectangle" && isfield(node.metadata, "position")
    p = double(node.metadata.position);
    bounds = [p(1) p(2) p(1)+p(3) p(2)+p(4)];
elseif node.kind == "text"
    p = double(node.data.x(:).');
    if numel(p) < 2, p = [0 0]; end
    bounds = [p(1) p(2) p(1) p(2)];
else
    x = double(node.data.x(:));
    y = double(node.data.y(:));
    if isempty(x), x = 0; end
    if isempty(y), y = 0; end
    bounds = [min(x, [], 'omitnan') min(y, [], 'omitnan') ...
        max(x, [], 'omitnan') max(y, [], 'omitnan')];
    bounds(~isfinite(bounds)) = 0;
end
end

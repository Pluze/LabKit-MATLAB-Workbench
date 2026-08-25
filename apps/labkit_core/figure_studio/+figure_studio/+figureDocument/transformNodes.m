%TRANSFORMNODES Move, scale, align, or distribute editable annotation nodes.
function document = transformNodes(document, ids, operation, parameters)
ids = editableDescendants(document, string(ids(:)));
if isempty(ids), return; end
indices = find(ismember(string({document.nodes.id}), ids));
operation = lower(string(operation));
boundCells = arrayfun(@(index) nodeBounds(document.nodes(index)), ...
    indices, UniformOutput=false);
bounds = vertcat(boundCells{:});
switch operation
    case "translate"
        delta = [double(parameters.dx), double(parameters.dy)];
        for index = reshape(indices, 1, [])
            document.nodes(index) = moveNode(document.nodes(index), delta);
        end
    case "scale"
        anchor = [mean([min(bounds(:, 1)) max(bounds(:, 3))]), ...
            mean([min(bounds(:, 2)) max(bounds(:, 4))])];
        factors = [double(parameters.sx), double(parameters.sy)];
        for index = reshape(indices, 1, [])
            document.nodes(index) = scaleNode(document.nodes(index), anchor, factors);
        end
    case {"align left", "align center", "align right", ...
            "align bottom", "align middle", "align top"}
        for k = 1:numel(indices)
            delta = alignmentDelta(bounds(k, :), bounds, operation);
            document.nodes(indices(k)) = moveNode(document.nodes(indices(k)), delta);
        end
    case {"distribute horizontally", "distribute vertically"}
        document = distributeNodes(document, indices, bounds, operation);
    otherwise
        error("figure_studio:figureDocument:UnknownTransform", ...
            "Unknown object transform: %s", operation);
end
end

function ids = editableDescendants(document, ids)
changed = true;
while changed
    children = string({document.nodes.parentId}).';
    newIds = string({document.nodes(ismember(children, ids)).id}).';
    combined = unique([ids; newIds], 'stable');
    changed = numel(combined) > numel(ids);
    ids = combined;
end
[found, indices] = ismember(ids, string({document.nodes.id}));
indices = indices(found);
ids = ids(found);
kinds = string({document.nodes(indices).kind}).';
locked = [document.nodes(indices).dataLocked].';
keep = kinds ~= "group" & ~locked;
ids = ids(keep);
end

function bounds = nodeBounds(node)
if node.kind == "rectangle" && isfield(node.metadata, "position")
    p = double(node.metadata.position);
    bounds = [p(1) p(2) p(1)+p(3) p(2)+p(4)];
    return;
end
if node.kind == "text"
    p = double(node.data.x(:).');
    if numel(p) < 2, p = [0 0]; end
    bounds = [p(1) p(2) p(1) p(2)];
    return;
end
x = double(node.data.x(:));
y = double(node.data.y(:));
if isempty(x), x = 0; end
if isempty(y), y = 0; end
bounds = [min(x, [], 'omitnan') min(y, [], 'omitnan') ...
    max(x, [], 'omitnan') max(y, [], 'omitnan')];
bounds(~isfinite(bounds)) = 0;
end

function node = moveNode(node, delta)
if node.kind == "rectangle" && isfield(node.metadata, "position")
    node.metadata.position(1:2) = node.metadata.position(1:2) + delta;
elseif node.kind == "text"
    node.data.x(1:2) = node.data.x(1:2) + delta;
elseif node.kind == "constantline" && isfield(node.metadata, "value")
    if lower(string(node.metadata.interceptAxis)) == "y"
        node.metadata.value = node.metadata.value + delta(2);
    else
        node.metadata.value = node.metadata.value + delta(1);
    end
else
    if ~isempty(node.data.x), node.data.x = node.data.x + delta(1); end
    if ~isempty(node.data.y), node.data.y = node.data.y + delta(2); end
end
end

function node = scaleNode(node, anchor, factors)
if node.kind == "rectangle" && isfield(node.metadata, "position")
    p = node.metadata.position;
    p(1:2) = anchor + (p(1:2) - anchor) .* factors;
    p(3:4) = p(3:4) .* factors;
    node.metadata.position = p;
elseif node.kind == "text"
    node.data.x(1:2) = anchor + (node.data.x(1:2) - anchor) .* factors;
else
    if ~isempty(node.data.x)
        node.data.x = anchor(1) + (node.data.x - anchor(1)) .* factors(1);
    end
    if ~isempty(node.data.y)
        node.data.y = anchor(2) + (node.data.y - anchor(2)) .* factors(2);
    end
end
end

function delta = alignmentDelta(bounds, allBounds, operation)
switch operation
    case "align left", delta = [min(allBounds(:, 1)) - bounds(1), 0];
    case "align center"
        target = mean([min(allBounds(:, 1)) max(allBounds(:, 3))]);
        delta = [target - mean(bounds([1 3])), 0];
    case "align right", delta = [max(allBounds(:, 3)) - bounds(3), 0];
    case "align bottom", delta = [0, min(allBounds(:, 2)) - bounds(2)];
    case "align middle"
        target = mean([min(allBounds(:, 2)) max(allBounds(:, 4))]);
        delta = [0, target - mean(bounds([2 4]))];
    case "align top", delta = [0, max(allBounds(:, 4)) - bounds(4)];
end
end

function document = distributeNodes(document, indices, bounds, operation)
if numel(indices) < 3, return; end
if operation == "distribute horizontally", dimension = 1; else, dimension = 2; end
centers = mean(bounds(:, [dimension dimension+2]), 2);
[~, order] = sort(centers);
targets = linspace(centers(order(1)), centers(order(end)), numel(indices));
for k = 1:numel(order)
    delta = [0 0];
    delta(dimension) = targets(k) - centers(order(k));
    index = indices(order(k));
    document.nodes(index) = moveNode(document.nodes(index), delta);
end
end

%PANELOPERATION Apply deterministic multi-panel layout operations.
function document = panelOperation(document, panelIds, operation)
panelIds = string(panelIds(:));
indices = find(ismember(string({document.panels.id}), panelIds));
operation = lower(string(operation));
if operation == "auto grid"
    indices = 1:numel(document.panels);
    geometries = gridGeometry(numel(indices));
    for k = 1:numel(indices)
        document.panels(indices(k)).geometry = geometries(k, :);
    end
    return;
end
if isempty(indices), return; end
geometry = vertcat(document.panels(indices).geometry);
switch operation
    case "align left"
        geometry(:, 1) = min(geometry(:, 1));
    case "align right"
        edge = max(geometry(:, 1) + geometry(:, 3));
        geometry(:, 1) = edge - geometry(:, 3);
    case "align top"
        edge = max(geometry(:, 2) + geometry(:, 4));
        geometry(:, 2) = edge - geometry(:, 4);
    case "align bottom"
        geometry(:, 2) = min(geometry(:, 2));
    case "equal width"
        geometry(:, 3) = mean(geometry(:, 3));
    case "equal height"
        geometry(:, 4) = mean(geometry(:, 4));
    case "distribute horizontally"
        geometry = distribute(geometry, 1, 3);
    case "distribute vertically"
        geometry = distribute(geometry, 2, 4);
    otherwise
        error("figure_studio:figureDocument:UnknownPanelOperation", ...
            "Unknown panel operation: %s", operation);
end
for k = 1:numel(indices)
    document.panels(indices(k)).geometry = clampGeometry(geometry(k, :));
end
end

function geometry = distribute(geometry, positionColumn, sizeColumn)
if size(geometry, 1) < 3, return; end
[~, order] = sort(geometry(:, positionColumn));
first = geometry(order(1), positionColumn);
last = geometry(order(end), positionColumn) + ...
    geometry(order(end), sizeColumn);
gap = (last - first - sum(geometry(:, sizeColumn))) / (size(geometry, 1) - 1);
cursor = first;
for k = 1:numel(order)
    index = order(k);
    geometry(index, positionColumn) = cursor;
    cursor = cursor + geometry(index, sizeColumn) + gap;
end
end

function values = gridGeometry(count)
if count == 0, values = zeros(0, 4); return; end
columns = ceil(sqrt(count));
rows = ceil(count / columns);
gap = 0.04;
width = (1 - gap * (columns - 1)) / columns;
height = (1 - gap * (rows - 1)) / rows;
values = zeros(count, 4);
for k = 1:count
    column = mod(k - 1, columns);
    row = floor((k - 1) / columns);
    values(k, :) = [column * (width + gap), ...
        1 - (row + 1) * height - row * gap, width, height];
end
end

function geometry = clampGeometry(geometry)
geometry = double(reshape(geometry, 1, 4));
geometry(3:4) = min(max(geometry(3:4), 0.02), 1);
geometry(1:2) = min(max(geometry(1:2), 0), 1 - geometry(3:4));
end

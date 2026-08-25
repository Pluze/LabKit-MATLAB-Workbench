%REORDERNODES Move selected objects one layer, to front, or to back.
function document = reorderNodes(document, nodeIds, direction)
nodeIds = unique(string(nodeIds(:)), "stable");
panelIds = unique(string({document.nodes( ...
    ismember(string({document.nodes.id}), nodeIds)).panelId}));
for panelId = reshape(panelIds, 1, [])
    panelMask = string({document.nodes.panelId}) == panelId & ...
        string({document.nodes.kind}) ~= "group";
    indices = find(panelMask);
    selected = ismember(string({document.nodes(indices).id}), nodeIds);
    order = 1:numel(indices);
    switch lower(string(direction))
        case "front"
            order = [order(~selected), order(selected)];
        case "back"
            order = [order(selected), order(~selected)];
        case "forward"
            for k = numel(order)-1:-1:1
                if selected(k) && ~selected(k+1)
                    order([k k+1]) = order([k+1 k]);
                    selected([k k+1]) = selected([k+1 k]);
                end
            end
        case "backward"
            for k = 2:numel(order)
                if selected(k) && ~selected(k-1)
                    order([k-1 k]) = order([k k-1]);
                    selected([k-1 k]) = selected([k k-1]);
                end
            end
        otherwise
            error("figure_studio:figureDocument:UnknownLayerMove", ...
                "Unknown layer movement: %s", string(direction));
    end
    document.nodes(indices) = document.nodes(indices(order));
end
document.revision = document.revision + 1;
end

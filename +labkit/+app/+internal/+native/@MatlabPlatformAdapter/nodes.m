function selected = nodes(obj, ids)
% Resolve ordered compiled children without rebuilding the layout ID list.
    ids = string(ids);
    indices = zeros(numel(ids), 1);
    for selectedIndex = 1:numel(ids)
        id = char(ids(selectedIndex));
        if ~isfield(obj.NodeIndices, id)
            error("labkit:app:runtime:InvariantFailure", ...
                "Compiled Layout child is missing: %s.", id);
        end
        indices(selectedIndex) = obj.NodeIndices.(id);
    end
    selected = reshape(obj.Plan.Nodes(indices), [], 1);
end

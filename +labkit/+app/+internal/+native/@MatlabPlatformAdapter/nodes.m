function selected = nodes(obj, ids)
% Class-folder implementation of MatlabPlatformAdapter.nodes.
    ids = string(ids);
    selected = repmat(obj.Plan.Nodes(1), numel(ids), 1);
    for selectedIndex = 1:numel(ids)
        id = ids(selectedIndex);
        index = find(string({obj.Plan.Nodes.Id}) == id, 1);
        if isempty(index)
            error("labkit:app:runtime:InvariantFailure", ...
                "Compiled Layout child is missing: %s.", id);
        end
        selected(selectedIndex, 1) = obj.Plan.Nodes(index);
    end
end

function selected = nodes(obj, ids)
% Class-folder implementation of MatlabPlatformAdapter.nodes.
    selected = repmat(obj.Plan.Nodes(1), 0, 1);
    for id = string(ids)
        index = find(string({obj.Plan.Nodes.Id}) == id, 1);
        if isempty(index)
            error("labkit:app:runtime:InvariantFailure", ...
                "Compiled Layout child is missing: %s.", id);
        end
        selected(end + 1, 1) = obj.Plan.Nodes(index);
    end
end

function owner = owningNode(obj, id)
% Resolve the native parent from the immutable compiled layout index.
    owner = [];
    if isfield(obj.ParentIndices, char(id))
        owner = obj.Plan.Nodes(obj.ParentIndices.(char(id)));
    end
end

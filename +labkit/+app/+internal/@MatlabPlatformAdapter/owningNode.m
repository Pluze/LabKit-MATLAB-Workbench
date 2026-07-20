function owner = owningNode(obj, id)
% Class-folder implementation of MatlabPlatformAdapter.owningNode.
    owner = [];
    for k = 1:numel(obj.Plan.Nodes)
        if any(obj.Plan.Nodes(k).ChildIds == id)
            owner = obj.Plan.Nodes(k);
            return
        end
    end
end

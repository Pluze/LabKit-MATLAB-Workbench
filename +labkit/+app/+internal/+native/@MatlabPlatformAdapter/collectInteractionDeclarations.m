function declarations = collectInteractionDeclarations(obj)
% Class-folder implementation of MatlabPlatformAdapter.collectInteractionDeclarations.
    chunks = cell(1, numel(obj.Plan.Nodes));
    for k = 1:numel(obj.Plan.Nodes)
        config = obj.Plan.Nodes(k).Configuration;
        if isfield(config, "Interactions")
            chunks{k} = config.Interactions;
        end
    end
    populated = ~cellfun("isempty", chunks);
    if any(populated)
        declarations = [chunks{populated}];
    else
        declarations = cell(1, 0);
    end
end

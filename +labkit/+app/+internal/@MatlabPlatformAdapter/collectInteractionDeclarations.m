function declarations = collectInteractionDeclarations(obj)
% Class-folder implementation of MatlabPlatformAdapter.collectInteractionDeclarations.
    declarations = {};
    for k = 1:numel(obj.Plan.Nodes)
        config = obj.Plan.Nodes(k).Configuration;
        if isfield(config, "Interactions")
            declarations = [declarations config.Interactions];
        end
    end
end

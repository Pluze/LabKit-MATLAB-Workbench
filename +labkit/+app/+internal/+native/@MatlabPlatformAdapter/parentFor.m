function parent = parentFor(obj, node)
% Resolve the native parent while preserving the workbench split ownership.
    parent = obj.Figure;
    if node.Kind == "workbench"
        return;
    end
    owner = obj.owningNode(node.Id);
    if isempty(owner)
        return;
    end
    if owner.Kind == "workbench"
        if node.Kind == "workspace"
            parent = obj.WorkbenchWorkspace;
        else
            parent = obj.WorkbenchControls;
        end
    else
        parent = obj.contentParent(owner.Id);
    end
end

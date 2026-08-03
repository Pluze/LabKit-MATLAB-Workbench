function parent = parentFor(obj, node)
% Class-folder implementation of MatlabPlatformAdapter.parentFor.
    if node.Kind == "workbench"
        parent = obj.Figure;
        return;
    end
    parent = obj.Figure;
    nodes = obj.Plan.Nodes;
    for k = 1:numel(nodes)
        if any(nodes(k).ChildIds == node.Id)
            if nodes(k).Kind == "workbench"
                if node.Kind == "workspace"
                    parent = obj.WorkbenchWorkspace;
                else
                    parent = obj.WorkbenchControls;
                end
                return;
            end
            parent = obj.contentParent(nodes(k).Id);
            return;
        end
    end
end

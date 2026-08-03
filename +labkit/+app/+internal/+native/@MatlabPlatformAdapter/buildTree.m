function buildTree(obj)
% Class-folder implementation of MatlabPlatformAdapter.buildTree.
    nodes = obj.Plan.Nodes;
    for k = 1:numel(nodes)
        node = nodes(k);
        parent = obj.parentFor(node);
        component = obj.createComponent(node, parent);
        if ~isempty(component)
            component.Tag = char(node.Id);
        end
        obj.placeInParent(node, component);
        obj.Components(char(node.Id)) = component;
    end
    workspaceIndex = find(string({nodes.Kind}) == "workspace", 1);
    if ~isempty(workspaceIndex)
        workspace = nodes(workspaceIndex);
        if strlength(workspace.InitialPage) > 0
            group = obj.component(workspace.Id);
            page = obj.component(workspace.InitialPage);
            group.SelectedTab = page;
        end
    end
end

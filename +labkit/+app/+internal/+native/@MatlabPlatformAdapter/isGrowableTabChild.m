function tf = isGrowableTabChild(obj, node)
% Class-folder implementation of MatlabPlatformAdapter.isGrowableTabChild.
    if node.Kind == "section" && isscalar(node.ChildIds)
        tf = obj.isGrowableTabChild(obj.node(node.ChildIds(1)));
        return
    end
    if node.Kind == "group"
        children = obj.nodes(node.ChildIds);
        tf = false;
        for k = 1:numel(children)
            child = children(k);
            if any(child.Kind == ["plotArea", "dataTable"]) || ...
                    (any(child.Kind == ["group", "section"]) && obj.isGrowableTabChild(child))
                tf = true;
                return
            end
        end
        return
    end
    if node.Kind == "fileList"
        tf = node.Configuration.SelectionMode == "multiple" || ...
            node.Configuration.MaxFiles > 1;
        return
    end
    tf = any(node.Kind == ["plotArea", "dataTable", "statusPanel"]);
end

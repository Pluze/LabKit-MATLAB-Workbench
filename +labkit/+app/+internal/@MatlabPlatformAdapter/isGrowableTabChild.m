function tf = isGrowableTabChild(obj, node)
% Class-folder implementation of MatlabPlatformAdapter.isGrowableTabChild.
    if node.Kind == "section" && numel(node.ChildIds) == 1
        tf = obj.isGrowableTabChild(obj.node(node.ChildIds(1)));
        return
    end
    if node.Kind == "fileList"
        tf = node.Configuration.SelectionMode == "multiple" || ...
            node.Configuration.MaxFiles > 1;
        return
    end
    tf = any(node.Kind == [ ...
        "plotArea", "dataTable", "logPanel", "statusPanel"]);
end

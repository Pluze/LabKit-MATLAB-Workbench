function tf = sectionDrawsOwnTitle(obj, node)
% Class-folder implementation of MatlabPlatformAdapter.sectionDrawsOwnTitle.
    tf = true;
    if node.Kind ~= "section" || numel(node.ChildIds) ~= 1
        return
    end
    child = obj.node(node.ChildIds(1));
    tf = ~any(child.Kind == [ ...
        "plotArea", "dataTable", "statusPanel", "fileList"]);
end

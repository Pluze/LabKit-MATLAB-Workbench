function tf = usesAdaptiveActionGrid(obj, node)
% Class-folder implementation of MatlabPlatformAdapter.usesAdaptiveActionGrid.
    tf = false;
    if node.Kind ~= "group" || ...
            ~isfield(node.Configuration, "Layout") || ...
            node.Configuration.Layout ~= "auto" || ...
            isempty(node.ChildIds)
        return
    end
    children = obj.nodes(node.ChildIds);
    tf = all(string({children.Kind}) == "button");
end

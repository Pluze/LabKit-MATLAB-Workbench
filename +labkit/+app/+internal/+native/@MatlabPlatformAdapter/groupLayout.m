function layout = groupLayout(obj, node)
% Resolve the orientation used by measurement, construction and placement.
    layout = "vertical";
    if node.Kind ~= "group"
        return
    end
    layout = node.Configuration.Layout;
    if layout == "auto"
        children = obj.nodes(node.ChildIds);
        if ~isempty(children) && all(string({children.Kind}) == "button")
            layout = "actions";
        else
            layout = "vertical";
        end
    end
end

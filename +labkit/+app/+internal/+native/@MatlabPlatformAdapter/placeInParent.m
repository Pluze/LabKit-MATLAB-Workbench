function placeInParent(obj, node, component)
% Class-folder implementation of MatlabPlatformAdapter.placeInParent.
    if any(node.Kind == ["workbench","workspacePage"]) || isempty(component)
        return
    end
    parentNode = obj.owningNode(node.Id);
    if isempty(parentNode) || parentNode.Kind == "workbench"
        return
    end
    index = find(parentNode.ChildIds == node.Id, 1);
    if isempty(index)
        return
    end
    handle = labkit.app.internal.native.NativeAdapterValues.layoutHandle(component);
    if isempty(handle) || ~isprop(handle, "Layout")
        return
    end
    layout = obj.groupLayout(parentNode);
    if layout == "actions"
        [~, columns] = obj.actionGridSize(parentNode);
        row = ceil(index / columns);
        column = mod(index - 1, columns) + 1;
        if columns > 1 && index == numel(parentNode.ChildIds) && ...
                mod(numel(parentNode.ChildIds), columns) == 1
            column = [1 columns];
        end
        handle.Layout.Row = row;
        handle.Layout.Column = column;
    elseif layout == "horizontal"
        handle.Layout.Row = 1;
        handle.Layout.Column = index;
    else
        row = index;
        column = 1;
        if parentNode.Kind == "tab"
            row = 1 + 5 * (index - 1);
            if numel(parentNode.ChildIds) > 1
                column = [1 3];
            end
        elseif isstruct(handle.Parent.UserData) && isfield(handle.Parent.UserData,"HeadingRow")
            row = index + 1;
        end
        handle.Layout.Row = row;
        handle.Layout.Column = column;
    end
end

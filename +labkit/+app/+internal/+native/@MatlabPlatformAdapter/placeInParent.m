function placeInParent(obj, node, component)
% Class-folder implementation of MatlabPlatformAdapter.placeInParent.
    if node.Kind == "workbench" || isempty(component)
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
    horizontal = parentNode.Kind == "group" && ...
        isfield(parentNode.Configuration, "Layout") && ...
        parentNode.Configuration.Layout == "horizontal";
    if obj.usesAdaptiveActionGrid(parentNode)
        [~, columns] = obj.actionGridSize(parentNode);
        row = ceil(index / columns);
        column = mod(index - 1, columns) + 1;
        if columns > 1 && index == numel(parentNode.ChildIds) && ...
                mod(numel(parentNode.ChildIds), columns) == 1
            column = [1 columns];
        end
        handle.Layout.Row = row;
        handle.Layout.Column = column;
    elseif horizontal
        handle.Layout.Row = 1;
        handle.Layout.Column = index;
    else
        row = index;
        if parentNode.Kind == "tab"
            row = 2 * index - 1;
        end
        handle.Layout.Row = row;
        handle.Layout.Column = 1;
    end
end

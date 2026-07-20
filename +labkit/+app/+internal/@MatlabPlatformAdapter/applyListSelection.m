function applyListSelection(~, component, selection)
% Class-folder implementation of MatlabPlatformAdapter.applyListSelection.
    if ~isprop(component, "Items") || ~isprop(component, "Value")
        return;
    end
    items = string(component.Items);
    indices = selection.Indices;
    indices = indices(indices >= 1 & indices <= numel(items));
    component.Value = items(indices);
end

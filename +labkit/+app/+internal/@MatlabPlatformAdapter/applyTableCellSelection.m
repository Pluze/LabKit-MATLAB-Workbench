function applyTableCellSelection(~, component, selection)
% Class-folder implementation of MatlabPlatformAdapter.applyTableCellSelection.
    if isprop(component, "Selection")
        component.Selection = selection.CellIndices;
    end
end

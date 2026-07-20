function applyTableData(~, component, model)
% Class-folder implementation of MatlabPlatformAdapter.applyTableData.
    component.Data = labkit.app.internal.NativeAdapterValues.nativeTableData(model.Data);
    if ~isempty(model.Columns)
        component.ColumnName = cellstr(model.Columns);
    end
    if ~isempty(model.RowNames)
        component.RowName = cellstr(model.RowNames);
    end
    component.ColumnEditable = model.ColumnEditable;
end

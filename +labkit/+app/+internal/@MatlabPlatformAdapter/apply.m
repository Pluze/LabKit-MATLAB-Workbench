function apply(obj, operation)
% Class-folder implementation of MatlabPlatformAdapter.apply.
    component = obj.component(operation.Target);
    switch operation.Kind
        case "value"
            obj.applyValue(component, operation.Value);
        case "choices"
            labkit.app.internal.NativeAdapterValues.applyChoices(component, operation.Value);
        case "limits"
            obj.applyLimits(component, operation.Value);
        case "enabled"
            obj.applyEnabled(component, operation.Value);
        case "visible"
            labkit.app.internal.NativeAdapterValues.setIfProperty(labkit.app.internal.NativeAdapterValues.layoutHandle(component), ...
                "Visible", labkit.app.internal.NativeAdapterValues.onOff(operation.Value));
        case "text"
            obj.applyText(component, operation.Value);
        case "filePaths"
            obj.applyFilePaths(component, operation.Value);
        case "fileItemStatuses"
            obj.applyFileItemStatuses(component, operation.Value);
        case "listSelection"
            obj.applyListSelection(component, operation.Value);
        case "tableCellSelection"
            obj.applyTableCellSelection(component, operation.Value);
        case "tableData"
            obj.applyTableData(component, operation.Value);
        case "renderPlot"
            obj.renderPlot(operation);
        case "workspacePage"
            labkit.app.internal.NativeAdapterValues.setIfProperty(component, "Enable", labkit.app.internal.NativeAdapterValues.onOff(operation.Value.Enabled));
            component.UserData = struct("Status", operation.Value.Status);
    end
end

function applyFilePaths(~, component, paths)
% Class-folder implementation of MatlabPlatformAdapter.applyFilePaths.
    data = component.UserData;
    data.Paths = reshape(string(paths), 1, []);
    if numel(data.ItemStatuses) ~= numel(data.Paths)
        data.ItemStatuses = strings(1, 0);
    end
    component.UserData = data;
    labels = labkit.app.internal.native.NativeAdapterValues.formatFileLabels(paths, data.ItemStatuses);
    if isempty(labels) && ~data.Compact
        labels = data.EmptyText;
    end
    labkit.app.internal.native.NativeAdapterValues.setIfProperty(component, "Items", labels);
    if ~isstruct(component.UserData) || ...
            ~isfield(component.UserData, "Status") || ...
            isempty(component.UserData.Status) || ...
            ~isvalid(component.UserData.Status)
        return
    end
    text = component.UserData.EmptyText;
    if ~isempty(paths)
        if component.UserData.Compact
            text = string(paths(1));
        elseif isscalar(paths)
            text = "1 file";
        else
            text = string(numel(paths)) + " files";
        end
    end
    if component.UserData.Compact
        status = component.UserData.Status;
        status.Value = char( ...
            labkit.app.internal.native.NativeAdapterValues.compactFileLabel(text));
        if isprop(status, "Tooltip")
            status.Tooltip = char(string(text));
        end
    else
        component.UserData.Status.Value = cellstr(string(text));
    end
end

function applyFilePaths(~, component, paths)
% Class-folder implementation of MatlabPlatformAdapter.applyFilePaths.
    data = component.UserData;
    data.Paths = reshape(string(paths), 1, []);
    if numel(data.ItemStatuses) ~= numel(data.Paths)
        data.ItemStatuses = strings(1, 0);
    end
    component.UserData = data;
    labels = labkit.app.internal.NativeAdapterValues.formatFileLabels(paths, data.ItemStatuses);
    if isempty(labels) && ~data.Compact
        labels = data.EmptyText;
    end
    labkit.app.internal.NativeAdapterValues.setIfProperty(component, "Items", labels);
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
        elseif numel(paths) == 1
            text = "1 file";
        else
            text = string(numel(paths)) + " files";
        end
    end
    if component.UserData.Compact
        component.UserData.Status.Value = char(string(text));
    else
        component.UserData.Status.Value = cellstr(string(text));
    end
end

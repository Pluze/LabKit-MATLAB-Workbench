function applyFileItemStatuses(~, component, statuses)
% Class-folder implementation of MatlabPlatformAdapter.applyFileItemStatuses.
    data = component.UserData;
    statuses = reshape(string(statuses), 1, []);
    if ~isempty(statuses) && numel(statuses) ~= numel(data.Paths)
        error("labkit:app:contract:InvalidValue", ...
            "File item statuses must be empty or match file paths.");
    end
    data.ItemStatuses = statuses;
    component.UserData = data;
    labels = labkit.app.internal.NativeAdapterValues.formatFileLabels(data.Paths, statuses);
    if isempty(labels) && ~data.Compact
        labels = data.EmptyText;
    end
    labkit.app.internal.NativeAdapterValues.setIfProperty(component, "Items", labels);
end

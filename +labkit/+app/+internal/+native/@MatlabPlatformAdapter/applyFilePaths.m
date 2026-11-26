function applyFilePaths(obj, component, paths)
% Class-folder implementation of MatlabPlatformAdapter.applyFilePaths.
    data = component.UserData;
    data.Paths = reshape(string(paths), 1, []);
    if numel(data.ItemStatuses) ~= numel(data.Paths)
        data.ItemStatuses = strings(1, 0);
    end
    component.UserData = data;
    labels = labkit.app.internal.native.NativeAdapterValues.formatFileLabels(paths, data.ItemStatuses);
    labkit.app.internal.native.NativeAdapterValues.setIfProperty(component, "Items", labels);
    if data.Compact
        text = data.EmptyText;
        if ~isempty(paths)
            text = string(paths(1));
        end
        data.Status.Value = char(labkit.app.internal.native.NativeAdapterValues.compactFileLabel(text));
        data.Status.Tooltip = char(text);
        return
    end
    hasFiles = ~isempty(paths);
    component.Visible = labkit.app.internal.native.NativeAdapterValues.onOff(hasFiles);
    data.EmptyLabel.Visible = labkit.app.internal.native.NativeAdapterValues.onOff(~hasFiles);
    footer = data.Remove.Parent;
    footer.Visible = component.Visible;
    grid = component.Parent;
    policy = labkit.app.internal.native.NativeAdapterValues.layoutPolicy();
    grid.RowHeight{footer.Layout.Row} = policy.ButtonHeight * hasFiles;
    height = policy.EmptyFileListHeight;
    if hasFiles
        height = policy.FileListNoStatusHeight;
    end
    if ~isempty(data.Status) && data.Status.Visible == "on"
        height = height + 64;
    end
    obj.updateContentHeight(data.Target, height);
    if isempty(data.CountLabel)
        return
    end
    if isscalar(paths)
        data.CountLabel.Text = "1 file";
    else
        data.CountLabel.Text = string(numel(paths)) + " files";
    end
end

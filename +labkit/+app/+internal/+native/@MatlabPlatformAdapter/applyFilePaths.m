function applyFilePaths(~, component, paths)
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
    panel = data.Panel;
    parent = panel.Parent;
    if isa(parent,"matlab.ui.container.GridLayout") && isscalar(parent.ColumnWidth) && ...
            numel(parent.RowHeight) > 1 && isempty(data.Status)
        row = panel.Layout.Row;
        height = parent.RowHeight{row};
        if ~hasFiles && isnumeric(height) && ~isfield(data,"LoadedHeight")
            data.LoadedHeight = height;
            parent.RowHeight{row} = min(height,116);
            component.UserData = data;
        elseif hasFiles && isfield(data,"LoadedHeight")
            parent.RowHeight{row} = data.LoadedHeight;
            component.UserData = rmfield(data,"LoadedHeight");
        end
    end
    component.Visible = labkit.app.internal.native.NativeAdapterValues.onOff(hasFiles);
    data.EmptyLabel.Visible = labkit.app.internal.native.NativeAdapterValues.onOff(~hasFiles);
    footer = data.Remove.Parent;
    footer.Visible = component.Visible;
    grid = component.Parent;
    grid.RowHeight{footer.Layout.Row} = 28 * hasFiles;
    if isempty(data.CountLabel)
        return
    end
    if isscalar(paths)
        data.CountLabel.Text = "1 file";
    else
        data.CountLabel.Text = string(numel(paths)) + " files";
    end
end

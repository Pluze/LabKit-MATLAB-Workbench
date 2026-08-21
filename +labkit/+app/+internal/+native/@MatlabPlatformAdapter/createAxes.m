function createAxes(obj, node, parent)
% Class-folder implementation of MatlabPlatformAdapter.createAxes.
    config = node.Configuration;
    hasModes = ~isempty(config.ViewModes);
    root = uigridlayout(parent, [1 + double(hasModes) 1], ...
        Padding=[2 2 2 2], RowSpacing=4, ColumnSpacing=2);
    root.RowHeight = {'1x'};
    axesRow = 1;
    mode = [];
    if hasModes
        root.RowHeight = {'fit', '1x'};
        mode = uidropdown(root, Items=config.ViewModes, ...
            Value=config.ViewModes(1), ...
            Tag=char(node.Id + ".viewMode"));
        mode.Layout.Row = 1;
        mode.Layout.Column = 1;
        axesRow = 2;
    end
    axisCount = numel(node.AxisIds);
    switch config.Layout
        case "pair"
            layout = uigridlayout(root, [1 axisCount]);
            layout.RowHeight = {'1x'};
            layout.ColumnWidth = labkit.app.internal.native.NativeAdapterValues.repeatedOrConfigured( ...
                config.ColumnWidths, axisCount);
        case "stack"
            layout = uigridlayout(root, [axisCount 1]);
            layout.RowHeight = repmat({'1x'}, 1, axisCount);
            layout.ColumnWidth = {'1x'};
        otherwise
            layout = uigridlayout(root, [1 1]);
            layout.RowHeight = {'1x'};
            layout.ColumnWidth = {'1x'};
    end
    layout.Layout.Row = axesRow;
    layout.Layout.Column = 1;
    layout.Padding = [0 0 0 0];
    layout.RowSpacing = 2;
    layout.ColumnSpacing = 2;
    for k = 1:numel(node.AxisIds)
        axisId = node.AxisIds(k);
        key = labkit.app.internal.native.NativeAdapterValues.axisKey(node.Id, axisId);
        ax = uiaxes(layout, Tag=char(key));
        if config.Layout == "stack"
            ax.Layout.Row = k;
            ax.Layout.Column = 1;
        elseif config.Layout == "pair"
            ax.Layout.Row = 1;
            ax.Layout.Column = k;
        else
            ax.Layout.Row = 1;
            ax.Layout.Column = 1;
        end
        title(ax, labkit.app.internal.native.NativeAdapterValues.axisText(config.AxisTitles, node.AxisIds, k));
        xlabel(ax, labkit.app.internal.native.NativeAdapterValues.axisText(config.XLabels, strings(1, axisCount), k));
        ylabel(ax, labkit.app.internal.native.NativeAdapterValues.axisText(config.YLabels, strings(1, axisCount), k));
        if config.ScrollZoomAxes(k) ~= "xy"
            setappdata(ax, "labkitPreviewScrollZoomAxes", ...
                config.ScrollZoomAxes(k));
        end
        obj.Axes(char(key)) = ax;
    end
    parent.UserData = struct("ValueControl", mode);
end

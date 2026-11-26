function createAxes(obj, node, parent)
% Class-folder implementation of MatlabPlatformAdapter.createAxes.
    config = node.Configuration;
    hasModes = ~isempty(config.ViewModes);
    axisCount = numel(node.AxisIds);
    isPair = config.Layout == "pair";
    isStack = config.Layout == "stack";
    rows = 1;
    columns = 1;
    if isStack
        rows = axisCount;
    elseif isPair
        columns = axisCount;
    end
    parent.BackgroundColor = obj.Appearance.Surface;
    layout = uigridlayout(parent, [rows + hasModes, columns], ...
        Padding=[2 2 2 2], RowSpacing=2, ColumnSpacing=2, ...
        BackgroundColor=obj.Appearance.Surface);
    layout.RowHeight = repmat({'1x'}, 1, rows);
    if isPair
        layout.ColumnWidth = labkit.app.internal.native.NativeAdapterValues.repeatedOrConfigured( ...
            config.ColumnWidths, axisCount);
        layout.BackgroundColor = obj.Appearance.Background;
        layout.ColumnSpacing = 12;
    end
    mode = [];
    if hasModes
        policy = labkit.app.internal.native.NativeAdapterValues.layoutPolicy();
        layout.RowHeight = [{policy.FieldHeight}, layout.RowHeight];
        mode = uidropdown(layout, Items=config.ViewModes, Value=config.ViewModes(1), ...
            Tag=char(node.Id + ".viewMode"), Tooltip="Choose a plot view");
        mode.Layout.Row = 1;
        if columns > 1
            mode.Layout.Column = [1 columns];
        else
            mode.Layout.Column = 1;
        end
    end
    for k = 1:numel(node.AxisIds)
        axisId = node.AxisIds(k);
        key = labkit.app.internal.native.NativeAdapterValues.axisKey(node.Id, axisId);
        host = layout;
        if isPair
            host = uigridlayout(layout,[1 1], Padding=[0 0 0 0], BackgroundColor=obj.Appearance.Surface);
            host.Layout.Row = 1 + hasModes;
            host.Layout.Column = k;
        end
        ax = uiaxes(host, Tag=char(key));
        % Create once before renderers inspect MATLAB's lazy Toolbar property.
        axtoolbar(ax, 'default');
        if isStack
            ax.Layout.Row = k + hasModes;
        elseif isPair
            ax.Layout.Row = 1;
        else
            ax.Layout.Row = 1 + hasModes;
        end
        ax.Layout.Column = 1;
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

function first = createRangeField(~, node, parent)
% Class-folder implementation of MatlabPlatformAdapter.createRangeField.
    config = node.Configuration;
    [limits, value] = labkit.app.internal.native.NativeAdapterValues.rangeSliderInitialValue(config);
    grid = labkit.app.internal.native.NativeAdapterValues.labeledParent(parent, config.Label, node.Id);
    grid.ColumnWidth = {'1x', '1x'};
    grid.RowHeight = {22, '1x'};
    grid.RowSpacing = 4;
    label = grid.UserData.Label;
    label.Text = "Lower";
    if config.Label ~= ""
        label.Text = config.Label + " · Lower";
    end
    label.Tooltip = label.Text;
    label.HorizontalAlignment = "left";
    upper = uilabel(grid, Text="Upper");
    upper.Layout.Row = 1;
    upper.Layout.Column = 2;
    first = uieditfield(grid, "numeric", Limits=limits, ...
        Value=value(1), Enable=labkit.app.internal.native.NativeAdapterValues.onOff(config.Enabled));
    first.Tooltip = char(config.Label + " · start");
    first.Layout.Row = 2;
    first.Layout.Column = 1;
    second = uieditfield(grid, "numeric", Limits=limits, ...
        Value=value(2), Enable=labkit.app.internal.native.NativeAdapterValues.onOff(config.Enabled), ...
        Tag=char(node.Id + ".end"));
    second.Tooltip = char(config.Label + " · end");
    second.Layout.Row = 2;
    second.Layout.Column = 2;
    first.UserData = struct( ...
        "LayoutContainer", grid, "EndField", second);
end

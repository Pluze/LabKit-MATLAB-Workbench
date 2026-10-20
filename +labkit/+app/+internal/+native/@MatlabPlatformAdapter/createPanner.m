function spinner = createPanner(~, node, parent)
% Class-folder implementation of MatlabPlatformAdapter.createPanner.
    config = node.Configuration;
    [limits, value] = labkit.app.internal.native.NativeAdapterValues.sliderInitialValue(config);
    outer = labkit.app.internal.native.NativeAdapterValues.labeledParent(parent, config.Label, node.Id);
    outer.UserData.LabelPosition = config.LabelPosition;
    labkit.app.internal.native.NativeAdapterValues.setControlLabel(outer.UserData.Label, config.Label);
    grid = uigridlayout(outer, [1 2], ...
        Padding=[0 0 0 0], ColumnSpacing=6, ...
        ColumnWidth={76, '1x'}, ...
        Tag=char(node.Id + ".panner"));
    grid.Layout.Row = 1;
    grid.Layout.Column = 2;
    if config.LabelPosition == "top"
        grid.Layout.Row = 2;
        grid.Layout.Column = 1;
    end
    step = config.Step;
    if isempty(step)
        step = max(eps, diff(limits) * 0.002);
    end
    spinner = uispinner(grid, Limits=limits, Value=value, ...
        Step=step, Enable=labkit.app.internal.native.NativeAdapterValues.onOff(config.Enabled));
    spinner.Layout.Row = 1;
    spinner.Layout.Column = 1;
    if strlength(config.ValueDisplayFormat) > 0
        spinner.ValueDisplayFormat = ...
            char(config.ValueDisplayFormat);
    end
    slider = uislider(grid, Limits=limits, Value=value, ...
        Enable=labkit.app.internal.native.NativeAdapterValues.onOff(config.Enabled), ...
        Tag=char(node.Id + ".slider"));
    slider.Layout.Row = 1;
    slider.Layout.Column = 2;
    if ~config.ShowValue
        spinner.Visible = "off";
        grid.ColumnWidth = {0, '1x'};
        grid.ColumnSpacing = 0;
    end
    slider.MajorTicks = [];
    slider.MinorTicks = [];
    spinner.UserData = struct( ...
        "LayoutContainer", outer, "Slider", slider, ...
        "CommittedValue", value);
end

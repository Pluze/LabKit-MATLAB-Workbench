function spinner = createPanner(~, node, parent)
% Class-folder implementation of MatlabPlatformAdapter.createPanner.
    config = node.Configuration;
    [limits, value] = labkit.app.internal.NativeAdapterValues.sliderInitialValue(config);
    outer = labkit.app.internal.NativeAdapterValues.labeledParent(parent, config.Label, node.Id);
    grid = uigridlayout(outer, [1 2], ...
        Padding=[0 0 0 0], ColumnSpacing=6, ...
        ColumnWidth={76, '1x'}, ...
        Tag=char(node.Id + ".panner"));
    grid.Layout.Row = 1;
    grid.Layout.Column = 2;
    step = config.Step;
    if isempty(step)
        step = max(eps, diff(limits) * 0.002);
    end
    spinner = uispinner(grid, Limits=limits, Value=value, ...
        Step=step, Enable=labkit.app.internal.NativeAdapterValues.onOff(config.Enabled));
    spinner.Layout.Row = 1;
    spinner.Layout.Column = 1;
    if strlength(config.ValueDisplayFormat) > 0
        spinner.ValueDisplayFormat = ...
            char(config.ValueDisplayFormat);
    end
    slider = uislider(grid, Limits=limits, Value=value, ...
        Enable=labkit.app.internal.NativeAdapterValues.onOff(config.Enabled), ...
        Tag=char(node.Id + ".slider"));
    slider.Layout.Row = 1;
    slider.Layout.Column = 2;
    if ~config.ShowTicks
        slider.MajorTicks = [];
        slider.MinorTicks = [];
    end
    spinner.UserData = struct( ...
        "LayoutContainer", outer, "Slider", slider);
end

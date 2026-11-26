function spinner = createPanner(~, node, parent)
% Class-folder implementation of MatlabPlatformAdapter.createPanner.
    config = node.Configuration;
    [limits, value] = labkit.app.internal.native.NativeAdapterValues.sliderInitialValue(config);
    outer = labkit.app.internal.native.NativeAdapterValues.labeledParent(parent, config.Label, node.Id);
    policy = labkit.app.internal.native.NativeAdapterValues.layoutPolicy();
    label = outer.UserData.Label;
    if config.ShowValue
        % Give precision entry and dragging separate rows, even in a narrow rail.
        outer.ColumnWidth = {'1x', 92};
        outer.RowHeight = {policy.FieldHeight, policy.SliderHeight};
        outer.RowSpacing = 4;
        label.HorizontalAlignment = "left";
        entryParent = outer;
        trackParent = outer;
    else
        outer.UserData.LabelPosition = config.LabelPosition;
        labkit.app.internal.native.NativeAdapterValues.setControlLabel(label, config.Label);
        trackParent = uigridlayout(outer, [1 1], Padding=[0 0 0 0]);
        if config.LabelPosition == "top"
            trackParent.Layout.Column = 1;
            trackParent.Layout.Row = 2;
        else
            trackParent.Layout.Column = 2;
        end
        entryParent = trackParent;
    end
    step = config.Step;
    if isempty(step)
        step = max(eps, diff(limits) * 0.002);
    end
    spinner = uispinner(entryParent, Limits=limits, Value=value, ...
        Step=step, Enable=labkit.app.internal.native.NativeAdapterValues.onOff(config.Enabled));
    spinner.Layout.Row = 1;
    spinner.Layout.Column = 1 + config.ShowValue;
    spinner.Tooltip = char(config.Label);
    if strlength(config.ValueDisplayFormat) > 0
        spinner.ValueDisplayFormat = ...
            char(config.ValueDisplayFormat);
    end
    slider = uislider(trackParent, Limits=limits, Value=value, ...
        Enable=labkit.app.internal.native.NativeAdapterValues.onOff(config.Enabled), ...
        Tag=char(node.Id + ".slider"));
    slider.Tooltip = char(config.Label);
    if config.ShowValue
        slider.Layout.Row = 2;
        slider.Layout.Column = [1 2];
    else
        slider.Layout.Row = 1;
        slider.Layout.Column = 1;
        spinner.Visible = "off";
    end
    slider.MajorTicks = [];
    slider.MinorTicks = [];
    spinner.UserData = struct( ...
        "LayoutContainer", outer, "Slider", slider, ...
        "LiveUpdate", config.LiveUpdate, "LastDragUpdate", [], "CommittedValue", value);
end

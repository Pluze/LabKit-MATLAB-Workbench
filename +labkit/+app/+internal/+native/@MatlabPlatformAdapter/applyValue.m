function applyValue(~, component, value)
% Class-folder implementation of MatlabPlatformAdapter.applyValue.
    mode = labkit.app.internal.native.NativeAdapterValues.linkedPlotMode(component);
    if ~isempty(mode)
        mode.Value = value;
        return
    end
    rangeEnd = labkit.app.internal.native.NativeAdapterValues.linkedRangeEnd(component);
    if ~isempty(rangeEnd)
        component.Value = value(1);
        rangeEnd.Value = value(2);
        return
    end
    labkit.app.internal.native.NativeAdapterValues.setIfProperty(component, "Value", value);
    linked = labkit.app.internal.native.NativeAdapterValues.linkedPannerSlider(component);
    if ~isempty(linked)
        linked.Value = min(linked.Limits(2), ...
            max(linked.Limits(1), double(value)));
    end
end

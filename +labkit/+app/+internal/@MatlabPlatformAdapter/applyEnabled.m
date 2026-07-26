function applyEnabled(~, component, enabled)
% Class-folder implementation of MatlabPlatformAdapter.applyEnabled.
    value = labkit.app.internal.NativeAdapterValues.onOff(enabled);
    labkit.app.internal.NativeAdapterValues.setIfProperty(component, "Enable", value);
    label = labkit.app.internal.NativeAdapterValues.linkedLabel(component);
    if ~isempty(label)
        labkit.app.internal.NativeAdapterValues.setIfProperty(label, "Enable", value);
    end
    mode = labkit.app.internal.NativeAdapterValues.linkedPlotMode(component);
    if ~isempty(mode)
        mode.Enable = value;
    end
    linked = labkit.app.internal.NativeAdapterValues.linkedPannerSlider(component);
    if ~isempty(linked)
        linked.Enable = value;
    end
    rangeEnd = labkit.app.internal.NativeAdapterValues.linkedRangeEnd(component);
    if ~isempty(rangeEnd)
        rangeEnd.Enable = value;
    end
end

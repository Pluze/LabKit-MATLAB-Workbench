function applyEnabled(~, component, enabled)
% Class-folder implementation of MatlabPlatformAdapter.applyEnabled.
    value = labkit.app.internal.native.NativeAdapterValues.onOff(enabled);
    labkit.app.internal.native.NativeAdapterValues.setIfProperty(component, "Enable", value);
    label = labkit.app.internal.native.NativeAdapterValues.linkedLabel(component);
    if ~isempty(label)
        labkit.app.internal.native.NativeAdapterValues.setIfProperty(label, "Enable", value);
    end
    mode = labkit.app.internal.native.NativeAdapterValues.linkedPlotMode(component);
    if ~isempty(mode)
        mode.Enable = value;
    end
    linked = labkit.app.internal.native.NativeAdapterValues.linkedPannerSlider(component);
    if ~isempty(linked)
        linked.Enable = value;
    end
    rangeEnd = labkit.app.internal.native.NativeAdapterValues.linkedRangeEnd(component);
    if ~isempty(rangeEnd)
        rangeEnd.Enable = value;
    end
end

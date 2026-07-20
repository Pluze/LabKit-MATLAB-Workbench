function applyLimits(~, component, limits)
% Class-folder implementation of MatlabPlatformAdapter.applyLimits.
    rangeEnd = labkit.app.internal.NativeAdapterValues.linkedRangeEnd(component);
    if ~isempty(rangeEnd)
        component.Limits = limits;
        rangeEnd.Limits = limits;
        return
    end
    linked = labkit.app.internal.NativeAdapterValues.linkedPannerSlider(component);
    if isempty(linked)
        labkit.app.internal.NativeAdapterValues.setIfProperty(component, "Limits", limits);
        return
    end
    value = min(limits(2), ...
        max(limits(1), double(component.Value)));
    component.Limits = limits;
    component.Value = value;
    linked.Limits = limits;
    linked.Value = value;
end

function applyEnabled(~, component, enabled)
% Class-folder implementation of MatlabPlatformAdapter.applyEnabled.
    value = labkit.app.internal.NativeAdapterValues.onOff(enabled);
    labkit.app.internal.NativeAdapterValues.setIfProperty(component, "Enable", value);
    if isprop(component, "Tag") && strlength(string(component.Tag)) > 0
        figure = ancestor(component, "figure");
        labels = findall(figure, "Tag", ...
            char(string(component.Tag) + ".label"));
        for k = 1:numel(labels)
            labkit.app.internal.NativeAdapterValues.setIfProperty(labels(k), "Enable", value);
        end
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

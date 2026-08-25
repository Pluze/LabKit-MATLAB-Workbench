function applyValue(obj, component, value)
% Class-folder implementation of MatlabPlatformAdapter.applyValue.
    if isstruct(component.UserData) && ...
            isfield(component.UserData, "Readonly") && ...
            component.UserData.Readonly
        obj.applyText(component, value);
        return
    end
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
        value = min(linked.Limits(2), max(linked.Limits(1), double(value)));
        linked.Value = value;
        data = component.UserData;
        data.CommittedValue = value;
        component.UserData = data;
    end
end

function applyText(obj, component, value)
% Class-folder implementation of MatlabPlatformAdapter.applyText.
    if isstruct(component.UserData) && ...
            isfield(component.UserData, "Status") && ...
            isfield(component.UserData, "Compact") && ...
            ~isempty(component.UserData.Status) && ...
            isvalid(component.UserData.Status)
        if component.UserData.Compact
            status = component.UserData.Status;
            status.Value = char( ...
                labkit.app.internal.native.NativeAdapterValues.compactFileLabel(value));
            if isprop(status, "Tooltip")
                status.Tooltip = char(string(value));
            end
        else
            component.UserData.Status.Value = cellstr(string(value));
        end
        labkit.app.internal.native.NativeAdapterValues.fitText(component.UserData.Status);
        return
    elseif ~isempty( ...
            labkit.app.internal.native.NativeAdapterValues. ...
            linkedPannerSlider(component))
        label = labkit.app.internal.native.NativeAdapterValues. ...
            linkedLabel(component);
        if isempty(label)
            error("labkit:app:runtime:InvariantFailure", ...
                "A slider text operation requires its cached label.");
        end
        label.Text = char(string(value));
        labkit.app.internal.native.NativeAdapterValues.fitText(label);
        return
    elseif isprop(component, "Text")
        component.Text = value;
    elseif isprop(component, "Value")
        component.Value = value;
    elseif isprop(component, "Title")
        component.Title = value;
    end
    if isstruct(component.UserData) && ...
            isfield(component.UserData, "Readonly") && ...
            component.UserData.Readonly && isprop(component, "Tooltip")
        component.Tooltip = char(join( ...
            labkit.app.internal.native.NativeAdapterValues.readonlyLines(value), ...
            newline));
        obj.updateReadonlyHeight(component, value);
        return
    end
    labkit.app.internal.native.NativeAdapterValues.fitText(component);
    if isappdata(component, "labkitAppLogFollowLatest") && ...
            getappdata(component, "labkitAppLogFollowLatest")
        try
            scroll(component, "bottom");
        catch
        end
    end
end

function applyText(~, component, value)
% Class-folder implementation of MatlabPlatformAdapter.applyText.
    if isstruct(component.UserData) && ...
            isfield(component.UserData, "Status") && ...
            isfield(component.UserData, "Compact") && ...
            ~isempty(component.UserData.Status) && ...
            isvalid(component.UserData.Status)
        if component.UserData.Compact
            component.UserData.Status.Value = char(string(value));
        else
            component.UserData.Status.Value = cellstr(string(value));
        end
        labkit.app.internal.native.NativeAdapterValues.fitText(component.UserData.Status);
        return
    elseif isprop(component, "Text")
        component.Text = value;
    elseif isprop(component, "Value")
        component.Value = value;
    elseif isprop(component, "Title")
        component.Title = value;
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

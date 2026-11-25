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
            status = component.UserData.Status;
            lines = string(value);
            status.Value = cellstr(lines);
            show = any(strlength(lines) > 0, "all");
            status.Visible = labkit.app.internal.native.NativeAdapterValues.onOff(show);
            grid = status.Parent;
            grid.RowHeight{status.Layout.Row} = 64 * show;
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
        labkit.app.internal.native.NativeAdapterValues.setControlLabel(label, value);
        return
    elseif isstruct(component.UserData) && isfield(component.UserData,"HeadingContext")
        component.UserData.HeadingContext.Text = value;
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
end

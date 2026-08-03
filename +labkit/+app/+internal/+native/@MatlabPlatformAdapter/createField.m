function component = createField(~, parent, config, id)
% Class-folder implementation of MatlabPlatformAdapter.createField.
    value = labkit.app.internal.native.NativeAdapterValues.neutralValue(config.Value, config.Kind, config.Choices);
    if config.Kind == "logical"
        component = uicheckbox(parent, Text=config.Label, ...
            Value=logical(value), Enable=labkit.app.internal.native.NativeAdapterValues.onOff(config.Enabled));
        return;
    end
    parent = labkit.app.internal.native.NativeAdapterValues.labeledParent(parent, config.Label, id);
    layoutContainer = parent;
    switch config.Kind
        case "numeric"
            component = uieditfield(parent, "numeric", ...
                Value=value, Enable=labkit.app.internal.native.NativeAdapterValues.onOff(config.Enabled));
        case "choice"
            choices = config.Choices;
            if isempty(choices)
                choices = "";
            end
            component = uidropdown(parent, Items=choices, ...
                Value=value, Enable=labkit.app.internal.native.NativeAdapterValues.onOff(config.Enabled));
        case "readonly"
            component = uitextarea(parent, Editable="off", ...
                Value=char(string(value)), ...
                Enable=labkit.app.internal.native.NativeAdapterValues.onOff(config.Enabled));
        otherwise
            component = uieditfield(parent, "text", ...
                Value=string(value), Enable=labkit.app.internal.native.NativeAdapterValues.onOff(config.Enabled));
    end
    component.UserData = struct( ...
        "LayoutContainer", layoutContainer);
end

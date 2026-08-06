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
            policy = labkit.app.internal.native.NativeAdapterValues.layoutPolicy();
            valuePanel = uipanel(parent, BorderType="none", ...
                AutoResizeChildren="off");
            initialHeight = labkit.app.internal.native.NativeAdapterValues.readonlyHeight( ...
                value, policy.ReadonlyDefaultWidth, policy.ReadonlyFontSize);
            lines = labkit.app.internal.native.NativeAdapterValues.readonlyLines(value);
            component = uitextarea(valuePanel, Editable="off", ...
                Value=cellstr(lines), ...
                WordWrap="on", ...
                Position=[0 0 policy.ReadonlyDefaultWidth initialHeight], ...
                Enable=labkit.app.internal.native.NativeAdapterValues.onOff(config.Enabled));
            if isprop(component, "WordWrap")
                component.WordWrap = "on";
            end
        otherwise
            component = uieditfield(parent, "text", ...
                Value=string(value), Enable=labkit.app.internal.native.NativeAdapterValues.onOff(config.Enabled));
    end
    component.UserData = struct( ...
        "LayoutContainer", layoutContainer, ...
        "Readonly", config.Kind == "readonly", ...
        "NodeId", string(id));
    if config.Kind == "readonly" && isprop(component, "Tooltip")
        component.Tooltip = char(join( ...
            labkit.app.internal.native.NativeAdapterValues.readonlyLines(value), ...
            newline));
    end
end

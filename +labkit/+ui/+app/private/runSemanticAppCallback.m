% Private UI app helper. Expected caller: UI 3.0 semantic callback wrappers.
% Inputs are the current UI registry, control adapter, event payload, app
% callback, and control id. Side effects: runs the callback in app busy state.
function runSemanticAppCallback(ui, control, event, appCallback, id)
    if isempty(appCallback)
        return;
    end

    labkit.ui.app.runBusy(ui.figure, actionBusyMessage(id, control.props), ...
        @() appCallback(control, event), ...
        struct('freezeInteractions', false));
end

function message = actionBusyMessage(id, props)
    message = optionValue(props, 'busyMessage', "");
    if strlength(string(message)) == 0
        message = optionValue(props, 'label', id);
    end
    message = char(string(message));
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end

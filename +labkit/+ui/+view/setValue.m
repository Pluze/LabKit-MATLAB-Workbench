function setValue(ui, id, value)
%SETVALUE Set a UI 2.0 control value through the semantic registry.
%
% App-facing contract:
%   labkit.ui.view.setValue(ui, id, value)
%
% Inputs:
%   ui - UI registry returned by labkit.ui.app.create.
%   id - globally unique semantic control id.
%   value - value assigned to the control's primary value handle.
%
% Output:
%   None. Programmatic updates suppress callbacks only where the underlying
%   MATLAB component would otherwise call them synchronously.

    control = resolveControl(ui, id);
    if isfield(control, 'setValue') && isa(control.setValue, 'function_handle')
        control.setValue(value);
        return;
    end
    handle = controlValueHandle(control);
    if ~isprop(handle, 'Value') || isequaln(handle.Value, value)
        return;
    end
    callback = callbackProperty(handle);
    cleanupObj = suppressCallback(handle, callback);
    handle.Value = value;
    clear cleanupObj;
end

function callback = callbackProperty(handle)
    callback = struct('property', '', 'value', []);
    for name = {'ValueChangedFcn', 'ButtonPushedFcn'}
        prop = name{1};
        if isprop(handle, prop)
            callback.property = prop;
            callback.value = handle.(prop);
            return;
        end
    end
end

function cleanupObj = suppressCallback(handle, callback)
    if isempty(callback.property)
        cleanupObj = onCleanup(@() []);
        return;
    end
    handle.(callback.property) = [];
    cleanupObj = onCleanup(@() restoreCallback(handle, callback));
end

function restoreCallback(handle, callback)
    if ~isempty(handle) && isvalid(handle) && isprop(handle, callback.property)
        handle.(callback.property) = callback.value;
    end
end

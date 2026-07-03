% Expected caller: rhs_preview.definitionActions. Inputs are one UI dropdown control,
% candidate items, selected value, and enabled flag. Side effect updates the
% dropdown while suppressing its value-change callback.
function setDropDown(control, items, value, enabled)
%SETDROPDOWN Update an app dropdown without firing semantic callbacks.

    items = string(items(:)).';
    if isempty(items)
        items = "No channels available";
    end
    value = string(value);
    if ~any(items == value)
        value = items(1);
    end

    handle = control.handle;
    callback = handle.ValueChangedFcn;
    handle.ValueChangedFcn = [];
    cleanupObj = onCleanup(@() restoreCallback(handle, callback));
    handle.Items = cellstr(items);
    handle.Value = char(value);
    handle.Enable = onOff(enabled);
    clear cleanupObj;
end

function restoreCallback(handle, callback)
    if ~isempty(handle) && isvalid(handle)
        handle.ValueChangedFcn = callback;
    end
end

function text = onOff(value)
    if logical(value)
        text = 'on';
    else
        text = 'off';
    end
end

function setItems(ui, id, items)
%SETITEMS Replace selectable items for a UI 5 value control.
%
% App-facing contract:
%   labkit.ui.control.setItems(ui, id, items)
%
% Inputs:
%   ui - UI registry returned by labkit.ui.runtime.create.
%   id - semantic id for a control whose primary handle exposes Items.
%   items - nonempty cell array or string array of display values.
%
% Output:
%   None. The current selection is preserved when it remains valid;
%   otherwise the first new item is selected without firing the app callback.

    values = cellstr(string(items(:)));
    if isempty(values)
        error('labkit:ui:control:EmptyItems', ...
            'Selectable control items must not be empty.');
    end
    control = resolveControl(ui, id);
    handle = controlValueHandle(control);
    if ~isprop(handle, 'Items') || ~isprop(handle, 'Value')
        error('labkit:ui:control:NoItems', ...
            'Control "%s" does not expose selectable items.', control.id);
    end

    callback = [];
    if isprop(handle, 'ValueChangedFcn')
        callback = handle.ValueChangedFcn;
        handle.ValueChangedFcn = [];
    end
    cleanupObj = onCleanup(@() restoreCallback(handle, callback));
    previous = string(handle.Value);
    handle.Items = values;
    if any(string(values) == previous)
        handle.Value = char(previous);
    else
        handle.Value = values{1};
    end
    clear cleanupObj;
end

function restoreCallback(handle, callback)
    if ~isempty(handle) && isvalid(handle) && isprop(handle, 'ValueChangedFcn')
        handle.ValueChangedFcn = callback;
    end
end

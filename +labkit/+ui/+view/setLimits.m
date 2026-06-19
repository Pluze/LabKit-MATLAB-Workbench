function setLimits(ui, id, limits)
%SETLIMITS Set numeric limits for a UI 2.0 control.
%
% App-facing contract:
%   labkit.ui.view.setLimits(ui, id, limits)
%
% Inputs:
%   ui - UI registry returned by labkit.ui.app.create.
%   id - globally unique semantic control id.
%   limits - two-element increasing numeric vector.
%
% Output:
%   None. Controls with a current Value are clamped into the new limits while
%   their value-change callback is temporarily suppressed.

    limits = double(limits(:)).';
    if numel(limits) ~= 2 || any(~isfinite(limits)) || limits(1) >= limits(2)
        error('labkit:ui:view:InvalidLimits', ...
            'Limits must be a finite increasing two-element vector.');
    end

    control = resolveControl(ui, id);
    handles = limitsHandles(control);
    if isempty(handles)
        error('labkit:ui:view:NoLimits', ...
            'Control "%s" does not expose numeric Limits.', control.id);
    end

    for k = 1:numel(handles)
        handle = handles{k};
        callback = callbackProperty(handle);
        cleanupObj = suppressCallback(handle, callback);
        handle.Limits = limits;
        if isprop(handle, 'Value') && isnumeric(handle.Value) && isscalar(handle.Value)
            handle.Value = min(limits(2), max(limits(1), handle.Value));
        end
        clear cleanupObj;
    end
end

function handles = limitsHandles(control)
    allHandles = controlHandles(control);
    handles = cell(1, numel(allHandles));
    count = 0;
    for k = 1:numel(allHandles)
        handle = allHandles{k};
        if isprop(handle, 'Limits')
            count = count + 1;
            handles{count} = handle;
        end
    end
    handles = handles(1:count);
end

function callback = callbackProperty(handle)
    callback = struct('property', '', 'value', []);
    for name = {'ValueChangedFcn'}
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

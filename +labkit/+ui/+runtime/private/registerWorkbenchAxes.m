% Private UI runtime helper. Expected caller: buildWorkspace. Inputs are the app
% figure and preview axes handles. Side effects: records valid axes for
% framework utility commands and installs lightweight active-axes tracking
% without taking over existing app callbacks.
function registerWorkbenchAxes(fig, axesHandles)
    axesHandles = axesHandles(:).';
    existing = gobjects(1, 0);
    if isappdata(fig, 'labkitUiWorkbenchAxes')
        existing = getappdata(fig, 'labkitUiWorkbenchAxes');
        existing = existing(isvalid(existing));
    end
    allAxes = [existing, axesHandles];
    allAxes = allAxes(isvalid(allAxes));
    setappdata(fig, 'labkitUiWorkbenchAxes', uniqueHandles(allAxes));
    for k = 1:numel(axesHandles)
        ax = axesHandles(k);
        existingCallback = ax.ButtonDownFcn;
        set(ax, 'ButtonDownFcn', ...
            @(source,event) handleAxesButtonDown(fig, source, event, ...
            existingCallback));
    end
end

function handleAxesButtonDown(fig, ax, event, existingCallback)
    if ~isempty(ax) && isvalid(ax)
        setappdata(fig, 'labkitUiActiveAxes', ax);
    end
    invokeExistingCallback(existingCallback, ax, event);
end

function invokeExistingCallback(callback, source, event)
    if isempty(callback)
        return;
    end
    if isa(callback, 'function_handle')
        callback(source, event);
    elseif iscell(callback) && ~isempty(callback) && isa(callback{1}, 'function_handle')
        callback{1}(source, event, callback{2:end});
    end
end

function out = uniqueHandles(handles)
    out = gobjects(1, 0);
    for k = 1:numel(handles)
        if ~any(out == handles(k))
            out(end + 1) = handles(k);
        end
    end
end

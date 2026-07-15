function varargout = runBusy(fig, message, workFcn, opts)
%RUNBUSY Run synchronous GUI work while the whole app is busy.
%
% App-facing contract:
%   labkit.ui.runtime.runBusy(fig, "Writing outputs...", @() writeOutputs());
%   result = labkit.ui.runtime.runBusy(fig, "Computing result...", @() compute());
%
% Inputs:
%   fig - owning uifigure or figure. Empty or invalid figures are accepted;
%       the work callback still runs.
%   message - short busy message appended to the figure title while work runs.
%   workFcn - scalar function handle to run synchronously.
%   opts - optional struct. freezeInteractions controls whether figure-level
%       pointer, keyboard, click, motion, scroll, and graphics hit-testing are
%       temporarily disabled. Default true.
%
% Outputs:
%   varargout - outputs returned by workFcn. When no outputs are requested,
%       workFcn is called for side effects only.
%
% Behavior:
%   The helper marks the app busy, sets the figure pointer to "watch", and
%   appends a busy message to the window title. When freezeInteractions is true,
%   it also clears app-level pointer, keyboard, click, motion, and scroll
%   callbacks and turns graphics hit testing off where supported. It restores
%   previous state after success or failure and rethrows callback errors.
%
% Notes:
%   This helper is intended for synchronous callbacks that must block repeated
%   user actions. It intentionally avoids transient modal progress dialogs.
%   runBusy intentionally does not change control Enable states. App callbacks
%   may update their own button enabled/disabled logic while the work runs.

    if nargin < 3
        error('labkit:ui:runBusy:InvalidInput', ...
            'runBusy requires fig, message, and workFcn.');
    end
    if ~isa(workFcn, 'function_handle')
        error('labkit:ui:runBusy:InvalidCallback', ...
            'workFcn must be a function handle.');
    end

    if nargin < 4
        opts = struct();
    end

    validFig = isLiveHandle(fig);
    state = enterBusyState(fig, validFig, message, opts);
    cleanupObj = onCleanup(@() restoreBusyState(state));

    drawnow;
    if nargout == 0
        workFcn();
    else
        [varargout{1:nargout}] = workFcn();
    end
end

function state = enterBusyState(fig, validFig, message, opts)
    state = struct( ...
        'fig', fig, ...
        'validFig', validFig, ...
        'nameChanged', false, ...
        'oldName', '', ...
        'busyName', '', ...
        'pointerChanged', false, ...
        'oldPointer', '', ...
        'busyPointer', '', ...
        'callbackState', struct('property', {}, 'value', {}), ...
        'busyState', struct('hadValue', false, 'value', []), ...
        'hitState', struct('handle', {}, 'hitTest', {}, 'pickableParts', {}));

    if ~validFig
        return;
    end

    state = setBusyTitle(state, fig, message);
    state = setBusyPointer(state, fig);
    state.busyState = setBusyFlag(fig, true);
    if logical(optionValue(opts, 'freezeInteractions', true))
        state.callbackState = clearFigureInteractionCallbacks(fig);
        state.hitState = disableGraphicsHitTesting(fig);
    end
end

function state = setBusyTitle(state, fig, message)
    if ~isprop(fig, 'Name')
        return;
    end

    state.oldName = stripBusySuffix(fig.Name);
    text = char(string(message));
    if isempty(strtrim(text))
        text = 'Working';
    end
    state.busyName = sprintf('%s [Working: %s]', char(string(state.oldName)), text);
    fig.Name = state.busyName;
    state.nameChanged = true;
end

function name = stripBusySuffix(name)
    name = char(string(name));
    while true
        stripped = regexprep(name, '\s*\[Working: [^\]]*\]\s*$', '');
        if strcmp(stripped, name)
            return;
        end
        name = stripped;
    end
end

function state = setBusyPointer(state, fig)
    if ~isprop(fig, 'Pointer')
        return;
    end

    state.oldPointer = fig.Pointer;
    state.busyPointer = 'watch';
    try
        fig.Pointer = state.busyPointer;
        state.pointerChanged = true;
    catch
        state.pointerChanged = false;
    end
end

function callbackState = clearFigureInteractionCallbacks(fig)
    names = {'WindowButtonDownFcn', 'WindowButtonMotionFcn', ...
        'WindowButtonUpFcn', 'WindowScrollWheelFcn', 'WindowKeyPressFcn', ...
        'WindowKeyReleaseFcn'};
    callbackState = struct('property', {}, 'value', {});
    for k = 1:numel(names)
        name = names{k};
        if ~isprop(fig, name)
            continue;
        end
        entry = struct();
        entry.property = name;
        entry.value = fig.(name);
        callbackState(end+1) = entry;
        try
            fig.(name) = [];
        catch
        end
    end
end

function busyState = setBusyFlag(fig, value)
    key = 'labkitUiBusy';
    busyState = struct('hadValue', false, 'value', []);
    try
        busyState.hadValue = isappdata(fig, key);
        if busyState.hadValue
            busyState.value = getappdata(fig, key);
        end
        setappdata(fig, key, logical(value));
    catch
    end
end

function hitState = disableGraphicsHitTesting(fig)
    handles = liveDescendants(fig);
    hitState = struct('handle', {}, 'hitTest', {}, 'pickableParts', {});
    for k = 1:numel(handles)
        h = handles{k};
        if ~isLiveHandle(h) || (~isprop(h, 'HitTest') && ~isprop(h, 'PickableParts'))
            continue;
        end
        entry = struct('handle', h, 'hitTest', [], 'pickableParts', []);
        changed = false;
        if isprop(h, 'HitTest')
            try
                entry.hitTest = h.HitTest;
                h.HitTest = 'off';
                changed = true;
            catch
            end
        end
        if isprop(h, 'PickableParts')
            try
                entry.pickableParts = h.PickableParts;
                h.PickableParts = 'none';
                changed = true;
            catch
            end
        end
        if changed
            hitState(end+1) = entry;
        end
    end
end

function restoreBusyState(state)
    restoreHitTesting(state.hitState);
    restoreFigureCallbacks(state.fig, state.validFig, state.callbackState);
    restoreBusyFlag(state.fig, state.validFig, state.busyState);
    restorePointer(state.fig, state.validFig, state.oldPointer, ...
        state.busyPointer, state.pointerChanged);
    restoreTitle(state.fig, state.validFig, state.oldName, ...
        state.busyName, state.nameChanged);
    drawnow;
end

function restoreHitTesting(hitState)
    for k = numel(hitState):-1:1
        h = hitState(k).handle;
        if ~isLiveHandle(h)
            continue;
        end
        if isprop(h, 'HitTest') && ~isempty(hitState(k).hitTest)
            try
                h.HitTest = hitState(k).hitTest;
            catch
            end
        end
        if isprop(h, 'PickableParts') && ~isempty(hitState(k).pickableParts)
            try
                h.PickableParts = hitState(k).pickableParts;
            catch
            end
        end
    end
end

function restoreFigureCallbacks(fig, validFig, callbackState)
    if ~validFig || ~isLiveHandle(fig)
        return;
    end

    for k = numel(callbackState):-1:1
        name = callbackState(k).property;
        if ~isprop(fig, name)
            continue;
        end
        try
            fig.(name) = callbackState(k).value;
        catch
        end
    end
end

function restoreBusyFlag(fig, validFig, busyState)
    if ~validFig || ~isLiveHandle(fig)
        return;
    end

    key = 'labkitUiBusy';
    try
        if busyState.hadValue
            setappdata(fig, key, busyState.value);
        else
            rmappdata(fig, key);
        end
    catch
    end
end

function restorePointer(fig, validFig, oldPointer, busyPointer, pointerChanged)
    if ~validFig || ~pointerChanged || ~isLiveHandle(fig) || ~isprop(fig, 'Pointer')
        return;
    end
    if ~strcmp(char(string(fig.Pointer)), char(string(busyPointer)))
        return;
    end

    try
        fig.Pointer = oldPointer;
    catch
    end
end

function restoreTitle(fig, validFig, oldName, busyName, nameChanged)
    if ~validFig || ~nameChanged || ~isLiveHandle(fig) || ~isprop(fig, 'Name')
        return;
    end
    if ~strcmp(char(string(fig.Name)), char(string(busyName)))
        return;
    end

    try
        fig.Name = oldName;
    catch
    end
end

function handles = liveDescendants(fig)
    handles = {};
    if ~isLiveHandle(fig)
        return;
    end
    try
        values = findall(fig);
        handles = num2cell(values(:));
    catch
        handles = {};
    end
end

function tf = isLiveHandle(h)
    tf = ~isempty(h);
    if ~tf
        return;
    end
    try
        tf = all(isvalid(h));
    catch
        tf = false;
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end

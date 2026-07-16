function varargout = runBusy(fig, message, workFcn, opts)
%RUNBUSY Run synchronous GUI work while the whole app is busy.
%
% Usage:
%   labkit.ui.runtime.runBusy(fig, "Writing outputs...", @() writeOutputs());
%   result = labkit.ui.runtime.runBusy(fig, "Computing result...", @() compute());
%   result = labkit.ui.runtime.runBusy(fig, message, workFcn, opts)
%
% Inputs:
%   fig - Owning uifigure or figure. If it is empty, invalid, or already
%       deleted, workFcn still runs without changing a window.
%   message - Short status text appended to the figure title. Blank text is
%       displayed as "Working".
%   workFcn - Function handle called synchronously. Its outputs are returned
%       unchanged.
%   opts - Optional scalar struct described under Options.
%
% Outputs:
%   varargout - Outputs returned by workFcn. When no outputs are requested,
%       workFcn is called for side effects only.
%
% Options:
%   freezeInteractions - Logical scalar controlling temporary suppression of
%       figure pointer, keyboard, click, motion, and scroll callbacks and
%       graphics hit testing. Default: true.
%
% Description:
%   runBusy marks the figure busy, changes its pointer to "watch", appends the
%   message to its title, and runs workFcn. All changed callbacks, hit-testing
%   properties, appdata, title text, and pointer state are restored after either
%   success or failure. Callback errors are rethrown. The function does not
%   open a modal progress dialog and does not change any control's Enable
%   property, so the app can continue to present its own enabled-state logic.
%
% Typical Call:
%   result = labkit.ui.runtime.runBusy(fig, "Analyzing files...", ...
%       @() analyzeFiles(files), struct("freezeInteractions", true));

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

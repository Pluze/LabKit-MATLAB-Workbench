% Private UI app helper. Expected callers are labkit.ui.app.create and
% labkit.ui.app.run. Inputs are app figures, internal UI registry handles,
% messages, and runtime task callbacks. Side effects are limited to framework
% startup appdata, non-modal status UI, timer scheduling, and the startup busy
% flag used to gate callbacks during first-render initialization.
function varargout = startupLifecycle(fig, action, varargin)
    action = char(string(action));
    switch action
        case 'start'
            state = startState(fig, varargin{:});
            setState(fig, state);
        case 'update'
            state = updateState(fig, varargin{:});
            setState(fig, state);
        case 'defer'
            [state, taskTimer] = deferTask(fig, varargin{:});
            if ~isempty(state)
                setState(fig, state);
            end
            varargout{1} = taskTimer;
        case 'finish'
            state = requestFinish(fig, varargin{:});
            setState(fig, state);
        otherwise
            error('labkit:ui:startup:InvalidAction', ...
                'Unsupported startup lifecycle action "%s".', action);
    end
end

function state = startState(fig, ui, message)
    state = defaultState(fig);
    state.mainGrid = ui.main;
    state.panel = ui.startupStatusPanel;
    state.label = ui.startupStatusLabel;
    rememberHandles(fig, state);
    state.oldBusy = captureBusy(fig);
    setappdata(fig, 'labkitUiBusy', true);
    state = updateStateWithMessage(state, message, false);
end

function state = updateState(fig, message)
    state = getState(fig);
    if isempty(state)
        return;
    end
    state = updateStateWithMessage(state, message, false);
end

function [state, taskTimer] = deferTask(fig, message, workFcn)
    state = getState(fig);
    if isempty(state)
        state = defaultState(fig);
        state = restoreHandles(fig, state);
        state.oldBusy = captureBusy(fig);
        setappdata(fig, 'labkitUiBusy', true);
        state = updateStateWithMessage(state, message, true);
    else
        state = updateStateWithMessage(state, message, true);
    end
    taskId = state.nextTaskId;
    state.nextTaskId = state.nextTaskId + 1;
    state.pending = state.pending + 1;
    if startupTaskRunsInline()
        taskTimer = [];
        setState(fig, state);
        runDeferredTask(fig, taskTimer, message, workFcn);
        state = getState(fig);
        return;
    end
    taskTimer = timer( ...
        'ExecutionMode', 'singleShot', ...
        'StartDelay', startupTaskDelay(), ...
        'TimerFcn', @(source, ~) runDeferredTask(fig, source, message, workFcn));
    state.timers = [state.timers, taskTimer];
    start(taskTimer);
end

function state = requestFinish(fig, message)
    state = updateState(fig, message);
    if isempty(state)
        return;
    end
    state.finishRequested = true;
    state = completeIfReady(state);
end

function state = updateStateWithMessage(state, message, forceVisible)
    if nargin < 3
        forceVisible = false;
    end
    if isempty(state) || ~isLiveHandle(state.fig)
        return;
    end
    state.message = string(message);
    becameVisible = false;
    if shouldShowStatus(state, forceVisible)
        state = showStatus(state);
        becameVisible = state.visible;
    end
    if state.visible && isLiveHandle(state.label)
        state.label.Text = char(state.message);
    end
    if shouldFlushStatus(state, becameVisible)
        drawnow limitrate;
        state.statusFlushed = true;
    end
end

function tf = shouldShowStatus(state, forceVisible)
    tf = ~state.visible && ~startupStatusSuppressed() && ...
        (forceVisible || toc(state.startedAt) >= startupStatusDelay());
end

function state = showStatus(state)
    if ~isLiveHandle(state.panel) || ~isLiveHandle(state.mainGrid)
        return;
    end
    try
        heights = state.mainGrid.RowHeight;
        if numel(heights) >= 1
            heights{1} = 28;
            state.mainGrid.RowHeight = heights;
        end
        state.panel.Visible = 'on';
        state.visible = true;
        state.visibleAt = tic;
    catch
    end
end

function tf = shouldFlushStatus(state, becameVisible)
    tf = becameVisible || isFailureMessage(state.message) || ...
        (state.visible && ~state.statusFlushed);
end

function tf = isFailureMessage(message)
    tf = startsWith(lower(string(message)), "startup failed");
end

function runDeferredTask(fig, taskTimer, message, workFcn)
    if ~isLiveHandle(fig)
        cleanupTimer(taskTimer);
        return;
    end
    state = updateState(fig, message);
    setState(fig, state);
    try
        workFcn();
    catch ME
        state = getState(fig);
        state.failed = true;
        state.finishRequested = false;
        state = updateStateWithMessage(state, ...
            "Startup failed: " + string(ME.message), true);
        setState(fig, state);
        reportStartupException(fig, ME);
        cleanupFinishedTask(fig, taskTimer);
        return;
    end
    cleanupFinishedTask(fig, taskTimer);
end

function cleanupFinishedTask(fig, taskTimer)
    state = getState(fig);
    if isempty(state)
        cleanupTimer(taskTimer);
        return;
    end
    state.pending = max(0, state.pending - 1);
    state.timers = removeTimer(state.timers, taskTimer);
    state = completeIfReady(state);
    setState(fig, state);
    cleanupTimer(taskTimer);
end

function state = completeIfReady(state)
    if isempty(state) || state.failed || state.pending > 0 || ~state.finishRequested
        return;
    end
    state = hideStatus(state);
    restoreBusy(state.fig, state.oldBusy);
    if isLiveHandle(state.fig)
        rmappdata(state.fig, startupKey());
    end
    state = [];
end

function state = hideStatus(state)
    if state.visible && isLiveHandle(state.panel) && ...
            toc(state.visibleAt) < startupMinimumVisible()
        pause(startupMinimumVisible() - toc(state.visibleAt));
    end
    if isLiveHandle(state.panel)
        try
            state.panel.Visible = 'off';
        catch
        end
    end
    if isLiveHandle(state.mainGrid)
        try
            heights = state.mainGrid.RowHeight;
            if numel(heights) >= 1
                heights{1} = 0;
                state.mainGrid.RowHeight = heights;
            end
        catch
        end
    end
    state.visible = false;
end

function reportStartupException(fig, ME)
    try
        debug = getappdata(fig, 'labkitUiDebugContext');
        if isstruct(debug) && isfield(debug, 'reportException') && ...
                isa(debug.reportException, 'function_handle')
            debug.reportException('startup', 'Deferred startup failed', ME);
        end
    catch
    end
end

function state = defaultState(fig)
    state = struct();
    state.fig = fig;
    state.startedAt = tic;
    state.visible = false;
    state.visibleAt = tic;
    state.finishRequested = false;
    state.failed = false;
    state.pending = 0;
    state.nextTaskId = 1;
    state.timers = timer.empty;
    state.message = "";
    state.mainGrid = [];
    state.panel = [];
    state.label = [];
    state.statusFlushed = false;
    state.oldBusy = struct('hadValue', false, 'value', []);
end

function rememberHandles(fig, state)
    if ~isLiveHandle(fig)
        return;
    end
    handles = struct( ...
        'mainGrid', state.mainGrid, ...
        'panel', state.panel, ...
        'label', state.label);
    try
        setappdata(fig, 'labkitUiStartupHandles', handles);
    catch
    end
end

function state = restoreHandles(fig, state)
    if ~isLiveHandle(fig) || ~isappdata(fig, 'labkitUiStartupHandles')
        return;
    end
    try
        handles = getappdata(fig, 'labkitUiStartupHandles');
        state.mainGrid = handles.mainGrid;
        state.panel = handles.panel;
        state.label = handles.label;
    catch
    end
end

function busy = captureBusy(fig)
    busy = struct('hadValue', false, 'value', []);
    if ~isLiveHandle(fig)
        return;
    end
    try
        busy.hadValue = isappdata(fig, 'labkitUiBusy');
        if busy.hadValue
            busy.value = getappdata(fig, 'labkitUiBusy');
        end
    catch
    end
end

function restoreBusy(fig, busy)
    if ~isLiveHandle(fig)
        return;
    end
    try
        if busy.hadValue
            setappdata(fig, 'labkitUiBusy', busy.value);
        else
            rmappdata(fig, 'labkitUiBusy');
        end
    catch
    end
end

function state = getState(fig)
    state = [];
    if isLiveHandle(fig) && isappdata(fig, startupKey())
        state = getappdata(fig, startupKey());
    end
end

function setState(fig, state)
    if ~isempty(state) && isLiveHandle(fig)
        setappdata(fig, startupKey(), state);
    end
end

function timers = liveTimers(timers)
    keep = false(size(timers));
    for k = 1:numel(timers)
        try
            keep(k) = isvalid(timers(k));
        catch
            keep(k) = false;
        end
    end
    timers = timers(keep);
end

function timers = removeTimer(timers, taskTimer)
    timers = liveTimers(timers);
    keep = true(size(timers));
    for k = 1:numel(timers)
        try
            keep(k) = ~isequal(timers(k), taskTimer);
        catch
            keep(k) = true;
        end
    end
    timers = timers(keep);
end

function cleanupTimer(taskTimer)
    try
        if ~isempty(taskTimer) && isvalid(taskTimer)
            stop(taskTimer);
            delete(taskTimer);
        end
    catch
    end
end

function key = startupKey()
    key = 'labkitUiStartup';
end

function tf = startupStatusSuppressed()
    mode = lower(strtrim(string(getenv('LABKIT_GUI_TEST_MODE'))));
    tf = mode == "hidden" || mode == "minimized";
end

function tf = startupTaskRunsInline()
    mode = lower(strtrim(string(getenv('LABKIT_GUI_TEST_MODE'))));
    tf = mode == "hidden" || mode == "minimized";
end

function value = startupStatusDelay()
    value = 0.25;
end

function value = startupTaskDelay()
    value = 0.01;
end

function value = startupMinimumVisible()
    value = 0.35;
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

% Private UI app helper. Expected caller: UI 4.0 semantic callback wrappers.
% Inputs are the current UI registry, control adapter, event payload, app
% callback, and control id. Side effects: runs the callback in app busy state.
function runSemanticAppCallback(ui, control, event, appCallback, id)
    if isempty(appCallback)
        return;
    end

    if shouldDebounce(control)
        scheduleDebouncedCallback(ui, control, event, appCallback, id);
        return;
    end

    runCallbackNow(ui.figure, control, event, appCallback, id);
end

function runCallbackNow(fig, control, event, appCallback, id)
    labkit.ui.app.runBusy(fig, actionBusyMessage(id, control.props), ...
        @() appCallback(control, event), ...
        struct('freezeInteractions', false));
end

function scheduleDebouncedCallback(ui, control, event, appCallback, id)
    fig = ui.figure;
    key = debounceKey(id);
    clearExistingTimer(fig, key);
    delay = debounceDelaySec(control.props);
    if delay <= 0
        runCallbackNow(fig, control, event, appCallback, id);
        return;
    end
    state = struct( ...
        'control', control, ...
        'event', event, ...
        'appCallback', appCallback, ...
        'id', id, ...
        'timer', []);
    state.timer = timer( ...
        'ExecutionMode', 'singleShot', ...
        'StartDelay', delay, ...
        'TimerFcn', @(timerObj, ~) fireDebouncedCallback(fig, key, timerObj));
    setappdata(fig, key, state);
    start(state.timer);
end

function fireDebouncedCallback(fig, key, timerObj)
    if isempty(fig) || ~isvalid(fig) || ~isappdata(fig, key)
        deleteTimer(timerObj);
        return;
    end
    state = getappdata(fig, key);
    rmappdata(fig, key);
    deleteTimer(timerObj);
    if isempty(fig) || ~isvalid(fig)
        return;
    end
    if isFigureBusy(fig)
        scheduleDebouncedCallback(struct('figure', fig), state.control, ...
            state.event, state.appCallback, state.id);
        return;
    end
    runCallbackNow(fig, state.control, state.event, state.appCallback, state.id);
end

function clearExistingTimer(fig, key)
    if isempty(fig) || ~isvalid(fig) || ~isappdata(fig, key)
        return;
    end
    state = getappdata(fig, key);
    rmappdata(fig, key);
    if isstruct(state) && isfield(state, 'timer')
        deleteTimer(state.timer);
    end
end

function deleteTimer(timerObj)
    if isempty(timerObj)
        return;
    end
    try
        if isvalid(timerObj)
            stop(timerObj);
            delete(timerObj);
        end
    catch
    end
end

function tf = shouldDebounce(control)
    tf = isfield(control, 'kind') && any(strcmp(control.kind, ...
        {'field', 'rangeField', 'panner'}));
end

function delay = debounceDelaySec(props)
    delay = double(optionValue(props, 'debounceMs', 500)) / 1000;
    if ~isfinite(delay) || delay < 0
        delay = 0.500;
    end
end

function key = debounceKey(id)
    key = ['labkitUiSemanticDebounce_' matlab.lang.makeValidName(char(string(id)))];
end

function tf = isFigureBusy(fig)
    tf = false;
    try
        tf = isappdata(fig, 'labkitUiBusy') && ...
            logical(getappdata(fig, 'labkitUiBusy'));
    catch
        tf = false;
    end
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

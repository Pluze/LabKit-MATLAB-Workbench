function fig = run(def, request)
%RUN Launch a LabKit app definition through the framework runtime.
%
% App-facing contract:
%   fig = labkit.ui.app.run(def)
%   fig = labkit.ui.app.run(def, request)
%
% Inputs:
%   def - scalar struct returned by labkit.ui.app.define.
%   request - optional struct. The `debug` field may contain a LabKit debug
%       context created by labkit.ui.app.dispatchRequest.
%
% Output:
%   fig - created app figure.
%
% Runtime behavior:
%   The framework validates the definition, creates initial state, generates
%   semantic callbacks from action ids, builds the UI, stores runtime state,
%   calls render, and dispatches declared startup actions through private
%   startup readiness machinery.

    if nargin < 2
        request = struct();
    end
    validateAppDefinition(def);
    debug = requestDebugContext(request);
    state = createInitialState(def.initialState);
    actions = def.actions;
    callbacks = runtimeCallbacks(actions);
    spec = buildRuntimeSpec(def.spec, callbacks, state);
    ui = labkit.ui.app.create(spec, "debug", debug);
    fig = ui.figure;
    runtime = struct( ...
        'definition', def, ...
        'state', state, ...
        'actions', actions, ...
        'ui', ui, ...
        'debug', debug);
    setappdata(fig, runtimeKey(), runtime);
    invokeRuntimeRender(fig);
    dispatchStartup(fig, def.startup);
end

function debug = requestDebugContext(request)
    debug = [];
    if isstruct(request) && isfield(request, 'debug')
        debug = request.debug;
    elseif isstruct(request) && isfield(request, 'Debug')
        debug = request.Debug;
    end
end

function state = createInitialState(initialState)
    if isa(initialState, 'function_handle')
        state = initialState();
    else
        state = initialState;
    end
end

function callbacks = runtimeCallbacks(actions)
    callbacks = struct();
    ids = string(fieldnames(actions));
    for k = 1:numel(ids)
        id = ids(k);
        callbacks.(char(id)) = @(control, event) runtimeCallback( ...
            control, event, id);
    end
end

function runtimeCallback(control, event, id)
    fig = runtimeFigure(control, event);
    dispatchRuntimeAction(fig, id, control, event);
end

function fig = runtimeFigure(control, event)
    fig = [];
    if isstruct(event) && isfield(event, 'ui') && isstruct(event.ui) && ...
            isfield(event.ui, 'figure')
        fig = event.ui.figure;
    elseif isstruct(control) && isfield(control, 'handle')
        fig = ancestor(control.handle, 'figure');
    elseif ~isstruct(control)
        fig = ancestor(control, 'figure');
    end
end

function spec = buildRuntimeSpec(specFcn, callbacks, state)
    n = narginOf(specFcn);
    if n == 0
        spec = specFcn();
    elseif n == 1
        spec = specFcn(callbacks);
    else
        spec = specFcn(callbacks, state);
    end
end

function dispatchStartup(fig, startupIds)
    startupIds = string(startupIds);
    startupIds = startupIds(startupIds ~= "");
    if isempty(startupIds)
        return;
    end
    runtime = getRuntime(fig);
    message = "Preparing " + runtime.definition.title + "...";
    startupLifecycle(fig, 'defer', message, @() runStartupActions(fig, startupIds));
end

function runStartupActions(fig, startupIds)
    for k = 1:numel(startupIds)
        startupLifecycle(fig, 'update', "Starting " + startupIds(k) + "...");
        payload = struct('id', startupIds(k), 'kind', "startup", ...
            'source', "framework");
        dispatchRuntimeAction(fig, startupIds(k), [], payload);
    end
    startupLifecycle(fig, 'finish', "Ready.");
end

function dispatchRuntimeAction(fig, id, control, event)
    runtime = getRuntime(fig);
    id = string(id);
    field = char(id);
    if ~isfield(runtime.actions, field)
        error('labkit:ui:app:UnknownAction', ...
            'App definition action "%s" is not registered.', id);
    end
    payload = actionPayload(id, control, event);
    services = runtimeServices(fig, runtime);
    handler = runtime.actions.(field);
    [nextState, effects, hasState] = invokeAction(handler, ...
        runtime.state, payload, services);
    if hasState
        runtime.state = nextState;
        setappdata(fig, runtimeKey(), runtime);
    end
    applyRuntimeEffects(fig, effects);
    invokeRuntimeRender(fig);
end

function payload = actionPayload(id, control, event)
    payload = struct();
    payload.id = id;
    payload.kind = "action";
    payload.source = "user";
    payload.control = control;
    payload.event = event;
    if isstruct(event) && isfield(event, 'kind')
        payload.kind = string(event.kind);
    end
    if isstruct(event) && isfield(event, 'source')
        payload.source = string(event.source);
    end
end

function [nextState, effects, hasState] = invokeAction(handler, state, payload, services)
    n = nargoutOf(handler);
    effects = [];
    hasState = true;
    if n == 0
        handler(state, payload, services);
        nextState = state;
        hasState = false;
    elseif n == 1
        nextState = handler(state, payload, services);
    else
        [nextState, effects] = handler(state, payload, services);
    end
end

function invokeRuntimeRender(fig)
    runtime = getRuntime(fig);
    renderFcn = runtime.definition.render;
    services = runtimeServices(fig, runtime);
    n = narginOf(renderFcn);
    if n == 0
        renderFcn();
    elseif n == 1
        renderFcn(runtime.state);
    elseif n == 2
        renderFcn(runtime.state, runtime.ui);
    else
        renderFcn(runtime.state, runtime.ui, services);
    end
end

function services = runtimeServices(fig, runtime)
    services = struct();
    services.figure = fig;
    services.ui = runtime.ui;
    services.debug = runtime.debug;
    services.dispatch = @(id) dispatchRuntimeAction(fig, id, [], ...
        struct('id', string(id), 'kind', "programmatic", 'source', "app"));
end

function applyRuntimeEffects(fig, effects)
    if isempty(effects)
        return;
    end
    if isstruct(effects)
        for k = 1:numel(effects)
            applyOneEffect(fig, effects(k));
        end
    elseif iscell(effects)
        for k = 1:numel(effects)
            applyRuntimeEffects(fig, effects{k});
        end
    end
end

function applyOneEffect(fig, effect)
    if ~isfield(effect, 'type')
        return;
    end
    switch string(effect.type)
        case "logDebug"
            runtime = getRuntime(fig);
            if isstruct(runtime.debug) && isfield(runtime.debug, 'append')
                runtime.debug.append(string(effect.message));
            end
        case "alert"
            titleText = "LabKit";
            if isfield(effect, 'title')
                titleText = effect.title;
            end
            labkit.ui.app.showAlert(fig, string(effect.message), titleText);
        case "setBusy"
            setappdata(fig, 'labkitUiBusy', true);
        case "clearBusy"
            if isappdata(fig, 'labkitUiBusy')
                rmappdata(fig, 'labkitUiBusy');
            end
    end
end

function runtime = getRuntime(fig)
    if isempty(fig) || ~isvalid(fig) || ~isappdata(fig, runtimeKey())
        error('labkit:ui:app:MissingRuntime', ...
            'The figure does not have a LabKit app runtime.');
    end
    runtime = getappdata(fig, runtimeKey());
end

function key = runtimeKey()
    key = 'labkitUiAppRuntime';
end

function n = narginOf(fcn)
    n = nargin(fcn);
    if n < 0
        n = 3;
    end
end

function n = nargoutOf(fcn)
    n = nargout(fcn);
    if n < 0
        n = 2;
    end
end

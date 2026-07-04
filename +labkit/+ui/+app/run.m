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
%   calls render, dispatches declared startup actions, records phase timings,
%   reports action exceptions through debug diagnostics, and dispatches
%   declared hydration actions through private startup readiness machinery.

    if nargin < 2
        request = struct();
    end
    validateAppDefinition(def);
    debug = requestDebugContext(request);
    state = createInitialState(def.initialState);
    actions = def.actions;
    callbacks = runtimeCallbacks(actions);
    spec = buildRuntimeSpec(def, callbacks, state);
    ui = labkit.ui.app.create(spec, "debug", debug);
    fig = ui.figure;
    runtime = struct( ...
        'definition', def, ...
        'state', state, ...
        'actions', actions, ...
        'ui', ui, ...
        'debug', debug);
    setappdata(fig, appRuntimeKey(), runtime);
    invokeRuntimeRender(fig);
    dispatchStartup(fig, def.startup, def.hydrate);
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

function spec = buildRuntimeSpec(def, callbacks, state)
    specFcn = def.spec;
    n = narginOf(specFcn);
    if n == 0
        spec = specFcn();
    elseif n == 1
        spec = specFcn(callbacks);
    else
        spec = specFcn(callbacks, state);
    end
    spec.props.utilities = def.utilities;
end

function dispatchStartup(fig, startupIds, hydrateIds)
    startupIds = string(startupIds);
    startupIds = startupIds(startupIds ~= "");
    if isempty(startupIds)
        dispatchHydration(fig, hydrateIds);
        return;
    end
    runtime = getRuntime(fig);
    message = "Preparing " + runtime.definition.title + "...";
    startupLifecycle(fig, 'defer', message, ...
        @() runStartupActions(fig, startupIds, hydrateIds));
end

function runStartupActions(fig, startupIds, hydrateIds)
    for k = 1:numel(startupIds)
        startupLifecycle(fig, 'update', "Starting " + startupIds(k) + "...");
        payload = struct('id', startupIds(k), 'kind', "startup", ...
            'source', "framework");
        dispatchRuntimeAction(fig, startupIds(k), [], payload);
    end
    startupLifecycle(fig, 'finish', "Ready.");
    dispatchHydration(fig, hydrateIds);
end

function dispatchHydration(fig, hydrateIds)
    hydrateIds = string(hydrateIds);
    hydrateIds = hydrateIds(hydrateIds ~= "");
    if isempty(hydrateIds)
        return;
    end
    runtime = getRuntime(fig);
    message = "Hydrating " + runtime.definition.title + "...";
    startupLifecycle(fig, 'defer', message, ...
        @() runHydrationActions(fig, hydrateIds));
end

function runHydrationActions(fig, hydrateIds)
    for k = 1:numel(hydrateIds)
        startupLifecycle(fig, 'update', "Hydrating " + hydrateIds(k) + "...");
        payload = struct('id', hydrateIds(k), 'kind', "hydrate", ...
            'source', "framework");
        dispatchRuntimeAction(fig, hydrateIds(k), [], payload);
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
    startedAt = tic;
    try
        services = runtimeServices(fig, runtime);
        handler = runtime.actions.(field);
        [nextState, effects, hasState] = invokeAction(handler, ...
            runtime.state, payload, services);
        if hasState
            runtime.state = nextState;
            setappdata(fig, appRuntimeKey(), runtime);
        end
        applyRuntimeEffects(fig, effects);
        invokeRuntimeRender(fig);
    catch ME
        appendPhaseTiming(fig, payload, "failed", toc(startedAt), ME);
        reportRuntimeException(fig, payload, ME);
        rethrow(ME);
    end
    appendPhaseTiming(fig, payload, "completed", toc(startedAt), []);
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
    services.dispatch = @(id, varargin) dispatchProgrammaticAction( ...
        fig, id, varargin{:});
end

function dispatchProgrammaticAction(fig, id, event)
    if nargin < 3
        event = struct();
    end
    if isstruct(event)
        event.id = string(id);
        if ~isfield(event, 'kind')
            event.kind = "programmatic";
        end
        if ~isfield(event, 'source')
            event.source = "app";
        end
    else
        event = struct('id', string(id), 'kind', "programmatic", ...
            'source', "app", 'value', event);
    end
    dispatchRuntimeAction(fig, id, [], event);
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

function appendPhaseTiming(fig, payload, status, elapsedSeconds, exception)
    if isempty(fig) || ~isvalid(fig)
        return;
    end
    record = struct();
    record.kind = string(payload.kind);
    record.id = string(payload.id);
    record.source = string(payload.source);
    record.status = string(status);
    record.elapsedSeconds = elapsedSeconds;
    if nargin >= 5 && isa(exception, 'MException')
        record.errorIdentifier = string(exception.identifier);
        record.errorMessage = string(exception.message);
    else
        record.errorIdentifier = "";
        record.errorMessage = "";
    end
    key = phaseTimingKey();
    if isappdata(fig, key)
        records = getappdata(fig, key);
        records(end + 1) = record;
    else
        records = record;
    end
    setappdata(fig, key, records);
    traceRuntimePhase(fig, record);
end

function traceRuntimePhase(fig, record)
    try
        runtime = getRuntime(fig);
        debug = runtime.debug;
        if isstruct(debug) && isfield(debug, 'trace') && ...
                isa(debug.trace, 'function_handle')
            debug.trace(sprintf(['runtime phase kind=%s id=%s status=%s ' ...
                'elapsed=%.6f'], char(record.kind), char(record.id), ...
                char(record.status), record.elapsedSeconds));
        end
    catch
    end
end

function reportRuntimeException(fig, payload, exception)
    try
        runtime = getRuntime(fig);
        debug = runtime.debug;
        if isstruct(debug) && isfield(debug, 'reportException') && ...
                isa(debug.reportException, 'function_handle')
            debug.reportException('runtime', ...
                sprintf('%s action %s failed', char(payload.kind), ...
                char(payload.id)), exception);
        end
    catch
    end
end

function runtime = getRuntime(fig)
    if isempty(fig) || ~isvalid(fig) || ~isappdata(fig, appRuntimeKey())
        error('labkit:ui:app:MissingRuntime', ...
            'The figure does not have a LabKit app runtime.');
    end
    runtime = getappdata(fig, appRuntimeKey());
end

function key = phaseTimingKey()
    key = 'labkitUiAppRuntimePhases';
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

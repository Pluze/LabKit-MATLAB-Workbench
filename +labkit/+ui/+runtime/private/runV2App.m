% Private UI runtime helper. Expected caller: runAppDefinition for a V2
% definition. Inputs are a validated definition and request. Output is the app
% figure. Side effects create the workbench, install one FIFO event queue,
% commit canonical state/presentation transactions, and own runtime resources.
function fig = runV2App(def, request)
    debug = requestDebugContext(request);
    progressReporter = startupProgressReporter(request);
    reportStartupProgress(progressReporter, "Creating app state...");
    state = createV2State(def);
    callbacks = runtimeCallbacks(def.actions);
    bindingCallback = @dispatchBindingCallback;
    reportStartupProgress(progressReporter, "Preparing app layout...");
    [layout, bindings] = prepareV2Layout( ...
        def, callbacks, state, bindingCallback);
    reportStartupProgress(progressReporter, "Building app shell...");
    ui = buildRuntimeWorkbench(layout, debug, progressReporter);
    fig = ui.figure;
    runtime = struct( ...
        "definition", def, ...
        "state", state, ...
        "actions", def.actions, ...
        "ui", ui, ...
        "debug", debug, ...
        "request", request, ...
        "bindings", bindings, ...
        "queue", {{}}, ...
        "processing", false, ...
        "resources", emptyResources(), ...
        "resourceListener", [], ...
        "interactionHub", [], ...
        "document", createV2DocumentState(), ...
        "lastPresentation", struct(), ...
        "metrics", struct("stateCommits", 0, ...
            "presentationCommits", 0, "eventsCompleted", 0));
    setappdata(fig, appRuntimeKey(), runtime);
    installResourceCleanup(fig);
    runtime = getAppRuntime(fig);
    runtime.interactionHub = v2FigureInteractionHub( ...
        ui, @(event) enqueueEvent(fig, event), ...
        @(target) disposeInteractionsForTarget(fig, target));
    setappdata(fig, appRuntimeKey(), runtime);
    v2ResourceRegistry(fig, "set", "figure", ...
        "interactionHub", runtime.interactionHub, ...
        @(hub) hub.delete());
    startupLifecycle(fig, 'update', "Preparing first view...");
    presentation = commitV2Presentation(getAppRuntime(fig), state);
    runtime = getAppRuntime(fig);
    runtime.lastPresentation = presentation;
    runtime.metrics.presentationCommits = 1;
    setappdata(fig, appRuntimeKey(), runtime);
    startupLifecycle(fig, 'update', "Running startup actions...");
    dispatchStart(fig, def.start);
    dispatchDebugSample(fig, def.debugSample);
    restoreRequestedRecovery(fig, request);
    startupLifecycle(fig, 'finish', "Ready.");

    function dispatchBindingCallback(control, event, path, eventId)
        canonical = canonicalEvent(eventId, control.id, event, "user");
        canonical.meta.bindingPath = path;
        enqueueEvent(fig, canonical);
    end
end

function restoreRequestedRecovery(fig, request)
    runtime = getAppRuntime(fig);
    candidate = discoverV2RecoveryFile(runtime.definition, request);
    if strlength(candidate) > 0
        setappdata(fig, 'labkitV2RecoveryCandidate', candidate);
    end
    requested = "";
    if isstruct(request) && isfield(request, 'recoveryFile')
        requested = string(request.recoveryFile);
    elseif isstruct(request) && isfield(request, 'recover') && ...
            logical(request.recover)
        requested = candidate;
    end
    if strlength(requested) == 0
        return;
    end
    restoreV2Project(fig, requested, true);
end

function disposeInteractionsForTarget(fig, target)
    ids = v2ResourceRegistry(fig, "listIds", "interaction");
    for k = 1:numel(ids)
        controlled = v2ResourceRegistry(fig, "get", ...
            "interaction", ids(k));
        if ~isempty(controlled) && isfield(controlled, 'spec') && ...
                any(controlled.spec.Targets == string(target))
            v2ResourceRegistry(fig, "remove", "interaction", ids(k));
        end
    end
end

function callbacks = runtimeCallbacks(actions)
    callbacks = struct();
    ids = string(fieldnames(actions));
    for k = 1:numel(ids)
        id = ids(k);
        callbacks.(char(id)) = @(control, event) dispatchUiEvent( ...
            control, event, id);
    end
end

function dispatchUiEvent(control, event, id)
    fig = runtimeFigure(control, event);
    target = id;
    if isstruct(control) && isfield(control, 'id')
        target = string(control.id);
    end
    enqueueEvent(fig, canonicalEvent(id, target, event, "user"));
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

function event = canonicalEvent(id, target, sourceEvent, source)
    event = struct("id", string(id), "source", string(source), ...
        "target", string(target), "value", [], "meta", struct());
    if isstruct(sourceEvent)
        if isfield(sourceEvent, 'value')
            event.value = sourceEvent.value;
        end
        event.meta.original = removeRuntimeFields(sourceEvent);
    elseif ~isempty(sourceEvent)
        event.value = sourceEvent;
    end
end

function value = removeRuntimeFields(value)
    for field = ["ui", "rawEvent"]
        name = char(field);
        if isfield(value, name)
            value = rmfield(value, name);
        end
    end
end

function dispatchStart(fig, start)
    if isempty(start)
        return;
    end
    event = canonicalEvent("start", "runtime", [], "startup");
    if isa(start, 'function_handle')
        event.meta.startHandler = start;
    else
        event.id = string(start);
    end
    enqueueEvent(fig, event);
end

function dispatchDebugSample(fig, writer)
    if isempty(writer)
        return;
    end
    runtime = getAppRuntime(fig);
    if ~isstruct(runtime.debug) || ~isfield(runtime.debug, 'enabled') || ...
            ~logical(runtime.debug.enabled)
        return;
    end
    event = canonicalEvent("debugSample", "runtime", [], "startup");
    event.meta.startHandler = ...
        @(state, ~, services) writeDebugSample(state, services, writer);
    enqueueEvent(fig, event);
end

function state = writeDebugSample(state, services, writer)
    services.debug.trace('Runtime debug sample generation enabled.');
    state = services.workflow.log(state, ...
        "Debug sample generation enabled.");
    try
        pack = writer(services.debug);
        if isstruct(pack) && isfield(pack, 'sampleFolder')
            state = services.workflow.log(state, ...
                "Debug sample files: " + string(pack.sampleFolder));
        end
        if isstruct(pack) && isfield(pack, 'outputFolder')
            state = services.workflow.log(state, ...
                "Debug output folder: " + string(pack.outputFolder));
        end
    catch ME
        services.diagnostics.report('Debug sample setup failed', ME);
        state = services.workflow.log(state, ...
            "Debug sample setup failed: " + ME.message);
    end
end

function enqueueEvent(fig, event)
    event = normalizeDispatchedEvent(event);
    runtime = getAppRuntime(fig);
    runtime.queue{end + 1} = event;
    if runtime.processing
        setappdata(fig, appRuntimeKey(), runtime);
        return;
    end
    runtime.processing = true;
    setappdata(fig, appRuntimeKey(), runtime);
    drainQueue(fig);
end

function drainQueue(fig)
    try
        while true
            runtime = getAppRuntime(fig);
            if isempty(runtime.queue)
                runtime.processing = false;
                setappdata(fig, appRuntimeKey(), runtime);
                return;
            end
            event = runtime.queue{1};
            runtime.queue(1) = [];
            setappdata(fig, appRuntimeKey(), runtime);
            processEvent(fig, event);
        end
    catch ME
        if ~isempty(fig) && isvalid(fig) && isappdata(fig, appRuntimeKey())
            runtime = getappdata(fig, appRuntimeKey());
            runtime.processing = false;
            runtime.queue = {};
            setappdata(fig, appRuntimeKey(), runtime);
        end
        rethrow(ME);
    end
end

function processEvent(fig, event)
    runtime = getAppRuntime(fig);
    previous = runtime.state;
    startedAt = tic;
    try
        next = applyBinding(previous, event);
        services = buildV2RuntimeServices(fig, runtime, ...
            @(event, varargin) dispatchProgrammatic( ...
            fig, event, varargin{:}));
        handler = eventHandler(runtime, event);
        if ~isempty(handler)
            next = invokeHandler(handler, next, event, services);
        end
        validateV2State(next, runtime.definition);
        latest = getAppRuntime(fig);
        latest.state = next;
        setappdata(fig, appRuntimeKey(), latest);
        presentation = commitV2Presentation( ...
            latest, next, event.source == "interaction");
        latest = getAppRuntime(fig);
        latest.lastPresentation = presentation;
        latest.metrics.stateCommits = latest.metrics.stateCommits + 1;
        latest.metrics.presentationCommits = ...
            latest.metrics.presentationCommits + 1;
        latest.metrics.eventsCompleted = latest.metrics.eventsCompleted + 1;
        if event.source ~= "startup" && ...
                ~isequaln(previous.project, next.project)
            latest.document.dirty = true;
            latest.document.revision = latest.document.revision + uint64(1);
        end
        setappdata(fig, appRuntimeKey(), latest);
        updateV2DocumentTitle(fig);
        if latest.document.dirty
            scheduleV2Autosave(fig);
        end
        v2ResourceRegistry(fig, "clearScope", "event");
        appendPhaseTiming(fig, event, "completed", toc(startedAt), []);
    catch ME
        if ~isempty(fig) && isvalid(fig) && isappdata(fig, appRuntimeKey())
            latest = getappdata(fig, appRuntimeKey());
            latest.state = previous;
            setappdata(fig, appRuntimeKey(), latest);
            v2ResourceRegistry(fig, "clearScope", "event");
            restorePresentation( ...
                fig, previous, event.source == "interaction");
        end
        appendPhaseTiming(fig, event, "failed", toc(startedAt), ME);
        reportRuntimeException(fig, event, ME);
        rethrow(ME);
    end
end

function next = applyBinding(state, event)
    next = state;
    if ~isfield(event.meta, 'bindingPath')
        return;
    end
    path = string(event.meta.bindingPath);
    previous = valueAtPath(state, path);
    value = normalizeBoundValue(event.value, previous);
    next = setValueAtPath(next, split(path, "."), value);
end

function value = normalizeBoundValue(value, fallback)
    if isnumeric(fallback) && isscalar(fallback)
        candidate = double(value);
        if ~(isnumeric(candidate) && isscalar(candidate) && isfinite(candidate))
            value = fallback;
        else
            value = candidate;
        end
    end
end

function value = valueAtPath(state, path)
    value = state;
    parts = split(path, ".");
    for k = 1:numel(parts)
        value = value.(char(parts(k)));
    end
end

function value = setValueAtPath(value, parts, replacement)
    field = char(parts(1));
    if numel(parts) == 1
        value.(field) = replacement;
    else
        value.(field) = setValueAtPath(value.(field), parts(2:end), replacement);
    end
end

function handler = eventHandler(runtime, event)
    handler = [];
    if isfield(event.meta, 'startHandler')
        handler = event.meta.startHandler;
        return;
    end
    if strlength(event.id) == 0
        return;
    end
    field = char(event.id);
    if ~isfield(runtime.actions, field)
        error('labkit:ui:runtime:UnknownAction', ...
            'App definition action "%s" is not registered.', event.id);
    end
    handler = runtime.actions.(field);
end

function next = invokeHandler(handler, state, event, services)
    count = nargout(handler);
    if count == 0
        handler(state, event, services);
        next = state;
    else
        next = handler(state, event, services);
    end
end

function dispatchProgrammatic(fig, event, varargin)
    if isstruct(event)
        canonical = event;
        if ~isfield(canonical, 'source')
            canonical.source = "service";
        end
    else
        value = [];
        if ~isempty(varargin)
            value = varargin{1};
        end
        canonical = canonicalEvent(string(event), "runtime", value, "service");
    end
    enqueueEvent(fig, canonical);
end

function event = normalizeDispatchedEvent(event)
    if ~isstruct(event) || ~isscalar(event)
        error('labkit:ui:runtime:InvalidEvent', ...
            'Runtime events must be scalar structs.');
    end
    defaults = struct("id", "", "source", "service", "target", "runtime", ...
        "value", [], "meta", struct());
    fields = fieldnames(defaults);
    for k = 1:numel(fields)
        field = fields{k};
        if ~isfield(event, field)
            event.(field) = defaults.(field);
        end
    end
    event.id = string(event.id);
    event.source = string(event.source);
    event.target = string(event.target);
    if ~isscalar(event.id) || ~isscalar(event.source) || ~isscalar(event.target) || ...
            ~isstruct(event.meta) || ~isscalar(event.meta)
        error('labkit:ui:runtime:InvalidEvent', ...
            'Event id, source, and target must be scalar text and meta a scalar struct.');
    end
end

function restorePresentation(fig, state, preserveView)
    try
        runtime = getAppRuntime(fig);
        presentation = commitV2Presentation(runtime, state, preserveView);
        runtime = getAppRuntime(fig);
        runtime.lastPresentation = presentation;
        setappdata(fig, appRuntimeKey(), runtime);
    catch
    end
end

function installResourceCleanup(fig)
    try
        listener = addlistener(fig, 'ObjectBeingDestroyed', ...
            @(~, ~) v2ResourceRegistry(fig, "clearAll"));
        runtime = getAppRuntime(fig);
        runtime.resourceListener = listener;
        setappdata(fig, appRuntimeKey(), runtime);
    catch
    end
end

function debug = requestDebugContext(request)
    debug = [];
    if isstruct(request) && isfield(request, 'debug')
        debug = request.debug;
    elseif isstruct(request) && isfield(request, 'Debug')
        debug = request.Debug;
    end
end

function appendPhaseTiming(fig, event, status, elapsedSeconds, exception)
    record = struct("kind", string(event.source), "id", string(event.id), ...
        "source", string(event.source), "status", string(status), ...
        "elapsedSeconds", elapsedSeconds, "errorIdentifier", "", ...
        "errorMessage", "");
    if isa(exception, 'MException')
        record.errorIdentifier = string(exception.identifier);
        record.errorMessage = string(exception.message);
    end
    key = 'labkitUiAppRuntimePhases';
    if isappdata(fig, key)
        records = getappdata(fig, key);
        records(end + 1) = record;
    else
        records = record;
    end
    setappdata(fig, key, records);
end

function reportRuntimeException(fig, event, exception)
    try
        runtime = getAppRuntime(fig);
        if isstruct(runtime.debug) && isfield(runtime.debug, 'reportException')
            runtime.debug.reportException('runtime', ...
                sprintf('%s event %s failed', char(event.source), ...
                char(event.id)), exception);
        end
    catch
    end
end

function resources = emptyResources()
    resources = struct("scope", {}, "id", {}, "value", {}, ...
        "cleanup", {}, "disposed", {});
end

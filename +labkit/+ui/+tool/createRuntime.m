function runtime = createRuntime(ax, opts)
%CREATERUNTIME Create a runtime that owns image-axes interaction sessions.
%
% Usage:
%   runtime = labkit.ui.tool.createRuntime(ax, ...
%       struct('figure', fig, 'defaultScrollFcn', @onPreviewScroll));
%   session = runtime.createSession(struct( ...
%       'name', 'curveEditor', ...
%       'onPointerDown', @onPointerDown, ...
%       'onScroll', @onScroll, ...
%       'installScrollWheel', true));
%
% The runtime is the public owner for pointer, drag, scroll, and hit-test sessions.

%
% Inputs:
%   ax - UI axes used by image tools.
%   opts - optional struct.
%
% Options:
%   figure - owning figure, default ancestor(ax, 'figure').
%   defaultScrollFcn - app-default scroll callback, default [].
%   defaultScrollTargets - handles that receive default scroll events,
%                          default ax.
%   scrollScope - "targets" (default) or "figure". "targets" gates scroll
%                 callbacks to the declared handles and their children.
%   onInteractionChanged - callback(active, name), default [].
%   onTrace - callback(message), default []. Receives verbose debug trace
%             messages for callback ownership and session lifecycle.
%
% Returned runtime API:
%   axes(), figure(), setDefaultScrollFcn(fcn), setDefaultScrollTargets(h),
%   installDefaultCallbacks(), setTraceCallback(fcn), createSession(spec),
%   isInteractionActive(), and delete().
%
% Session spec fields:
%   name - descriptive char/string name, default "interaction".
%   onPointerDown - callback installed on the axes/background while active.
%   onScroll - callback installed on the figure while active when enabled.
%   installScrollWheel - logical, default true. False leaves the runtime
%                        default scroll callback active during the session.
%   scrollTargets - handles that receive session scroll events. Defaults to
%                   the runtime axes plus active background/graphics handles.
%   scrollScope - "targets" (default) or "figure".
%
% Session API:
%   activate(), deactivate(), isActive(), setBackground(handle),
%   setGraphics(handles), captureDrag(motionFcn, releaseFcn), releaseDrag(),
%   refresh(), and delete().
%
% The runtime owns axes-level image-tool callback lifecycle. Apps register
% default behavior through this runtime instead of mutating figure/axes
% pointer callbacks directly. Target misses are passed to the scroll callback
% that existed before the runtime was installed, allowing the framework
% previewArea navigator or other fallbacks to keep working outside the tool's
% declared targets. Layout resize helpers remain separate shell behavior and
% do not use this runtime.

    if nargin < 2
        opts = struct();
    end

    key = imageAxesRuntimeAppdataKey();
    if isValidHandle(ax) && isappdata(ax, key)
        runtime = getappdata(ax, key);
        if isstruct(runtime)
            if isfield(opts, 'figure')
                runtime.setFigure(opts.figure);
            end
            if isfield(opts, 'defaultScrollFcn')
                runtime.setDefaultScrollFcn(opts.defaultScrollFcn);
            end
            if isfield(opts, 'defaultScrollTargets')
                runtime.setDefaultScrollTargets(opts.defaultScrollTargets);
            end
            if isfield(opts, 'scrollScope')
                runtime.setScrollScope(opts.scrollScope);
            end
            if isfield(opts, 'onTrace')
                runtime.setTraceCallback(opts.onTrace);
            end
            runtime.installDefaultCallbacks();
            return;
        end
    end

    state = struct();
    state.ax = ax;
    state.fig = optionValue(opts, 'figure', ancestor(ax, 'figure'));
    state.defaultScrollFcn = optionValue(opts, 'defaultScrollFcn', []);
    state.defaultScrollTargets = normalizeHandles( ...
        optionValue(opts, 'defaultScrollTargets', ax));
    state.defaultScrollScope = scrollScopeValue(optionValue(opts, ...
        'scrollScope', 'targets'));
    state.fallbackScrollFcn = currentScrollFcn(state.fig);
    state.activeToken = [];
    state.activeName = "";
    state.activeDeactivate = [];
    state.activeScrollToken = [];
    state.onInteractionChanged = optionValue(opts, 'onInteractionChanged', []);
    state.onTrace = optionValue(opts, 'onTrace', []);

    runtime = struct();
    runtime.axes = @runtimeAxes;
    runtime.figure = @runtimeFigure;
    runtime.setFigure = @setFigure;
    runtime.setDefaultScrollFcn = @setDefaultScrollFcn;
    runtime.setDefaultScrollTargets = @setDefaultScrollTargets;
    runtime.setScrollScope = @setScrollScope;
    runtime.setTraceCallback = @setTraceCallback;
    runtime.installDefaultCallbacks = @installDefaultCallbacks;
    runtime.createSession = @createSession;
    runtime.isInteractionActive = @isInteractionActive;
    runtime.delete = @deleteRuntime;

    if isValidHandle(ax)
        setappdata(ax, key, runtime);
    end
    installDefaultCallbacks();

    function out = runtimeAxes()
        out = state.ax;
    end

    function out = runtimeFigure()
        out = state.fig;
    end

    function setFigure(fig)
        state.fig = fig;
        state.fallbackScrollFcn = currentScrollFcn(state.fig);
        installDefaultCallbacks();
    end

    function setDefaultScrollFcn(fcn)
        state.defaultScrollFcn = fcn;
        trace('default scroll callback updated');
        installDefaultCallbacks();
    end

    function setDefaultScrollTargets(handles)
        state.defaultScrollTargets = normalizeHandles(handles);
        trace(sprintf('default scroll targets updated: %d', ...
            numel(state.defaultScrollTargets)));
        installDefaultCallbacks();
    end

    function setScrollScope(scope)
        state.defaultScrollScope = scrollScopeValue(scope);
        trace(sprintf('default scroll scope updated: %s', ...
            char(state.defaultScrollScope)));
        installDefaultCallbacks();
    end

    function setTraceCallback(fcn)
        state.onTrace = fcn;
    end

    function installDefaultCallbacks()
        if isValidHandle(state.ax)
            labkit.ui.tool.enableAxesPopout(state.ax);
        end
        if ~isValidHandle(state.fig) || ~isempty(state.activeScrollToken)
            return;
        end
        if isempty(state.defaultScrollFcn)
            state.fig.WindowScrollWheelFcn = state.fallbackScrollFcn;
            trace('installed fallback scroll callback');
        else
            state.fig.WindowScrollWheelFcn = @onDefaultScroll;
            trace('installed runtime default scroll callback');
        end
    end

    function onDefaultScroll(src, evt)
        if shouldDispatchScroll(state.fig, state.defaultScrollTargets, ...
                state.defaultScrollScope)
            state.defaultScrollFcn(src, evt);
        else
            callFallbackScroll(src, evt);
        end
    end

    function tf = isInteractionActive()
        tf = ~isempty(state.activeToken);
    end

    function deleteRuntime()
        trace('delete runtime');
        if ~isempty(state.activeDeactivate)
            state.activeDeactivate();
        end
        if isValidHandle(state.fig)
            state.fig.WindowScrollWheelFcn = state.fallbackScrollFcn;
            state.fig.WindowButtonMotionFcn = '';
            state.fig.WindowButtonUpFcn = '';
        end
        if isValidHandle(state.ax)
            state.ax.ButtonDownFcn = [];
            if isappdata(state.ax, key)
                rmappdata(state.ax, key);
            end
        end
    end

    function session = createSession(spec)
        if nargin < 1
            spec = struct();
        end

        sessionState = struct();
        sessionState.token = nextInteractionToken();
        sessionState.name = string(optionValue(spec, 'name', 'interaction'));
        sessionState.onPointerDown = optionValue(spec, 'onPointerDown', []);
        sessionState.onScroll = optionValue(spec, 'onScroll', []);
        sessionState.installScrollWheel = optionValue(spec, 'installScrollWheel', true);
        sessionState.scrollTargets = normalizeHandles(optionValue(spec, ...
            'scrollTargets', []));
        sessionState.scrollScope = scrollScopeValue(optionValue(spec, ...
            'scrollScope', 'targets'));
        sessionState.background = [];
        sessionState.graphics = [];
        sessionState.dragActive = false;

        session = struct();
        session.activate = @activateSession;
        session.deactivate = @deactivateSession;
        session.isActive = @isSessionActive;
        session.setBackground = @setSessionBackground;
        session.setGraphics = @setSessionGraphics;
        session.captureDrag = @captureDrag;
        session.releaseDrag = @releaseDrag;
        session.refresh = @refreshSession;
        session.delete = @deleteSession;

        if isfield(spec, 'background')
            setSessionBackground(spec.background);
        end
        if isfield(spec, 'graphics')
            setSessionGraphics(spec.graphics);
        end

        function activateSession()
            if ~isValidHandle(state.ax)
                trace(sprintf('skip activate invalid axes: %s', char(sessionState.name)));
                return;
            end
            if ~isempty(state.activeDeactivate) && ...
                    ~isequal(state.activeToken, sessionState.token)
                trace(sprintf('deactivate peer before activating %s', char(sessionState.name)));
                state.activeDeactivate();
            end

            trace(sprintf('activate session %s', char(sessionState.name)));
            state.activeToken = sessionState.token;
            state.activeName = sessionState.name;
            state.activeDeactivate = @deactivateFromPeer;
            installPointerCallback();
            updateInteractiveTargets(true);
            if sessionState.installScrollWheel && ~isempty(sessionState.onScroll)
                installSessionScroll();
            else
                if isequal(state.activeScrollToken, sessionState.token)
                    state.activeScrollToken = [];
                end
                trace(sprintf('session %s keeps runtime default scroll', char(sessionState.name)));
                installDefaultCallbacks();
            end
            notifyInteractionChanged(true, sessionState.name);
        end

        function deactivateSession()
            wasActive = isSessionActive();
            trace(sprintf('deactivate session %s active=%d', ...
                char(sessionState.name), wasActive));
            releaseDrag();
            updateInteractiveTargets(false);

            if wasActive
                if isValidHandle(state.ax)
                    state.ax.ButtonDownFcn = [];
                end
                state.activeToken = [];
                state.activeName = "";
                state.activeDeactivate = [];
            end

            if isequal(state.activeScrollToken, sessionState.token)
                state.activeScrollToken = [];
                installDefaultCallbacks();
            elseif wasActive
                installDefaultCallbacks();
            end

            if wasActive
                notifyInteractionChanged(false, sessionState.name);
            end
        end

        function tf = isSessionActive()
            tf = isequal(state.activeToken, sessionState.token);
        end

        function setSessionBackground(h)
            sessionState.background = normalizeHandles(h);
            trace(sprintf('session %s background handles=%d', ...
                char(sessionState.name), numel(sessionState.background)));
            refreshSession();
        end

        function setSessionGraphics(h)
            sessionState.graphics = normalizeHandles(h);
            trace(sprintf('session %s graphics handles=%d', ...
                char(sessionState.name), numel(sessionState.graphics)));
            refreshSession();
        end

        function captureDrag(motionFcn, releaseFcn)
            if ~isSessionActive() || ~isValidHandle(state.fig)
                trace(sprintf('skip drag capture for inactive session %s', char(sessionState.name)));
                return;
            end
            trace(sprintf('capture drag for session %s', char(sessionState.name)));
            sessionState.dragActive = true;
            state.fig.WindowButtonMotionFcn = @onDragMotion;
            state.fig.WindowButtonUpFcn = @onDragRelease;

            function onDragMotion(src, evt)
                try
                    if ~isempty(motionFcn)
                        motionFcn(src, evt);
                    end
                catch ME
                    trace(sprintf('drag motion error for session %s: %s', ...
                        char(sessionState.name), ME.identifier));
                    releaseDrag();
                    rethrow(ME);
                end
            end

            function onDragRelease(src, evt)
                try
                    if ~isempty(releaseFcn)
                        releaseFcn(src, evt);
                    end
                catch ME
                    trace(sprintf('drag release error for session %s: %s', ...
                        char(sessionState.name), ME.identifier));
                    releaseDrag();
                    rethrow(ME);
                end
                releaseDrag();
            end
        end

        function releaseDrag()
            if ~sessionState.dragActive
                return;
            end
            trace(sprintf('release drag for session %s', char(sessionState.name)));
            if isValidHandle(state.fig)
                state.fig.WindowButtonMotionFcn = '';
                state.fig.WindowButtonUpFcn = '';
            end
            sessionState.dragActive = false;
        end

        function refreshSession()
            if isSessionActive()
                installPointerCallback();
                updateInteractiveTargets(true);
                if sessionState.installScrollWheel && ~isempty(sessionState.onScroll)
                    installSessionScroll();
                end
            else
                updateInteractiveTargets(false);
            end
        end

        function deleteSession()
            deactivateSession();
            sessionState.background = [];
            sessionState.graphics = [];
        end

        function deactivateFromPeer()
            deactivateSession();
        end

        function installPointerCallback()
            if ~isValidHandle(state.ax)
                return;
            end
            state.ax.ButtonDownFcn = sessionState.onPointerDown;
        end

        function installSessionScroll()
            if ~isValidHandle(state.fig)
                trace(sprintf('skip session scroll invalid figure: %s', char(sessionState.name)));
                return;
            end
            state.activeScrollToken = sessionState.token;
            state.fig.WindowScrollWheelFcn = @onSessionScroll;
            trace(sprintf('installed session scroll callback: %s', char(sessionState.name)));
        end

        function onSessionScroll(src, evt)
            if shouldDispatchScroll(state.fig, sessionScrollTargets(), ...
                    sessionState.scrollScope)
                sessionState.onScroll(src, evt);
            else
                callFallbackScroll(src, evt);
            end
        end

        function handles = sessionScrollTargets()
            handles = sessionState.scrollTargets;
            if isempty(handles)
                handles = normalizeHandles({state.ax, ...
                    sessionState.background, sessionState.graphics});
            end
        end

        function updateInteractiveTargets(active)
            if active
                hitTest = 'on';
                pickableParts = 'visible';
                pointerFcn = sessionState.onPointerDown;
            else
                hitTest = 'off';
                pickableParts = 'none';
                pointerFcn = [];
            end

            applyTargetState(sessionState.background, pointerFcn, hitTest, pickableParts);
            applyTargetState(sessionState.graphics, pointerFcn, hitTest, pickableParts);
        end
    end

    function notifyInteractionChanged(active, name)
        if isempty(state.onInteractionChanged)
            return;
        end
        state.onInteractionChanged(active, name);
    end

    function trace(message)
        if isempty(state.onTrace)
            return;
        end
        state.onTrace(sprintf('imageAxesRuntime: %s', char(message)));
    end

    function callFallbackScroll(src, evt)
        fcn = state.fallbackScrollFcn;
        if isempty(fcn)
            return;
        end
        if isValidHandle(state.fig) && isequal(fcn, state.fig.WindowScrollWheelFcn)
            return;
        end
        if isa(fcn, 'function_handle')
            fcn(src, evt);
        elseif iscell(fcn) && ~isempty(fcn)
            feval(fcn{1}, src, evt, fcn{2:end});
        elseif ischar(fcn) || isstring(fcn)
            feval(char(fcn), src, evt);
        end
    end
end

function applyTargetState(handles, pointerFcn, hitTest, pickableParts)
    handles = normalizeHandles(handles);
    for k = 1:numel(handles)
        h = handles(k);
        if ~isValidHandle(h)
            continue;
        end
        if isprop(h, 'ButtonDownFcn')
            h.ButtonDownFcn = pointerFcn;
        end
        if isprop(h, 'HitTest')
            h.HitTest = hitTest;
        end
        if isprop(h, 'PickableParts')
            h.PickableParts = pickableParts;
        end
    end
end

function handles = normalizeHandles(handles)
    if isempty(handles)
        handles = [];
        return;
    end
    if iscell(handles)
        parts = cell(1, numel(handles));
        count = 0;
        for k = 1:numel(handles)
            item = normalizeHandles(handles{k});
            if ~isempty(item)
                count = count + 1;
                parts{count} = item;
            end
        end
        if count == 0
            handles = [];
        else
            handles = [parts{1:count}];
        end
        return;
    end
    handles = handles(:).';
end

function tf = shouldDispatchScroll(fig, targets, scope)
    scope = scrollScopeValue(scope);
    if scope == "figure"
        tf = true;
        return;
    end
    targets = normalizeHandles(targets);
    if isempty(targets)
        tf = false;
        return;
    end
    tf = pointerOverTargets(fig, targets);
end

function tf = pointerOverTargets(fig, targets)
    tf = false;
    if ~isValidHandle(fig)
        return;
    end
    try
        hit = hittest(fig);
    catch
        hit = [];
    end
    if isempty(hit) || ~isValidHandle(hit)
        return;
    end

    current = hit;
    while ~isempty(current) && isValidHandle(current)
        if anyHandleMatches(current, targets)
            tf = true;
            return;
        end
        if ~isprop(current, 'Parent')
            return;
        end
        current = current.Parent;
    end
end

function tf = anyHandleMatches(handle, handles)
    tf = false;
    for k = 1:numel(handles)
        target = handles(k);
        if isValidHandle(target) && isequal(handle, target)
            tf = true;
            return;
        end
    end
end

function scope = scrollScopeValue(scope)
    scope = lower(string(scope));
    if scope == "figure"
        return;
    end
    scope = "targets";
end

function fcn = currentScrollFcn(fig)
    fcn = [];
    if isValidHandle(fig)
        fcn = fig.WindowScrollWheelFcn;
    end
end

function tf = isValidHandle(h)
    tf = ~isempty(h) && all(isvalid(h));
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end

function token = nextInteractionToken()
    persistent nextToken
    if isempty(nextToken)
        nextToken = 0;
    end
    nextToken = nextToken + 1;
    token = nextToken;
end

function key = imageAxesRuntimeAppdataKey()
    key = 'labkit_ui_imageAxesRuntime';
end

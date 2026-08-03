% Private App runtime helper. The MATLAB adapter supplies a figure, semantic
% axes targets, and one typed-dispatch bridge. This hub owns figure pointer,
% wheel, drag, target-listener, and editor-session lifetimes.
function hub = FigureInteractionHub( ...
        fig, suppliedTargets, dispatchEvent, cleanupTarget)
    state = struct();
    state.targets = normalizeTargets(suppliedTargets);
    state.sessions = emptySessions();
    state.activeGroup = "";
    state.drag = emptyDrag();
    state.suppressed = false;
    state.deleted = false;
    state.prior = priorCallbacks(fig);
    state.callbacks = struct( ...
        "down", @onPointerDown, ...
        "motion", @onPointerMotion, ...
        "up", @onPointerUp, ...
        "scroll", @onScroll);
    installTargetListeners();
    installCallbacks();

    hub = struct( ...
        "adapter", @adapter, ...
        "dispatch", @dispatchSemanticEvent, ...
        "point", @targetPoint, ...
        "setSuppressed", @setSuppressed, ...
        "targetIds", @targetIds, ...
        "activeGroup", @activeGroup, ...
        "isDragging", @isDragging, ...
        "routeWheel", @routeWheel, ...
        "delete", @deleteHub);

    function point = targetPoint(targetId)
        ax = targetAxes(requireTarget(targetId));
        current = double(ax.CurrentPoint);
        point = current(1, 1:2);
    end

    function runtime = adapter(targetId, groupId)
        targetId = requireTarget(targetId);
        if nargin < 2 || strlength(string(groupId)) == 0
            groupId = "interaction:" + targetId;
        end
        groupId = string(groupId);
        runtime = struct( ...
            "axes", @() targetAxes(targetId), ...
            "figure", @() fig, ...
            "createSession", @(options) createSession( ...
                targetId, groupId, options));
    end

    function session = createSession(targetId, groupId, options)
        if nargin < 3 || isempty(options)
            options = struct();
        end
        token = nextToken();
        entry = struct( ...
            "token", token, ...
            "target", targetId, ...
            "group", groupId, ...
            "name", string(optionValue(options, 'name', 'interaction')), ...
            "onPointerDown", optionValue(options, 'onPointerDown', []), ...
            "onScroll", optionValue(options, 'onScroll', []), ...
            "installScrollWheel", logical(optionValue( ...
                options, 'installScrollWheel', true)), ...
            "background", gobjects(1, 0), ...
            "graphics", gobjects(1, 0));
        state.sessions(end + 1) = entry;
        session = struct( ...
            "activate", @activate, ...
            "activateIfAvailable", @activateIfAvailable, ...
            "canActivate", @canActivate, ...
            "deactivate", @deactivate, ...
            "isActive", @isActive, ...
            "setBackground", @(value) setHandles('background', value), ...
            "setGraphics", @(value) setHandles('graphics', value), ...
            "captureDrag", @captureDrag, ...
            "releaseDrag", @releaseDrag, ...
            "refresh", @refresh, ...
            "delete", @deleteSession);

        function activate()
            assertTargetValid(targetId);
            state.activeGroup = groupId;
        end

        function activated = activateIfAvailable()
            activated = canActivate();
            if activated
                activate();
            end
        end

        function tf = canActivate()
            tf = strlength(state.activeGroup) == 0 || ...
                state.activeGroup == groupId;
        end

        function deactivate()
            releaseDrag();
            if state.activeGroup == groupId
                state.activeGroup = "";
            end
        end

        function tf = isActive()
            tf = state.activeGroup == groupId && sessionExists(token);
        end

        function setHandles(field, value)
            index = sessionIndex(token);
            if isempty(index)
                return;
            end
            state.sessions(index).(field) = normalizeHandles(value);
        end

        function captureDrag(motionFcn, releaseFcn)
            if ~isActive()
                return;
            end
            state.drag = struct("token", token, "motion", motionFcn, ...
                "release", releaseFcn);
        end

        function releaseDrag()
            if isequal(state.drag.token, token)
                state.drag = emptyDrag();
            end
        end

        function refresh()
            assertTargetValid(targetId);
        end

        function deleteSession()
            releaseDrag();
            index = sessionIndex(token);
            if isempty(index)
                return;
            end
            state.sessions(index) = [];
            if state.activeGroup == groupId
                state.activeGroup = "";
            end
        end
    end

    function onPointerDown(src, event)
        hit = pointerHitObject(src, event);
        target = targetUnderPointer(hit);
        entry = activeSessionForTarget(target);
        if isempty(entry)
            invokeCallback(state.prior.down, src, event);
            return;
        end
        invokeCallback(entry.onPointerDown, hit, event);
    end

    function hit = pointerHitObject(fallback, event)
        hit = [];
        if isstruct(event) && isfield(event, 'HitObject') && ...
                isValidHandle(event.HitObject)
            hit = event.HitObject;
        elseif isobject(event) && isprop(event, 'HitObject') && ...
                isValidHandle(event.HitObject)
            hit = event.HitObject;
        end
        if isempty(hit)
            try
                hit = hittest(fig);
            catch
            end
        end
        if isempty(hit)
            hit = fallback;
        end
    end

    function onPointerMotion(src, event)
        if isempty(state.drag.token)
            invokeCallback(state.prior.motion, src, event);
            return;
        end
        try
            invokeCallback(state.drag.motion, src, event);
        catch ME
            state.drag = emptyDrag();
            rethrow(ME);
        end
    end

    function onPointerUp(src, event)
        if isempty(state.drag.token)
            invokeCallback(state.prior.up, src, event);
            return;
        end
        release = state.drag.release;
        state.drag = emptyDrag();
        invokeCallback(release, src, event);
    end

    function onScroll(src, event)
        target = targetUnderPointer();
        if strlength(target) == 0
            invokeCallback(state.prior.scroll, src, event);
            return;
        end
        routeWheel(target, event, src);
    end

    function routeWheel(targetId, event, src)
        if nargin < 3
            src = fig;
        end
        if strlength(string(targetId)) == 0
            invokeCallback(state.prior.scroll, src, event);
            return;
        end
        targetId = requireTarget(targetId);
        entry = activeSessionForTarget(targetId);
        if ~isempty(entry) && entry.installScrollWheel && ...
                ~isempty(entry.onScroll)
            invokeCallback(entry.onScroll, src, event);
            return;
        end
        ax = targetAxes(targetId);
        count = scrollCount(event);
        if count == 0
            return;
        end
        point = wheelPoint(ax, event);
        zoomAxesAtPoint(ax, point, count, ...
            "ZoomAxes", scrollZoomAxes(ax));
    end

    function dispatchSemanticEvent(id, ~, value, ~)
        if state.suppressed || isempty(dispatchEvent)
            return;
        end
        dispatchEvent(string(id), value);
    end

    function setSuppressed(value)
        state.suppressed = logical(value);
    end

    function ids = targetIds()
        ids = [state.targets.id];
    end

    function value = activeGroup()
        value = state.activeGroup;
    end

    function tf = isDragging()
        tf = ~isempty(state.drag.token);
    end

    function deleteHub()
        if state.deleted
            return;
        end
        state.deleted = true;
        deleteTargetListeners();
        state.sessions = emptySessions();
        state.drag = emptyDrag();
        restoreCallbacks();
    end

    function installTargetListeners()
        for index = 1:numel(state.targets)
            id = state.targets(index).id;
            state.targets(index).listener = addlistener( ...
                state.targets(index).axes, 'ObjectBeingDestroyed', ...
                @(~, ~) onTargetDeleted(id));
        end
    end

    function onTargetDeleted(id)
        if state.deleted
            return;
        end
        matches = string({state.sessions.target}) == id;
        removedTokens = [state.sessions(matches).token];
        removedGroups = [state.sessions(matches).group];
        state.sessions(matches) = [];
        if ~isempty(state.drag.token) && any(removedTokens == state.drag.token)
            state.drag = emptyDrag();
        end
        if ~isempty(removedGroups) && ...
                any(string(removedGroups) == state.activeGroup)
            state.activeGroup = "";
        end
        cleanupTarget(id);
    end

    function deleteTargetListeners()
        for index = 1:numel(state.targets)
            listener = state.targets(index).listener;
            if ~isempty(listener) && isvalid(listener)
                delete(listener);
            end
        end
    end

    function installCallbacks()
        fig.WindowButtonDownFcn = state.callbacks.down;
        fig.WindowButtonMotionFcn = state.callbacks.motion;
        fig.WindowButtonUpFcn = state.callbacks.up;
        fig.WindowScrollWheelFcn = state.callbacks.scroll;
    end

    function restoreCallbacks()
        if ~isValidHandle(fig)
            return;
        end
        restoreIfOwned('WindowButtonDownFcn', state.callbacks.down, state.prior.down);
        restoreIfOwned('WindowButtonMotionFcn', state.callbacks.motion, state.prior.motion);
        restoreIfOwned('WindowButtonUpFcn', state.callbacks.up, state.prior.up);
        restoreIfOwned('WindowScrollWheelFcn', state.callbacks.scroll, state.prior.scroll);
    end

    function restoreIfOwned(property, owned, prior)
        if isequal(fig.(property), owned)
            fig.(property) = prior;
        end
    end

    function target = targetUnderPointer(hit)
        target = "";
        if ~isValidHandle(fig)
            return;
        end
        if nargin < 1 || isempty(hit)
            hit = [];
            try
                hit = hittest(fig);
            catch
            end
        end
        for k = 1:numel(state.targets)
            if handleDescendsFrom(hit, state.targets(k).axes)
                target = state.targets(k).id;
                return;
            end
        end
        try
            point = fig.CurrentPoint;
        catch
            return;
        end
        for k = 1:numel(state.targets)
            ax = state.targets(k).axes;
            if ~isValidHandle(ax)
                continue;
            end
            position = getpixelposition(ax, true);
            if point(1) >= position(1) && point(1) <= position(1) + position(3) && ...
                    point(2) >= position(2) && point(2) <= position(2) + position(4)
                target = state.targets(k).id;
                return;
            end
        end
    end

    function entry = activeSessionForTarget(target)
        entry = [];
        if strlength(target) == 0 || strlength(state.activeGroup) == 0
            return;
        end
        index = find(string({state.sessions.target}) == target & ...
            string({state.sessions.group}) == state.activeGroup, 1, 'last');
        if ~isempty(index)
            entry = state.sessions(index);
        end
    end

    function id = requireTarget(id)
        id = string(id);
        if ~isscalar(id) || ~any(string({state.targets.id}) == id)
            error('labkit:app:runtime:UnknownInteractionTarget', ...
                'Unknown interaction target "%s".', id);
        end
    end

    function ax = targetAxes(id)
        index = find(string({state.targets.id}) == string(id), 1, 'first');
        ax = state.targets(index).axes;
    end

    function assertTargetValid(id)
        if ~isValidHandle(targetAxes(id))
            error('labkit:app:runtime:InvalidInteractionTarget', ...
                'Interaction target "%s" no longer exists.', id);
        end
    end

    function index = sessionIndex(token)
        index = find([state.sessions.token] == token, 1, 'first');
    end

    function tf = sessionExists(token)
        tf = ~isempty(sessionIndex(token));
    end
end

function targets = normalizeTargets(values)
    if ~isstruct(values) || ...
            ~isfield(values, "id") || ~isfield(values, "axes")
        error("labkit:app:runtime:InvariantFailure", ...
            "Interaction targets must provide semantic ids and axes.");
    end
    targets = repmat(struct("id", "", "axes", [], "listener", []), ...
        1, numel(values));
    for k = 1:numel(values)
        targets(k) = struct( ...
            "id", string(values(k).id), ...
            "axes", values(k).axes, "listener", []);
    end
end

function callbacks = priorCallbacks(fig)
    callbacks = struct( ...
        "down", fig.WindowButtonDownFcn, ...
        "motion", fig.WindowButtonMotionFcn, ...
        "up", fig.WindowButtonUpFcn, ...
        "scroll", fig.WindowScrollWheelFcn);
    key = 'labkitPreviewScrollNavigation';
    if isappdata(fig, key)
        navigation = getappdata(fig, key);
        if isfield(navigation, 'fallbackScrollFcn')
            callbacks.scroll = navigation.fallbackScrollFcn;
        end
    end
end

function sessions = emptySessions()
    sessions = struct("token", {}, "target", {}, "group", {}, ...
        "name", {}, "onPointerDown", {}, "onScroll", {}, ...
        "installScrollWheel", {}, "background", {}, "graphics", {});
end

function drag = emptyDrag()
    drag = struct("token", [], "motion", [], "release", []);
end

function token = nextToken()
    persistent value
    if isempty(value)
        value = uint64(0);
    end
    value = value + 1;
    token = value;
end

function value = optionValue(options, name, defaultValue)
    value = defaultValue;
    if isstruct(options) && isfield(options, name)
        value = options.(name);
    end
end

function handles = normalizeHandles(value)
    handles = gobjects(1, 0);
    if isempty(value)
        return;
    end
    if iscell(value)
        chunks = cell(1, numel(value));
        for k = 1:numel(value)
            chunks{k} = normalizeHandles(value{k});
        end
        handles = [chunks{:}];
        return;
    end
    value = value(:).';
    handles = value(arrayfun(@isValidHandle, value));
end

function tf = handleDescendsFrom(handle, ancestorHandle)
    tf = false;
    while isValidHandle(handle)
        if isequal(handle, ancestorHandle)
            tf = true;
            return;
        end
        if ~isprop(handle, 'Parent')
            return;
        end
        handle = handle.Parent;
    end
end

function count = scrollCount(event)
    count = 0;
    if isstruct(event) && isfield(event, 'VerticalScrollCount')
        count = event.VerticalScrollCount;
    elseif isobject(event) && isprop(event, 'VerticalScrollCount')
        count = event.VerticalScrollCount;
    end
    if ~isnumeric(count) || ~isscalar(count) || ~isfinite(count)
        count = 0;
    end
end

function point = wheelPoint(ax, event)
    if isstruct(event) && isfield(event, 'Point') && ...
            isnumeric(event.Point) && numel(event.Point) >= 2
        point = double(event.Point(1, 1:2));
        return;
    end
    current = ax.CurrentPoint;
    point = current(1, 1:2);
end

function axesMode = scrollZoomAxes(ax)
    axesMode = "xy";
    if isappdata(ax, 'labkitPreviewScrollZoomAxes')
        axesMode = string(getappdata(ax, 'labkitPreviewScrollZoomAxes'));
    end
end

function invokeCallback(callback, src, event)
    if isempty(callback)
        return;
    end
    if isa(callback, 'function_handle')
        callback(src, event);
    elseif iscell(callback)
        callbackFunction = callback{1};
        callbackFunction(src, event, callback{2:end});
    elseif ischar(callback) || isstring(callback)
        if isempty(regexp(char(callback), ...
                '^[A-Za-z]\w*(\.[A-Za-z]\w*)*$', 'once'))
            error('labkit:app:FigureInteractionHub:InvalidCallbackName', ...
                'Legacy string callbacks must contain one callable function name.');
        end
        % Compatibility boundary for MATLAB figures that still expose a
        % legacy named callback instead of a function handle.
        feval(char(callback), src, event);
    end
end

function tf = isValidHandle(value)
    tf = ~isempty(value) && isscalar(value) && isgraphics(value);
end

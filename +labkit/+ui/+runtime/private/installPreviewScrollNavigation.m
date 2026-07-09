% Private UI runtime helper. Expected caller: buildWorkspace preview-area setup.
% Inputs are the app figure and preview axes. Output mutates the figure by
% installing one target-gated scroll dispatcher for all previewArea axes.
function installPreviewScrollNavigation(fig, axesHandles)
    if ~isValidHandle(fig)
        return;
    end
    axesHandles = normalizeAxes(axesHandles);
    if isempty(axesHandles)
        return;
    end

    key = 'labkitPreviewScrollNavigation';
    if isappdata(fig, key)
        state = getappdata(fig, key);
    else
        state = struct();
        state.axes = gobjects(1, 0);
        state.preparedAxes = gobjects(1, 0);
        state.fallbackScrollFcn = fig.WindowScrollWheelFcn;
        state.callback = @onPreviewScroll;
    end
    if ~isfield(state, 'preparedAxes')
        state.preparedAxes = gobjects(1, 0);
    end

    state.axes = uniqueAxes([normalizeAxes(state.axes), axesHandles]);
    state.preparedAxes = axesInSet(normalizeAxes(state.preparedAxes), state.axes);
    setappdata(fig, key, state);

    current = fig.WindowScrollWheelFcn;
    if isempty(current) || isequal(current, state.fallbackScrollFcn) || ...
            isequal(current, state.callback)
        fig.WindowScrollWheelFcn = state.callback;
    end

    function onPreviewScroll(src, event)
        if ~isappdata(src, key)
            return;
        end
        navState = getappdata(src, key);
        ax = axesUnderPointer(src, navState.axes);
        if isempty(ax)
            callFallback(navState.fallbackScrollFcn, src, event);
            return;
        end
        scrollCount = scrollCountFromEvent(event);
        if scrollCount == 0
            return;
        end
        navState = prepareAxesForWheelNavigation(src, key, navState, ax);
        point = ax.CurrentPoint;
        labkit.ui.interaction.zoomAtPoint(ax, point(1, 1:2), scrollCount, ...
            "ZoomAxes", scrollZoomAxes(ax));
    end
end

function zoomAxes = scrollZoomAxes(ax)
    zoomAxes = "xy";
    try
        if isappdata(ax, 'labkitPreviewScrollZoomAxes')
            zoomAxes = string(getappdata(ax, 'labkitPreviewScrollZoomAxes'));
        end
    catch
    end
end

function ax = axesUnderPointer(fig, axesHandles)
    ax = [];
    try
        hit = hittest(fig);
        hitAxes = uiAxesAncestor(hit);
    catch
        hitAxes = [];
    end
    if isempty(hitAxes) || ~isValidHandle(hitAxes)
        ax = axesUnderFigurePoint(fig, axesHandles);
        return;
    end
    axesHandles = normalizeAxes(axesHandles);
    for k = 1:numel(axesHandles)
        if isequal(hitAxes, axesHandles(k))
            ax = hitAxes;
            return;
        end
    end
end

function ax = axesUnderFigurePoint(fig, axesHandles)
    ax = [];
    axesHandles = normalizeAxes(axesHandles);
    if isempty(axesHandles)
        return;
    end
    try
        point = fig.CurrentPoint;
    catch
        return;
    end
    if isempty(point) || numel(point) < 2 || any(~isfinite(point(1, 1:2)))
        return;
    end
    x = point(1, 1);
    y = point(1, 2);
    for k = 1:numel(axesHandles)
        try
            pos = getpixelposition(axesHandles(k), true);
        catch
            continue;
        end
        if x >= pos(1) && x <= pos(1) + pos(3) && ...
                y >= pos(2) && y <= pos(2) + pos(4)
            ax = axesHandles(k);
            return;
        end
    end
end

function ax = uiAxesAncestor(handle)
    ax = [];
    current = handle;
    while ~isempty(current) && isValidHandle(current)
        if isa(current, 'matlab.ui.control.UIAxes')
            ax = current;
            return;
        end
        if ~isprop(current, 'Parent')
            return;
        end
        current = current.Parent;
    end
end

function count = scrollCountFromEvent(event)
    count = 0;
    if isstruct(event) && isfield(event, 'VerticalScrollCount')
        count = event.VerticalScrollCount;
    elseif isobject(event) && isprop(event, 'VerticalScrollCount')
        count = event.VerticalScrollCount;
    end
    if isempty(count) || ~isnumeric(count) || ~isscalar(count) || ~isfinite(count)
        count = 0;
    end
end

function callFallback(fcn, src, event)
    if isempty(fcn)
        return;
    end
    if isa(fcn, 'function_handle')
        fcn(src, event);
    elseif iscell(fcn) && ~isempty(fcn)
        feval(fcn{1}, src, event, fcn{2:end});
    elseif ischar(fcn) || isstring(fcn)
        feval(char(fcn), src, event);
    end
end

function axesHandles = normalizeAxes(axesHandles)
    if isempty(axesHandles)
        axesHandles = gobjects(1, 0);
        return;
    end
    axesHandles = axesHandles(:).';
    keep = false(size(axesHandles));
    for k = 1:numel(axesHandles)
        keep(k) = isValidHandle(axesHandles(k)) && ...
            isa(axesHandles(k), 'matlab.ui.control.UIAxes');
    end
    axesHandles = axesHandles(keep);
end

function axesHandles = uniqueAxes(axesHandles)
    keep = true(size(axesHandles));
    for k = 1:numel(axesHandles)
        if ~keep(k)
            continue;
        end
        for j = k + 1:numel(axesHandles)
            if isequal(axesHandles(k), axesHandles(j))
                keep(j) = false;
            end
        end
    end
    axesHandles = axesHandles(keep);
end

function state = prepareAxesForWheelNavigation(fig, key, state, ax)
    if axesContains(state.preparedAxes, ax)
        return;
    end
    disableBuiltInWheelNavigation(ax);
    state.preparedAxes = uniqueAxes([normalizeAxes(state.preparedAxes), ax]);
    if isValidHandle(fig)
        setappdata(fig, key, state);
    end
end

function disableBuiltInWheelNavigation(ax)
    try
        disableDefaultInteractivity(ax);
    catch
    end
    try
        ax.Interactions = [];
    catch
    end
    try
        if ~strcmp(ax.Toolbar.Visible, 'on')
            ax.Toolbar.Visible = 'on';
        end
    catch
    end
end

function axesHandles = axesInSet(axesHandles, allowedAxes)
    keep = false(size(axesHandles));
    for k = 1:numel(axesHandles)
        keep(k) = axesContains(allowedAxes, axesHandles(k));
    end
    axesHandles = axesHandles(keep);
end

function tf = axesContains(axesHandles, ax)
    tf = false;
    axesHandles = normalizeAxes(axesHandles);
    if ~isValidHandle(ax)
        return;
    end
    for k = 1:numel(axesHandles)
        if isequal(axesHandles(k), ax)
            tf = true;
            return;
        end
    end
end

function tf = isValidHandle(h)
    tf = ~isempty(h) && all(isvalid(h));
end

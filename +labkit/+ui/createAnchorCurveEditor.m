function editor = createAnchorCurveEditor(ax, imageSize, opts)
%CREATEANCHORCURVEEDITOR Create reusable editable anchor-curve interaction.
%
% Usage:
%   editor = labkit.ui.createAnchorCurveEditor(ax, size(image), ...
%       struct('closed', true, 'style', 'Curve', 'onChanged', @onChanged));
%   editor.start(points);
%
% Inputs:
%   ax - UI axes containing the image/plot surface.
%   imageSize - [height width] or image size used for zoom/limit clamping.
%   opts - optional struct.
%
% Options:
%   figure - owning uifigure/figure, default ancestor(ax,'figure').
%   closed - logical, default false; close preview path for ROI boundaries.
%   style - "Curve" (default) or "Straight lines".
%   installScrollWheel - logical, default true; install scroll zoom handler.
%   maxPoints - positive integer/Inf, default Inf.
%   onChanged - function handle called after point edits.
%
% Returned editor API:
%   start(points), setActive(tf), setPoints(points), getPoints(),
%   clearPoints(), undoLast(), insertPoint(x,y), setStyle(style),
%   setImageSize(imageSize), setBackground(handle), refresh(),
%   curvePoints(), delete().
%
% Interaction:
%   Double-click blank space to add/insert anchors, drag anchors to move,
%   double-click anchors to delete, and use scroll wheel to zoom when enabled.
%   Open paths extend endpoints for natural tracing, but clicks close to an
%   existing visible segment insert correction anchors. Endpoint extensions
%   that would self-intersect the visible path are treated as insertions.
%   Only one anchor editor owns a given axes at a time. Activating an editor
%   deactivates the previous editor on that axes, temporarily owns pointer
%   hit-testing and scroll-wheel zoom, and restores the prior scroll callback
%   when deactivated.

    if nargin < 3
        opts = struct();
    end

    state = struct();
    state.ax = ax;
    state.fig = optionValue(opts, 'figure', ancestor(ax, 'figure'));
    state.imageSize = imageSize;
    state.token = nextEditorToken();
    state.closed = optionValue(opts, 'closed', false);
    state.style = string(optionValue(opts, 'style', 'Curve'));
    state.installScrollWheel = optionValue(opts, 'installScrollWheel', true);
    state.maxPoints = optionValue(opts, 'maxPoints', inf);
    state.active = false;
    state.points = zeros(0, 2);
    state.dragIndex = [];
    state.curveLine = [];
    state.anchorLine = [];
    state.background = [];
    state.viewXLim = [];
    state.viewYLim = [];
    state.ownsScrollWheel = false;
    state.previousScrollWheelFcn = [];
    state.onChanged = optionValue(opts, 'onChanged', []);

    editor = struct();
    editor.start = @start;
    editor.setActive = @setActive;
    editor.setPoints = @setPoints;
    editor.getPoints = @getPoints;
    editor.clearPoints = @clearPoints;
    editor.undoLast = @undoLast;
    editor.insertPoint = @insertPoint;
    editor.setStyle = @setStyle;
    editor.setImageSize = @setImageSize;
    editor.setBackground = @setBackground;
    editor.refresh = @refresh;
    editor.curvePoints = @curvePointsForCurrentState;
    editor.delete = @deleteEditor;

    setActive(false);
    refresh();

    function start(points)
        if nargin >= 1 && ~isempty(points)
            state.points = normalizePoints(points);
        end
        setActive(true);
        notifyChanged('start');
    end

    function setActive(enabled)
        state.active = logical(enabled);
        if state.active
            registerActiveEditor();
            state.ax.ButtonDownFcn = @onAxesClicked;
            installScrollWheelCallback();
        else
            unregisterActiveEditor();
            state.ax.ButtonDownFcn = [];
            releaseDragCallbacks();
            clearOwnedScrollWheel();
        end
        updateBackgroundHitTest();
        updateEditorHitTest();
    end

    function setPoints(points)
        state.points = normalizePoints(points);
        refresh();
        notifyChanged('set points');
    end

    function points = getPoints()
        points = state.points;
    end

    function clearPoints()
        state.points = zeros(0, 2);
        state.dragIndex = [];
        refresh();
        notifyChanged('clear points');
    end

    function undoLast()
        if isempty(state.points)
            return;
        end
        state.points(end, :) = [];
        refresh();
        notifyChanged('undo point');
    end

    function insertPoint(point)
        state.points = addOrInsertAnchor(state.points, point, state.ax, ...
            state.imageSize, state.style, state.closed, state.maxPoints);
        refresh();
        notifyChanged('add point');
    end

    function setStyle(style)
        state.style = string(style);
        refresh();
        notifyChanged('style changed');
    end

    function setImageSize(imageSize)
        state.imageSize = imageSize;
        refresh();
    end

    function setBackground(h)
        state.background = h;
        updateBackgroundHitTest();
    end

    function refresh()
        if state.active
            state.ax.ButtonDownFcn = @onAxesClicked;
            installScrollWheelCallback();
        end
        updateBackgroundHitTest();
        ensureGraphics();
        updateEditorHitTest();
        if ~isempty(state.anchorLine) && isvalid(state.anchorLine)
            state.anchorLine.XData = state.points(:, 1);
            state.anchorLine.YData = state.points(:, 2);
        end

        curve = curvePointsForCurrentState();
        if ~isempty(state.curveLine) && isvalid(state.curveLine)
            if isempty(curve)
                state.curveLine.XData = NaN;
                state.curveLine.YData = NaN;
            else
                state.curveLine.XData = curve(:, 1);
                state.curveLine.YData = curve(:, 2);
            end
        end

        applyStoredView();
    end

    function curve = curvePointsForCurrentState()
        curve = anchorCurvePoints(state.points, state.imageSize, state.style, state.closed);
    end

    function deleteEditor()
        if ~isempty(state.curveLine) && isvalid(state.curveLine)
            delete(state.curveLine);
        end
        if ~isempty(state.anchorLine) && isvalid(state.anchorLine)
            delete(state.anchorLine);
        end
        if isvalid(state.ax)
            state.ax.ButtonDownFcn = [];
        end
        unregisterActiveEditor();
        releaseDragCallbacks();
        clearOwnedScrollWheel();
        labkit.ui.enableAxesPopout(state.ax);
    end

    function onAxesClicked(~, ~)
        if ~state.active || isempty(state.imageSize)
            return;
        end
        if strcmp(state.fig.SelectionType, 'alt') || strcmp(state.fig.SelectionType, 'extend')
            return;
        end

        point = state.ax.CurrentPoint;
        x = point(1, 1);
        y = point(1, 2);
        if ~insideImageBounds(x, y, state.imageSize)
            return;
        end

        idx = nearestAnchor(x, y);
        if strcmp(state.fig.SelectionType, 'open')
            if ~isempty(idx)
                state.points(idx, :) = [];
                refresh();
                notifyChanged('delete point');
            else
                state.points = addOrInsertAnchor(state.points, [x y], state.ax, ...
                    state.imageSize, state.style, state.closed, state.maxPoints);
                refresh();
                notifyChanged('add point');
            end
            return;
        end

        if ~isempty(idx)
            state.dragIndex = idx;
            updateDraggedAnchor();
            state.fig.WindowButtonMotionFcn = @onAnchorDragged;
            state.fig.WindowButtonUpFcn = @onAnchorReleased;
        end
    end

    function onAnchorDragged(~, ~)
        updateDraggedAnchor();
    end

    function onAnchorReleased(~, ~)
        updateDraggedAnchor();
        releaseDragCallbacks();
        notifyChanged('move point');
    end

    function updateDraggedAnchor()
        if isempty(state.dragIndex) || state.dragIndex > size(state.points, 1)
            return;
        end
        point = state.ax.CurrentPoint;
        x = min(max(point(1, 1), 0.5), state.imageSize(2) + 0.5);
        y = min(max(point(1, 2), 0.5), state.imageSize(1) + 0.5);
        state.points(state.dragIndex, :) = [x y];
        refresh();
    end

    function onScrollZoom(~, event)
        if isempty(state.imageSize)
            return;
        end
        point = state.ax.CurrentPoint;
        x = point(1, 1);
        y = point(1, 2);
        if ~insideImageBounds(x, y, state.imageSize)
            return;
        end
        zoomAxesAtPoint(state.ax, x, y, event.VerticalScrollCount, state.imageSize);
        state.viewXLim = state.ax.XLim;
        state.viewYLim = state.ax.YLim;
    end

    function ensureGraphics()
        created = false;
        if isempty(state.curveLine) || ~isvalid(state.curveLine)
            state.curveLine = line(state.ax, NaN, NaN, ...
                'Color', [0 0.45 0.95], ...
                'LineWidth', 1.5, ...
                'ButtonDownFcn', @onAxesClicked, ...
                'HitTest', 'on', ...
                'PickableParts', 'visible');
            created = true;
        end

        if isempty(state.anchorLine) || ~isvalid(state.anchorLine)
            state.anchorLine = line(state.ax, NaN, NaN, ...
                'LineStyle', 'none', ...
                'Marker', 'o', ...
                'MarkerSize', 7, ...
                'Color', [1 0.85 0], ...
                'MarkerFaceColor', [0 0.45 0.95], ...
                'ButtonDownFcn', @onAxesClicked, ...
                'HitTest', 'on', ...
                'PickableParts', 'visible');
            created = true;
        end
        if created
            labkit.ui.enableAxesPopout(state.ax);
        end
    end

    function updateEditorHitTest()
        if state.active
            hitTest = 'on';
            pickableParts = 'visible';
        else
            hitTest = 'off';
            pickableParts = 'none';
        end
        setGraphicHitTest(state.curveLine, hitTest, pickableParts);
        setGraphicHitTest(state.anchorLine, hitTest, pickableParts);
    end

    function setGraphicHitTest(h, hitTest, pickableParts)
        if isempty(h) || ~isvalid(h)
            return;
        end
        h.HitTest = hitTest;
        h.PickableParts = pickableParts;
    end

    function releaseDragCallbacks()
        if isempty(state.fig) || ~isvalid(state.fig)
            state.dragIndex = [];
            return;
        end
        state.fig.WindowButtonMotionFcn = '';
        state.fig.WindowButtonUpFcn = '';
        state.dragIndex = [];
    end

    function clearOwnedScrollWheel()
        if ~state.ownsScrollWheel
            return;
        end
        if state.installScrollWheel && ~isempty(state.fig) && isvalid(state.fig)
            state.fig.WindowScrollWheelFcn = state.previousScrollWheelFcn;
        end
        state.previousScrollWheelFcn = [];
        state.ownsScrollWheel = false;
    end

    function installScrollWheelCallback()
        if ~state.installScrollWheel || isempty(state.fig) || ~isvalid(state.fig)
            return;
        end
        if ~state.ownsScrollWheel
            state.previousScrollWheelFcn = state.fig.WindowScrollWheelFcn;
        end
        state.fig.WindowScrollWheelFcn = @onScrollZoom;
        state.ownsScrollWheel = true;
    end

    function registerActiveEditor()
        if isempty(state.ax) || ~isvalid(state.ax)
            return;
        end
        key = activeEditorAppdataKey();
        if isappdata(state.ax, key)
            activeEditor = getappdata(state.ax, key);
            if isstruct(activeEditor) && isfield(activeEditor, 'token') && ...
                    activeEditor.token ~= state.token && ...
                    isfield(activeEditor, 'deactivate') && isa(activeEditor.deactivate, 'function_handle')
                activeEditor.deactivate();
            end
        end
        setappdata(state.ax, key, struct( ...
            'token', state.token, ...
            'deactivate', @deactivateFromPeer));
    end

    function unregisterActiveEditor()
        if isempty(state.ax) || ~isvalid(state.ax)
            return;
        end
        key = activeEditorAppdataKey();
        if ~isappdata(state.ax, key)
            return;
        end
        activeEditor = getappdata(state.ax, key);
        if isstruct(activeEditor) && isfield(activeEditor, 'token') && ...
                activeEditor.token == state.token
            rmappdata(state.ax, key);
        end
    end

    function deactivateFromPeer()
        setActive(false);
    end

    function updateBackgroundHitTest()
        if isempty(state.background) || ~isvalid(state.background)
            return;
        end
        if state.active
            state.background.ButtonDownFcn = @onAxesClicked;
            state.background.HitTest = 'on';
            state.background.PickableParts = 'visible';
        else
            state.background.ButtonDownFcn = [];
            state.background.HitTest = 'off';
            state.background.PickableParts = 'none';
        end
    end

    function idx = nearestAnchor(x, y)
        idx = [];
        if isempty(state.points)
            return;
        end
        dx = state.points(:, 1) - x;
        dy = state.points(:, 2) - y;
        [dist, bestIdx] = min(hypot(dx, dy));
        xSpan = max(1, diff(state.ax.XLim));
        ySpan = max(1, diff(state.ax.YLim));
        threshold = 0.025 * max(xSpan, ySpan);
        if dist <= threshold
            idx = bestIdx;
        end
    end

    function applyStoredView()
        if isempty(state.imageSize) || ~isvalid(state.ax)
            return;
        end
        fullX = [0.5, state.imageSize(2) + 0.5];
        fullY = [0.5, state.imageSize(1) + 0.5];
        state.ax.XLim = validStoredLimits(state.viewXLim, fullX);
        state.ax.YLim = validStoredLimits(state.viewYLim, fullY);
    end

    function notifyChanged(reason)
        if isempty(state.onChanged)
            return;
        end
        state.onChanged(state.points, reason);
    end
end

function points = normalizePoints(points)
    if isempty(points)
        points = zeros(0, 2);
        return;
    end
    points = double(points);
    assert(size(points, 2) == 2, 'Anchor points must be an N-by-2 numeric array.');
end

function tf = insideImageBounds(x, y, imageSize)
    tf = isfinite(x) && isfinite(y) && ...
        x >= 0.5 && y >= 0.5 && ...
        x <= imageSize(2) + 0.5 && y <= imageSize(1) + 0.5;
end

function zoomAxesAtPoint(ax, x, y, scrollCount, imageSize)
    if scrollCount == 0
        return;
    end

    fullX = [0.5, imageSize(2) + 0.5];
    fullY = [0.5, imageSize(1) + 0.5];
    zoomFactor = 1.20 ^ scrollCount;

    currentX = ax.XLim;
    currentY = ax.YLim;
    newWidth = diff(currentX) * zoomFactor;
    newHeight = diff(currentY) * zoomFactor;

    minSpan = 10;
    newWidth = min(max(newWidth, minSpan), diff(fullX));
    newHeight = min(max(newHeight, minSpan), diff(fullY));

    xFrac = (x - currentX(1)) / max(eps, diff(currentX));
    yFrac = (y - currentY(1)) / max(eps, diff(currentY));
    xFrac = min(max(xFrac, 0), 1);
    yFrac = min(max(yFrac, 0), 1);

    newX = [x - xFrac * newWidth, x + (1 - xFrac) * newWidth];
    newY = [y - yFrac * newHeight, y + (1 - yFrac) * newHeight];

    ax.XLim = clampLimits(newX, fullX);
    ax.YLim = clampLimits(newY, fullY);
end

function limits = validStoredLimits(storedLimits, fullLimits)
    limits = fullLimits;
    if isempty(storedLimits) || numel(storedLimits) ~= 2 || any(~isfinite(storedLimits))
        return;
    end
    limits = clampLimits(storedLimits, fullLimits);
end

function limits = clampLimits(limits, fullLimits)
    span = diff(limits);
    fullSpan = diff(fullLimits);
    if span >= fullSpan
        limits = fullLimits;
        return;
    end
    if limits(1) < fullLimits(1)
        limits = [fullLimits(1), fullLimits(1) + span];
    end
    if limits(2) > fullLimits(2)
        limits = [fullLimits(2) - span, fullLimits(2)];
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isfield(opts, name)
        value = opts.(name);
    end
end

function token = nextEditorToken()
    persistent nextToken
    if isempty(nextToken)
        nextToken = 0;
    end
    nextToken = nextToken + 1;
    token = nextToken;
end

function key = activeEditorAppdataKey()
    key = 'labkit_ui_activeAnchorCurveEditor';
end

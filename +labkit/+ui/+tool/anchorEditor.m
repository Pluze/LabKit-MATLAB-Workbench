function editor = anchorEditor(runtime, imageSize, opts)
%ANCHOREDITOR Create reusable editable anchor-curve interaction.
%
% Usage:
%   runtime = labkit.ui.tool.createRuntime(ax);
%   editor = labkit.ui.tool.anchorEditor(runtime, size(image), ...
%       struct('closed', true, 'style', 'Curve', 'onChanged', @onChanged));
%   editor.start(points);
%
% Inputs:
%   runtime - interaction runtime returned by labkit.ui.tool.createRuntime.
%   imageSize - [height width] or image size used for zoom/limit clamping.
%   opts - optional struct.
%
% Options:
%   closed - logical, default false; close preview path for ROI boundaries.
%   style - "Curve" (default) or "Straight lines".
%   installScrollWheel - logical, default true; temporarily use editor zoom
%                        while active. False preserves the runtime default
%                        scroll callback during editing.
%   maxPoints - positive integer/Inf, default Inf.
%   onChanged - function handle called after point edits.
%   onTrace - callback(message), default []. Receives verbose debug trace
%             messages for editor lifecycle and pointer interactions.
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
%   Interaction callback ownership is delegated to the image axes runtime.
%   Only one runtime session owns a given image axes at a time.

    if nargin < 3
        opts = struct();
    end

    state = struct();
    assert(isstruct(runtime) && isfield(runtime, 'axes') && ...
        isa(runtime.axes, 'function_handle') && ...
        isfield(runtime, 'createSession') && ...
        isa(runtime.createSession, 'function_handle'), ...
        'First input must be a labkit.ui.tool.createRuntime result.');

    state.runtime = runtime;
    state.ax = runtime.axes();
    state.fig = runtime.figure();
    state.imageSize = imageSize;
    state.closed = optionValue(opts, 'closed', false);
    state.style = string(optionValue(opts, 'style', 'Curve'));
    state.installScrollWheel = optionValue(opts, 'installScrollWheel', true);
    state.maxPoints = optionValue(opts, 'maxPoints', inf);
    state.points = zeros(0, 2);
    state.dragIndex = [];
    state.curveLine = [];
    state.anchorLine = [];
    state.viewXLim = [];
    state.viewYLim = [];
    state.onChanged = optionValue(opts, 'onChanged', []);
    state.onTrace = optionValue(opts, 'onTrace', []);
    state.session = runtime.createSession(struct( ...
        'name', 'anchorCurveEditor', ...
        'onPointerDown', @onAxesClicked, ...
        'onScroll', @onScrollZoom, ...
        'installScrollWheel', state.installScrollWheel));

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
    trace('created anchor curve editor');

    function start(points)
        trace(sprintf('start inputPoints=%d', pointCount(points)));
        if nargin >= 1 && ~isempty(points)
            state.points = normalizePoints(points);
        end
        setActive(true);
        notifyChanged('start');
    end

    function setActive(enabled)
        trace(sprintf('setActive %d', logical(enabled)));
        if logical(enabled)
            state.session.activate();
        else
            state.session.deactivate();
        end
    end

    function setPoints(points)
        trace(sprintf('setPoints %d', pointCount(points)));
        state.points = normalizePoints(points);
        refresh();
        notifyChanged('set points');
    end

    function points = getPoints()
        points = state.points;
    end

    function clearPoints()
        trace('clearPoints');
        state.points = zeros(0, 2);
        state.dragIndex = [];
        refresh();
        notifyChanged('clear points');
    end

    function undoLast()
        trace(sprintf('undoLast currentPoints=%d', size(state.points, 1)));
        if isempty(state.points)
            return;
        end
        state.points(end, :) = [];
        refresh();
        notifyChanged('undo point');
    end

    function insertPoint(point)
        trace(sprintf('insertPoint %.6g %.6g', point(1), point(2)));
        state.points = addOrInsertAnchor(state.points, point, state.ax, ...
            state.imageSize, state.style, state.closed, state.maxPoints);
        refresh();
        notifyChanged('add point');
    end

    function setStyle(style)
        style = string(style);
        trace(sprintf('setStyle %s', char(style)));
        if state.style == style
            trace('setStyle skipped unchanged');
            return;
        end
        state.style = style;
        refresh();
        notifyChanged('style changed');
    end

    function setImageSize(imageSize)
        trace(sprintf('setImageSize %s', sizeText(imageSize)));
        state.imageSize = imageSize;
        refresh();
    end

    function setBackground(h)
        trace(sprintf('setBackground valid=%d', isValidHandle(h)));
        state.session.setBackground(h);
    end

    function refresh()
        trace(sprintf('refresh active=%d points=%d', ...
            state.session.isActive(), size(state.points, 1)));
        ensureGraphics();
        state.session.setGraphics([state.curveLine state.anchorLine]);
        state.session.refresh();
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
        trace('deleteEditor');
        state.session.delete();
        if ~isempty(state.curveLine) && isvalid(state.curveLine)
            delete(state.curveLine);
        end
        if ~isempty(state.anchorLine) && isvalid(state.anchorLine)
            delete(state.anchorLine);
        end
        enableAxesPopout(state.ax);
    end

    function onAxesClicked(~, ~)
        trace(sprintf('onAxesClicked active=%d imageSizeEmpty=%d', ...
            state.session.isActive(), isempty(state.imageSize)));
        if ~state.session.isActive() || isempty(state.imageSize)
            return;
        end
        if strcmp(state.fig.SelectionType, 'alt') || strcmp(state.fig.SelectionType, 'extend')
            trace(sprintf('onAxesClicked ignored selection=%s', state.fig.SelectionType));
            return;
        end

        point = state.ax.CurrentPoint;
        x = point(1, 1);
        y = point(1, 2);
        if ~insideImageBounds(x, y, state.imageSize)
            trace(sprintf('onAxesClicked out of bounds x=%.6g y=%.6g', x, y));
            return;
        end

        idx = nearestAnchor(x, y);
        if strcmp(state.fig.SelectionType, 'open')
            if ~isempty(idx)
                trace(sprintf('onAxesClicked double-delete idx=%d', idx));
                state.points(idx, :) = [];
                refresh();
                notifyChanged('delete point');
            else
                trace(sprintf('onAxesClicked double-add x=%.6g y=%.6g', x, y));
                state.points = addOrInsertAnchor(state.points, [x y], state.ax, ...
                    state.imageSize, state.style, state.closed, state.maxPoints);
                refresh();
                notifyChanged('add point');
            end
            return;
        end

        if ~isempty(idx)
            trace(sprintf('onAxesClicked drag idx=%d', idx));
            state.dragIndex = idx;
            updateDraggedAnchor();
            state.session.captureDrag(@onAnchorDragged, @onAnchorReleased);
        end
    end

    function onAnchorDragged(~, ~)
        trace('onAnchorDragged');
        updateDraggedAnchor();
    end

    function onAnchorReleased(~, ~)
        trace('onAnchorReleased');
        updateDraggedAnchor();
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
            trace('ensureGraphics create curveLine');
            state.curveLine = line(state.ax, NaN, NaN, ...
                'Color', [0 0.45 0.95], ...
                'LineWidth', 1.5, ...
                'ButtonDownFcn', [], ...
                'HitTest', 'off', ...
                'PickableParts', 'none');
            created = true;
        end

        if isempty(state.anchorLine) || ~isvalid(state.anchorLine)
            trace('ensureGraphics create anchorLine');
            state.anchorLine = line(state.ax, NaN, NaN, ...
                'LineStyle', 'none', ...
                'Marker', 'o', ...
                'MarkerSize', 7, ...
                'Color', [1 0.85 0], ...
                'MarkerFaceColor', [0 0.45 0.95], ...
                'ButtonDownFcn', [], ...
                'HitTest', 'off', ...
                'PickableParts', 'none');
            created = true;
        end
        if created
            enableAxesPopout(state.ax);
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
        trace(sprintf('notifyChanged reason=%s points=%d', ...
            char(string(reason)), size(state.points, 1)));
        state.onChanged(state.points, reason);
    end

    function trace(message)
        if isempty(state.onTrace)
            return;
        end
        state.onTrace(sprintf('anchorCurveEditor: %s', char(message)));
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
    bounds = [0.5, imageSize(2) + 0.5, 0.5, imageSize(1) + 0.5];
    labkit.ui.tool.zoomAxesAtPoint(ax, [x, y], scrollCount, ...
        "Bounds", bounds);
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
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end

function n = pointCount(points)
    if isempty(points)
        n = 0;
    elseif isnumeric(points) && ndims(points) == 2
        n = size(points, 1);
    else
        n = numel(points);
    end
end

function txt = sizeText(value)
    if isempty(value)
        txt = '[]';
        return;
    end
    dims = size(value);
    if isvector(value) && numel(value) <= 4
        dims = value(:).';
    end
    txt = strjoin(cellstr(string(dims)), 'x');
end

function tf = isValidHandle(h)
    tf = ~isempty(h) && all(isvalid(h));
end

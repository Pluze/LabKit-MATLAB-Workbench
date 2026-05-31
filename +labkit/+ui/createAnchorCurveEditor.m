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

    if nargin < 3
        opts = struct();
    end

    state = struct();
    state.ax = ax;
    state.fig = optionValue(opts, 'figure', ancestor(ax, 'figure'));
    state.imageSize = imageSize;
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
            state.ax.ButtonDownFcn = @onAxesClicked;
            if state.installScrollWheel && ~isempty(state.fig) && isvalid(state.fig)
                state.fig.WindowScrollWheelFcn = @onScrollZoom;
            end
        else
            state.ax.ButtonDownFcn = [];
        end
        updateBackgroundHitTest();
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
            if state.installScrollWheel && ~isempty(state.fig) && isvalid(state.fig)
                state.fig.WindowScrollWheelFcn = @onScrollZoom;
            end
        end
        updateBackgroundHitTest();
        ensureGraphics();
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
        if state.installScrollWheel && ~isempty(state.fig) && isvalid(state.fig)
            state.fig.WindowScrollWheelFcn = [];
        end
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
        state.fig.WindowButtonMotionFcn = '';
        state.fig.WindowButtonUpFcn = '';
        state.dragIndex = [];
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
        if isempty(state.curveLine) || ~isvalid(state.curveLine)
            state.curveLine = line(state.ax, NaN, NaN, ...
                'Color', [0 0.45 0.95], ...
                'LineWidth', 1.5, ...
                'ButtonDownFcn', @onAxesClicked, ...
                'HitTest', 'on', ...
                'PickableParts', 'visible');
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
        end
        labkit.ui.enableAxesPopout(state.ax);
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

function curve = anchorCurvePoints(points, imageSize, curveStyle, closed)
    minCount = 2;
    if closed
        minCount = 3;
    end
    if size(points, 1) < minCount
        curve = [];
        return;
    end

    if strcmp(string(curveStyle), "Straight lines")
        if closed
            curve = [points; points(1, :)];
        else
            curve = points;
        end
        curve = clampCurve(curve, imageSize);
        return;
    end

    if closed
        curve = closedCatmullRom(points, imageSize);
    else
        curve = openCatmullRom(points, imageSize);
    end
end

function curve = closedCatmullRom(points, imageSize)
    n = size(points, 1);
    samplesPerSegment = max(12, ceil(240 / n));
    curve = zeros(n * samplesPerSegment + 1, 2);
    out = 1;
    for i = 1:n
        p0 = points(wrapIndex(i - 1, n), :);
        p1 = points(i, :);
        p2 = points(wrapIndex(i + 1, n), :);
        p3 = points(wrapIndex(i + 2, n), :);
        for k = 0:(samplesPerSegment - 1)
            t = k / samplesPerSegment;
            curve(out, :) = catmullRomPoint(p0, p1, p2, p3, t);
            out = out + 1;
        end
    end
    curve(out, :) = curve(1, :);
    curve = clampCurve(curve(1:out, :), imageSize);
end

function curve = openCatmullRom(points, imageSize)
    n = size(points, 1);
    if n < 3
        curve = clampCurve(points, imageSize);
        return;
    end

    samplesPerSegment = max(12, ceil(240 / max(1, n - 1)));
    curve = zeros((n - 1) * samplesPerSegment + 1, 2);
    out = 1;
    for i = 1:(n - 1)
        p0 = points(max(1, i - 1), :);
        p1 = points(i, :);
        p2 = points(i + 1, :);
        p3 = points(min(n, i + 2), :);
        for k = 0:(samplesPerSegment - 1)
            t = k / samplesPerSegment;
            curve(out, :) = catmullRomPoint(p0, p1, p2, p3, t);
            out = out + 1;
        end
    end
    curve(out, :) = points(end, :);
    curve = clampCurve(curve(1:out, :), imageSize);
end

function p = catmullRomPoint(p0, p1, p2, p3, t)
    p = 0.5 .* ((2 .* p1) + ...
        (-p0 + p2) .* t + ...
        (2 .* p0 - 5 .* p1 + 4 .* p2 - p3) .* t.^2 + ...
        (-p0 + 3 .* p1 - 3 .* p2 + p3) .* t.^3);
end

function curve = clampCurve(curve, imageSize)
    curve(:, 1) = min(max(curve(:, 1), 0.5), imageSize(2) + 0.5);
    curve(:, 2) = min(max(curve(:, 2), 0.5), imageSize(1) + 0.5);
end

function idx = wrapIndex(idx, n)
    idx = mod(idx - 1, n) + 1;
end

function points = addOrInsertAnchor(points, newPoint, ax, imageSize, curveStyle, closed, maxPoints)
    n = size(points, 1);
    if n < 2
        points(end+1, :) = newPoint;
        return;
    end

    if isfinite(maxPoints) && n >= maxPoints
        idx = nearestPointIndex(points, newPoint);
        points(idx, :) = newPoint;
        return;
    end

    if ~closed
        insertIdx = selfIntersectionAwareOpenPathInsertion(points, newPoint);
        points = [points(1:insertIdx, :); newPoint; points((insertIdx + 1):end, :)];
        return;
    end

    [segmentIdx, distance] = nearestVisibleSegment(points, newPoint, imageSize, curveStyle, closed);
    xSpan = max(1, diff(ax.XLim));
    ySpan = max(1, diff(ax.YLim));
    threshold = 0.10 * max(xSpan, ySpan);
    if isempty(segmentIdx)
        points(end+1, :) = newPoint;
        return;
    end

    if closed
        points = [points(1:segmentIdx, :); newPoint; points((segmentIdx + 1):end, :)];
        return;
    end

    if distance > threshold
        points(end+1, :) = newPoint;
        return;
    end

    points = [points(1:segmentIdx, :); newPoint; points((segmentIdx + 1):end, :)];
end

function idx = nearestPointIndex(points, point)
    [~, idx] = min(hypot(points(:, 1) - point(1), points(:, 2) - point(2)));
end

function insertIdx = selfIntersectionAwareOpenPathInsertion(points, point)
    n = size(points, 1);
    bestIntersections = inf;
    bestLength = inf;
    insertIdx = n;
    for k = 0:n
        candidate = [points(1:k, :); point; points((k + 1):end, :)];
        intersections = polylineSelfIntersectionCount(candidate);
        pathLength = openPathLength(candidate);
        if intersections < bestIntersections || ...
                (intersections == bestIntersections && pathLength < bestLength)
            bestIntersections = intersections;
            bestLength = pathLength;
            insertIdx = k;
        end
    end
end

function total = openPathLength(points)
    total = sum(hypot(diff(points(:, 1)), diff(points(:, 2))));
end

function count = polylineSelfIntersectionCount(points)
    count = 0;
    n = size(points, 1);
    if n < 4
        return;
    end
    for i = 1:(n - 2)
        for j = (i + 2):(n - 1)
            if segmentsIntersect(points(i, :), points(i + 1, :), ...
                    points(j, :), points(j + 1, :))
                count = count + 1;
            end
        end
    end
end

function tf = segmentsIntersect(a, b, c, d)
    epsTol = 1e-9;
    if min(norm(a - c), min(norm(a - d), min(norm(b - c), norm(b - d)))) <= epsTol
        tf = false;
        return;
    end

    o1 = segmentOrientation(a, b, c);
    o2 = segmentOrientation(a, b, d);
    o3 = segmentOrientation(c, d, a);
    o4 = segmentOrientation(c, d, b);
    tf = (o1 * o2 < -epsTol) && (o3 * o4 < -epsTol);
end

function value = segmentOrientation(a, b, c)
    value = (b(1) - a(1)) * (c(2) - a(2)) - ...
        (b(2) - a(2)) * (c(1) - a(1));
end

function [segmentIdx, bestDistance] = nearestVisibleSegment(points, point, imageSize, curveStyle, closed)
    segmentIdx = [];
    bestDistance = inf;
    n = size(points, 1);
    if n < 2
        return;
    end

    [curve, owners] = anchorCurvePointsWithOwners(points, imageSize, curveStyle, closed);
    if size(curve, 1) < 2
        return;
    end

    for k = 1:(size(curve, 1) - 1)
        distance = pointSegmentDistance(point, curve(k, :), curve(k + 1, :));
        if distance < bestDistance
            bestDistance = distance;
            segmentIdx = owners(k);
        end
    end
end

function [curve, owners] = anchorCurvePointsWithOwners(points, imageSize, curveStyle, closed)
    minCount = 2;
    if closed
        minCount = 3;
    end
    if size(points, 1) < minCount
        curve = [];
        owners = [];
        return;
    end

    if strcmp(string(curveStyle), "Straight lines")
        [curve, owners] = straightCurveWithOwners(points, imageSize, closed);
        return;
    end

    if closed
        [curve, owners] = closedCatmullRomWithOwners(points, imageSize);
    else
        [curve, owners] = openCatmullRomWithOwners(points, imageSize);
    end
end

function [curve, owners] = straightCurveWithOwners(points, imageSize, closed)
    n = size(points, 1);
    if closed
        curve = [points; points(1, :)];
        owners = (1:n).';
    else
        curve = points;
        owners = (1:(n - 1)).';
    end
    curve = clampCurve(curve, imageSize);
end

function [curve, owners] = closedCatmullRomWithOwners(points, imageSize)
    n = size(points, 1);
    samplesPerSegment = max(12, ceil(240 / n));
    curve = zeros(n * samplesPerSegment + 1, 2);
    out = 1;
    for i = 1:n
        p0 = points(wrapIndex(i - 1, n), :);
        p1 = points(i, :);
        p2 = points(wrapIndex(i + 1, n), :);
        p3 = points(wrapIndex(i + 2, n), :);
        for k = 0:(samplesPerSegment - 1)
            t = k / samplesPerSegment;
            curve(out, :) = catmullRomPoint(p0, p1, p2, p3, t);
            out = out + 1;
        end
    end
    curve(out, :) = curve(1, :);
    curve = clampCurve(curve(1:out, :), imageSize);
    owners = repelem((1:n).', samplesPerSegment);
end

function [curve, owners] = openCatmullRomWithOwners(points, imageSize)
    n = size(points, 1);
    if n < 3
        [curve, owners] = straightCurveWithOwners(points, imageSize, false);
        return;
    end

    samplesPerSegment = max(12, ceil(240 / max(1, n - 1)));
    curve = zeros((n - 1) * samplesPerSegment + 1, 2);
    out = 1;
    for i = 1:(n - 1)
        p0 = points(max(1, i - 1), :);
        p1 = points(i, :);
        p2 = points(i + 1, :);
        p3 = points(min(n, i + 2), :);
        for k = 0:(samplesPerSegment - 1)
            t = k / samplesPerSegment;
            curve(out, :) = catmullRomPoint(p0, p1, p2, p3, t);
            out = out + 1;
        end
    end
    curve(out, :) = points(end, :);
    curve = clampCurve(curve(1:out, :), imageSize);
    owners = repelem((1:(n - 1)).', samplesPerSegment);
end

function distance = pointSegmentDistance(point, a, b)
    ab = b - a;
    denom = dot(ab, ab);
    if denom <= eps
        distance = hypot(point(1) - a(1), point(2) - a(2));
        return;
    end
    t = dot(point - a, ab) / denom;
    t = min(max(t, 0), 1);
    projection = a + t .* ab;
    distance = hypot(point(1) - projection(1), point(2) - projection(2));
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

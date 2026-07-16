% Private anchor-editor insertion helper. Expected caller:
% createAnchorEditor. Inputs are existing and candidate image-pixel
% anchor coordinates plus axes/image/style constraints; output is the updated
% N-by-2 anchor array. No graphics or app state are mutated.
function points = addOrInsertAnchor(points, newPoint, ax, imageSize, curveStyle, closed, maxPoints)
%ADDORINSERTANCHOR Apply anchor insertion policy for createAnchorCurveEditor.
%
% Expected caller:
%   createAnchorEditor when users double-click/add anchors.
%
% Inputs:
%   points - existing N-by-2 normalized anchor coordinates.
%   newPoint - 1-by-2 candidate anchor coordinate.
%   ax - axes handle used only for current view-dependent insertion thresholds.
%   imageSize - image size vector used for curve clamping.
%   curveStyle - "Curve" or "Straight lines".
%   closed - logical; true inserts into the nearest closed visible segment.
%   maxPoints - maximum anchor count; existing anchors are replaced when full.
%
% Output:
%   points - updated N-by-2 anchor coordinates.
%
% Side effects:
%   None. This helper does not mutate graphics or app state.

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
        points = addOrInsertOpenAnchor(points, newPoint, ax, imageSize, curveStyle);
        return;
    end

    [segmentIdx, ~] = nearestVisibleSegment(points, newPoint, imageSize, curveStyle, closed);
    if isempty(segmentIdx)
        points(end+1, :) = newPoint;
        return;
    end

    points = insertAnchorAfterSegment(points, newPoint, segmentIdx);
end

function idx = nearestPointIndex(points, point)
    [~, idx] = min(hypot(points(:, 1) - point(1), points(:, 2) - point(2)));
end

function points = addOrInsertOpenAnchor(points, newPoint, ax, imageSize, curveStyle)
    firstDistance = hypot(newPoint(1) - points(1, 1), newPoint(2) - points(1, 2));
    lastDistance = hypot(newPoint(1) - points(end, 1), newPoint(2) - points(end, 2));
    [segmentIdx, segmentDistance] = nearestVisibleSegment(points, newPoint, imageSize, curveStyle, false);
    segmentThreshold = anchorInsertionThreshold(ax, 0.025, 6, 30);
    correctionThreshold = anchorInsertionThreshold(ax, 0.045, 10, 55);

    if ~isempty(segmentIdx) && segmentDistance <= segmentThreshold && ...
            segmentDistance <= min(firstDistance, lastDistance) * 0.45
        points = insertAnchorAfterSegment(points, newPoint, segmentIdx);
        return;
    end

    endpointThreshold = anchorInsertionThreshold(ax, 0.08, 12, 80);
    if min(firstDistance, lastDistance) <= endpointThreshold
        if firstDistance < lastDistance
            endpointPoints = [newPoint; points];
            prepend = true;
        else
            endpointPoints = [points; newPoint];
            prepend = false;
        end
        if endpointExtensionIntersectsVisiblePath( ...
                points, newPoint, imageSize, curveStyle, prepend) && ...
                ~isempty(segmentIdx) && segmentDistance <= correctionThreshold
            points = insertAnchorAfterSegment(points, newPoint, segmentIdx);
        else
            points = endpointPoints;
        end
        return;
    end

    if ~isempty(segmentIdx) && segmentDistance <= segmentThreshold
        points = insertAnchorAfterSegment(points, newPoint, segmentIdx);
        return;
    end

    points(end+1, :) = newPoint;
end

function points = insertAnchorAfterSegment(points, newPoint, segmentIdx)
    points = [points(1:segmentIdx, :); newPoint; points((segmentIdx + 1):end, :)];
end

function threshold = anchorInsertionThreshold(ax, fraction, minPixels, maxPixels)
    xSpan = max(1, diff(ax.XLim));
    ySpan = max(1, diff(ax.YLim));
    threshold = min(maxPixels, max(minPixels, fraction * max(xSpan, ySpan)));
end

function [segmentIdx, bestDistance] = nearestVisibleSegment(points, point, imageSize, curveStyle, closed)
    segmentIdx = [];
    bestDistance = inf;
    n = size(points, 1);
    if n < 2
        return;
    end

    [curve, owners] = labkit.ui.interaction.anchorPath(points, imageSize, ...
        "Style", string(curveStyle), "Closed", closed);
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

function tf = endpointExtensionIntersectsVisiblePath(points, newPoint, imageSize, curveStyle, prepend)
    tf = false;
    n = size(points, 1);
    if n < 3
        return;
    end

    if prepend
        a = newPoint;
        b = points(1, :);
        adjacentOwner = 1;
    else
        a = points(end, :);
        b = newPoint;
        adjacentOwner = n - 1;
    end

    [curve, owners] = labkit.ui.interaction.anchorPath(points, imageSize, ...
        "Style", string(curveStyle), "Closed", false);
    if size(curve, 1) < 2
        return;
    end

    for k = 1:(size(curve, 1) - 1)
        if owners(k) == adjacentOwner
            continue;
        end
        if segmentsIntersect(a, b, curve(k, :), curve(k + 1, :))
            tf = true;
            return;
        end
    end
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

function tf = segmentsIntersect(a, b, c, d)
    % Constant: 1e-9 coordinate units absorbs floating-point orientation
    % noise without changing visible anchor-curve intersections.
    intersectionTolerance = 1e-9;
    if max(min(a(1), b(1)), min(c(1), d(1))) > ...
            min(max(a(1), b(1)), max(c(1), d(1))) + intersectionTolerance || ...
            max(min(a(2), b(2)), min(c(2), d(2))) > ...
            min(max(a(2), b(2)), max(c(2), d(2))) + intersectionTolerance
        tf = false;
        return;
    end

    o1 = orient2d(a, b, c);
    o2 = orient2d(a, b, d);
    o3 = orient2d(c, d, a);
    o4 = orient2d(c, d, b);

    tf = (oppositeSigns(o1, o2, intersectionTolerance) && ...
        oppositeSigns(o3, o4, intersectionTolerance)) || ...
        (abs(o1) <= intersectionTolerance && ...
        pointOnSegment(c, a, b, intersectionTolerance)) || ...
        (abs(o2) <= intersectionTolerance && ...
        pointOnSegment(d, a, b, intersectionTolerance)) || ...
        (abs(o3) <= intersectionTolerance && ...
        pointOnSegment(a, c, d, intersectionTolerance)) || ...
        (abs(o4) <= intersectionTolerance && ...
        pointOnSegment(b, c, d, intersectionTolerance));
end

function value = orient2d(a, b, c)
    value = (b(1) - a(1)) * (c(2) - a(2)) - ...
        (b(2) - a(2)) * (c(1) - a(1));
end

function tf = oppositeSigns(a, b, tol)
    tf = (a > tol && b < -tol) || (a < -tol && b > tol);
end

function tf = pointOnSegment(p, a, b, tol)
    tf = p(1) >= min(a(1), b(1)) - tol && ...
        p(1) <= max(a(1), b(1)) + tol && ...
        p(2) >= min(a(2), b(2)) - tol && ...
        p(2) <= max(a(2), b(2)) + tol;
end

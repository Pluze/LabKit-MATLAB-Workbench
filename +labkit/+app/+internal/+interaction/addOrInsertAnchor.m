% Internal anchor-path insertion policy. Expected caller: the native anchor
% editor. Inputs are ordered image-pixel anchors, one candidate point, image
% geometry, curve style, closure, and point limit. Output is the updated
% ordered anchor array. Side effects: none.
function points = addOrInsertAnchor( ...
        points, newPoint, imageSize, curveStyle, closed, maxPoints)
%ADDORINSERTANCHOR Add a point at its nearest visible path location.

% Open paths use the nearest location on the complete visible curve. A point
% whose nearest location is the first or last path endpoint extends that end;
% every other point is inserted after the owning visible segment. This avoids
% view-size thresholds that could make the same click append or insert after
% zooming. Closed paths always insert after the nearest visible segment.

% Expected caller:
%   The private native anchor editor used by anchorPath interactions.

% Inputs:
%   points - Existing N-by-2 ordered anchor coordinates.
%   newPoint - Candidate 1-by-2 image-pixel coordinate.
%   imageSize - Image size vector beginning with height and width.
%   curveStyle - "Curve" or "Straight lines".
%   closed - Logical scalar selecting an open or closed path.
%   maxPoints - Positive integer or Inf. At capacity, the nearest anchor is
%       replaced instead of growing the collection.

% Outputs:
%   points - Updated N-by-2 ordered anchor coordinates.

% Side effects:
%   None.

    n = size(points, 1);
    if n < 2
        points(end + 1, :) = newPoint;
        return;
    end

    if isfinite(maxPoints) && n >= maxPoints
        idx = nearestPointIndex(points, newPoint);
        points(idx, :) = newPoint;
        return;
    end

    [segmentIdx, endpoint] = nearestVisibleLocation( ...
        points, newPoint, imageSize, curveStyle, closed);
    if isempty(segmentIdx)
        points(end + 1, :) = newPoint;
        return;
    end

    if closed || endpoint == "interior"
        points = insertAnchorAfterSegment(points, newPoint, segmentIdx);
        return;
    end

    if endpoint == "start"
        points = [newPoint; points];
    else
        points = [points; newPoint];
    end
end

function idx = nearestPointIndex(points, point)
    [~, idx] = min(hypot(points(:, 1) - point(1), ...
        points(:, 2) - point(2)));
end

function points = insertAnchorAfterSegment(points, newPoint, segmentIdx)
    points = [points(1:segmentIdx, :); newPoint; ...
        points((segmentIdx + 1):end, :)];
end

function [segmentIdx, endpoint] = nearestVisibleLocation( ...
        points, point, imageSize, curveStyle, closed)
    segmentIdx = [];
    endpoint = "interior";
    [curve, owners] = labkit.app.interaction.interpolateAnchorPath( ...
        points, imageSize, "Style", string(curveStyle), "Closed", closed);
    segmentCount = size(curve, 1) - 1;
    if segmentCount < 1
        return;
    end

    bestDistance = inf;
    bestCurveSegment = 0;
    bestFraction = 0;
    for index = 1:segmentCount
        [distance, fraction] = pointSegmentDistance( ...
            point, curve(index, :), curve(index + 1, :));
        if distance < bestDistance
            bestDistance = distance;
            bestCurveSegment = index;
            bestFraction = fraction;
        end
    end
    segmentIdx = owners(bestCurveSegment);
    if closed
        return;
    end

    endpointTolerance = 1e-9;
    if bestCurveSegment == 1 && bestFraction <= endpointTolerance
        endpoint = "start";
    elseif bestCurveSegment == segmentCount && ...
            bestFraction >= 1 - endpointTolerance
        endpoint = "end";
    end
end

function [distance, fraction] = pointSegmentDistance(point, a, b)
    ab = b - a;
    denom = dot(ab, ab);
    if denom <= eps
        fraction = 0;
        distance = hypot(point(1) - a(1), point(2) - a(2));
        return;
    end
    fraction = dot(point - a, ab) / denom;
    fraction = min(max(fraction, 0), 1);
    projection = a + fraction .* ab;
    distance = hypot(point(1) - projection(1), ...
        point(2) - projection(2));
end

% Private anchor-editor path builder. Expected caller:
% labkit.ui.tool.anchorEditor and insertion helpers. Inputs are N-by-2
% image-pixel anchors, image size, curve style, and closed/open mode; outputs
% are display curve samples and segment-owner indices. No side effects.
function [curve, owners] = anchorCurvePoints(points, imageSize, curveStyle, closed)
%ANCHORCURVEPOINTS Build displayed anchor path samples for curve editors.
%
% Expected caller:
%   labkit.ui.tool.anchorEditor and sibling private insertion helpers.
%
% Inputs:
%   points - N-by-2 anchor coordinates in image pixel coordinates.
%   imageSize - image size vector with height in element 1 and width in element 2.
%   curveStyle - "Curve" or "Straight lines".
%   closed - logical; true closes the visible path.
%
% Outputs:
%   curve - M-by-2 displayed path samples, clamped to image bounds.
%   owners - (M-1)-by-1 anchor-segment owner indices for each visible segment.
%
% Side effects:
%   None. The helper assumes points are already normalized numeric coordinates.

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

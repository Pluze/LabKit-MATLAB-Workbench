% Expected caller: DIC preprocess runner and direct unit tests. Inputs are ROI
% anchor points, image size, and the boundary style label. Output is a closed,
% image-clamped curve suitable for mask rasterization. Side effects: none.

function curve = maskBoundaryCurve(points, imageSize, boundaryStyle)
%MASKBOUNDARYCURVE Build a closed ROI mask boundary curve.

    if size(points, 1) < 3
        curve = [];
        return;
    end
    if strcmp(string(boundaryStyle), "Straight lines")
        curve = [points; points(1, :)];
        curve(:, 1) = min(max(curve(:, 1), 0.5), imageSize(2) + 0.5);
        curve(:, 2) = min(max(curve(:, 2), 0.5), imageSize(1) + 0.5);
        return;
    end

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
    curve = curve(1:out, :);
    curve(:, 1) = min(max(curve(:, 1), 0.5), imageSize(2) + 0.5);
    curve(:, 2) = min(max(curve(:, 2), 0.5), imageSize(1) + 0.5);
end

function p = catmullRomPoint(p0, p1, p2, p3, t)
    p = 0.5 .* ((2 .* p1) + ...
        (-p0 + p2) .* t + ...
        (2 .* p0 - 5 .* p1 + 4 .* p2 - p3) .* t.^2 + ...
        (-p0 + 3 .* p1 - 3 .* p2 + p3) .* t.^3);
end

function idx = wrapIndex(idx, n)
    idx = mod(idx - 1, n) + 1;
end

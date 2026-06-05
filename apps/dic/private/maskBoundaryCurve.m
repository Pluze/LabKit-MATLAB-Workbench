% App-owned DIC helper extracted from labkit_DICPreprocess_app.m. Expected caller: DIC app entrypoints.
% Inputs, outputs, and side effects match the original local helper implementation.
function curve = maskBoundaryCurve(points, imageSize, boundaryStyle)
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

%TRACKPOINTS Predict ordered points in the next frame with pyramidal KLT.
% Expected callers are Video Marker forward propagation and focused tests.
% Inputs are same-sized RGB/grayscale frames, N-by-2 source points, and an
% optional N-by-2 constant-velocity fallback. Outputs preserve point order and
% return per-point confidence plus diagnostics. Computer Vision Toolbox is
% used when available; otherwise the constant-velocity fallback is returned.
function [points, confidence, diagnostics] = trackPoints( ...
        previousImage, currentImage, previousPoints, priorDisplacement)
    if ~isequal(size(previousImage), size(currentImage))
        error('labkit_VideoMarker_app:FrameSizeMismatch', ...
            'Motion estimation requires consecutive frames with the same size.');
    end
    previousPoints = double(previousPoints);
    if size(previousPoints, 2) ~= 2 || any(~isfinite(previousPoints(:)))
        error('labkit_VideoMarker_app:InvalidTrackingPoints', ...
            'Previous-frame points must be a finite N-by-2 array.');
    end
    pointCount = size(previousPoints, 1);
    if nargin < 4 || isempty(priorDisplacement)
        priorDisplacement = zeros(pointCount, 2);
    end
    priorDisplacement = expandPriorDisplacements(priorDisplacement, pointCount);
    fallback = clampPoints(previousPoints + priorDisplacement, size(currentImage));
    points = fallback;
    confidence = zeros(pointCount, 1);
    diagnostics = struct('engine', "constant_velocity", ...
        'valid', false(pointCount, 1), 'failureMessage', "");
    if pointCount == 0
        return;
    end
    if exist('vision.PointTracker', 'class') ~= 8
        diagnostics.failureMessage = "Computer Vision Toolbox point tracker is unavailable.";
        return;
    end

    % Constant: 48 pixels keeps the KLT neighborhood and four image-pyramid
    % levels away from an ordinary ROI crop boundary while avoiding full-frame
    % processing for a compact skeleton.
    cropMargin = 48;
    [rows, columns, offset] = trackingCrop(previousPoints, fallback, ...
        size(previousImage), cropMargin);
    previousCrop = previousImage(rows, columns, :);
    currentCrop = currentImage(rows, columns, :);
    localPoints = previousPoints - offset;

    % Constants: these values follow the documented KLT operating range. Four
    % pyramid levels cover larger articulated motion; a 31-pixel neighborhood
    % retains joint texture; 2.5 pixels rejects inconsistent forward/backward
    % tracks without treating subpixel refinement as a failure.
    blockSize = [31 31];
    pyramidLevels = 4;
    maximumIterations = 30;
    maximumBidirectionalError = 2.5;
    try
        tracker = vision.PointTracker( ...
            'BlockSize', blockSize, ...
            'NumPyramidLevels', pyramidLevels, ...
            'MaxIterations', maximumIterations, ...
            'MaxBidirectionalError', maximumBidirectionalError);
        cleanup = onCleanup(@() releaseTracker(tracker));
        initialize(tracker, localPoints, previousCrop);
        [tracked, valid, scores] = tracker(currentCrop);
        tracked = tracked + offset;
        tracked = clampPoints(tracked, size(currentImage));
        points(valid, :) = tracked(valid, :);
        confidence(valid) = double(scores(valid));
        diagnostics.engine = "pyramidal_klt";
        diagnostics.valid = logical(valid(:));
        clear cleanup
    catch ME
        diagnostics.failureMessage = string(ME.message);
    end
end

function prior = expandPriorDisplacements(prior, pointCount)
    prior = double(prior);
    if isequal(size(prior), [1 2])
        prior = repmat(prior, pointCount, 1);
    end
    if ~isequal(size(prior), [pointCount 2]) || any(~isfinite(prior(:)))
        error('labkit_VideoMarker_app:InvalidMotionPrior', ...
            'Motion prior must be finite N-by-2 displacements.');
    end
end

function [rows, columns, offset] = trackingCrop(source, predicted, imageSize, margin)
    allPoints = [source; predicted];
    x1 = max(1, floor(min(allPoints(:, 1)) - margin));
    x2 = min(imageSize(2), ceil(max(allPoints(:, 1)) + margin));
    y1 = max(1, floor(min(allPoints(:, 2)) - margin));
    y2 = min(imageSize(1), ceil(max(allPoints(:, 2)) + margin));
    rows = y1:y2;
    columns = x1:x2;
    offset = [x1 - 1, y1 - 1];
end

function points = clampPoints(points, imageSize)
    points(:, 1) = min(max(points(:, 1), 1), imageSize(2));
    points(:, 2) = min(max(points(:, 2), 1), imageSize(1));
end

function releaseTracker(tracker)
    try
        release(tracker);
    catch
        % Tracker construction or initialization may have failed before lock.
    end
end

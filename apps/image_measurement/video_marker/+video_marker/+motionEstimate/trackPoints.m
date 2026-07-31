function [points, confidence, diagnostics] = trackPoints(previousImage, currentImage, previousPoints, priorDisplacement)
%TRACKPOINTS Track ordered image points between two consecutive video frames.
%
% Usage:
%   [points, confidence, diagnostics] = ...
%       video_marker.motionEstimate.trackPoints( ...
%       previousImage, currentImage, previousPoints)
%   [points, confidence, diagnostics] = ...
%       video_marker.motionEstimate.trackPoints( ...
%       previousImage, currentImage, previousPoints, priorDisplacement)
%
% Description:
%   Tracks each point with deterministic base-MATLAB multiscale patch matching.
%   A grayscale pyramid provides up to four resolution levels. At every level,
%   a 7-by-7 mean-centered template is compared by normalized correlation in a
%   plus-or-minus four-pixel search around the predicted location. A parabolic
%   peak fit refines the final match to subpixel coordinates.
%
%   Points are processed independently and preserve their input order. A flat,
%   out-of-frame, or weakly correlated patch is not treated as a hard error:
%   the output retains the clamped motion-prior prediction and reports zero
%   confidence for that point.
%
% Inputs:
%   previousImage - Finite numeric or logical grayscale or RGB source frame.
%   currentImage - Finite frame with exactly the same size as previousImage.
%   previousPoints - Finite N-by-2 array of [x y] coordinates in the previous
%       frame, where x is the column and y is the row. N may be zero.
%   priorDisplacement - Optional finite [dx dy] motion prediction. A 1-by-2
%       value is shared by all points; an N-by-2 array supplies one prior per
%       point. Default: zeros(N,2).
%
% Outputs:
%   points - N-by-2 tracked [x y] coordinates, limited to currentImage bounds.
%       Failed matches contain the limited previousPoints+priorDisplacement.
%   confidence - N-by-1 values in [0,1]. Accepted normalized-correlation scores
%       are mapped with (score+1)/2; failed matches are zero. A correlation of
%       at least 0.55 is required for acceptance.
%   diagnostics - Scalar structure with engine, valid, and failureMessage.
%       engine is "multiscale_patch". valid is an N-by-1 logical mask.
%       failureMessage is empty when every point succeeds and explains partial
%       tracking failure otherwise.
%
% Errors:
%   labkit_VideoMarker_app:FrameSizeMismatch - Frame arrays differ in size.
%   labkit_VideoMarker_app:InvalidTrackingPoints - previousPoints is not a
%       finite N-by-2 array.
%   labkit_VideoMarker_app:InvalidMotionPrior - priorDisplacement is neither a
%       finite 1-by-2 nor finite N-by-2 array.
%   labkit_VideoMarker_app:InvalidTrackingImage - A frame is not grayscale or
%       RGB after conversion, or contains nonfinite values.
%
% Example:
%   rng(7)
%   previousImage = rand(60, 70);
%   currentImage = circshift(previousImage, [-2 3]);
%   [point, confidence, diagnostics] = ...
%       video_marker.motionEstimate.trackPoints( ...
%       previousImage, currentImage, [35 30]);
%   assert(norm(point - [38 28]) < 0.5)
%   assert(confidence > 0.5 && diagnostics.valid)
%
% See also video_marker.motionEstimate.predictForward,
%   video_marker.frameAnnotations.setFramePoints

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
    diagnostics = struct('engine', "multiscale_patch", ...
        'valid', false(pointCount, 1), 'failureMessage', "");
    if pointCount == 0
        return;
    end

    previousGray = grayscaleDouble(previousImage);
    currentGray = grayscaleDouble(currentImage);

    % Constant: four half-resolution levels let a four-pixel local search
    % capture roughly 32 pixels of motion without scanning the full frame.
    maximumPyramidLevels = 4;
    [previousPyramid, currentPyramid] = buildPyramidPair( ...
        previousGray, currentGray, maximumPyramidLevels);

    % Constants: a seven-pixel template is large enough to distinguish local
    % texture at the coarsest level; a four-pixel search balances articulated
    % motion coverage and neighboring-feature confusion. Correlation below
    % 0.55 is treated as insufficient evidence and keeps the motion prior.
    patchRadius = 3;
    searchRadius = 4;
    minimumCorrelation = 0.55;
    for pointIndex = 1:pointCount
        [candidate, score, valid] = trackOnePoint( ...
            previousPyramid, currentPyramid, previousPoints(pointIndex, :), ...
            priorDisplacement(pointIndex, :), patchRadius, searchRadius);
        if valid && score >= minimumCorrelation
            points(pointIndex, :) = clampPoints(candidate, size(currentImage));
            confidence(pointIndex) = min(1, max(0, (score + 1) ./ 2));
            diagnostics.valid(pointIndex) = true;
        end
    end
    if ~all(diagnostics.valid)
        diagnostics.failureMessage = ...
            "One or more points lacked a distinctive in-frame image patch.";
    end
end

function image = grayscaleDouble(image)
    image = labkit.image.im2double(image);
    if ndims(image) == 3 && size(image, 3) == 3
        image = labkit.image.rgb2gray(image);
    elseif ~ismatrix(image)
        error('labkit_VideoMarker_app:InvalidTrackingImage', ...
            'Motion estimation requires a grayscale or RGB image.');
    end
    if any(~isfinite(image(:)))
        error('labkit_VideoMarker_app:InvalidTrackingImage', ...
            'Motion estimation images must contain finite values.');
    end
end

function [previousPyramid, currentPyramid] = buildPyramidPair( ...
        previousImage, currentImage, maximumLevels)
    previousPyramid = cell(1, maximumLevels);
    currentPyramid = cell(1, maximumLevels);
    previousPyramid{1} = previousImage;
    currentPyramid{1} = currentImage;
    levelCount = 1;
    for level = 2:maximumLevels
        previousNext = downsampleByTwo(previousPyramid{levelCount});
        currentNext = downsampleByTwo(currentPyramid{levelCount});
        % Constant: a seven-pixel template plus a four-pixel search needs an
        % eleven-pixel margin; stop before a pyramid level cannot contain it.
        minimumLevelSize = 23;
        if min(size(previousNext)) < minimumLevelSize
            break;
        end
        levelCount = levelCount + 1;
        previousPyramid{levelCount} = previousNext;
        currentPyramid{levelCount} = currentNext;
    end
    previousPyramid = previousPyramid(1:levelCount);
    currentPyramid = currentPyramid(1:levelCount);
end

function reduced = downsampleByTwo(image)
    lastRow = 2 * floor(size(image, 1) / 2);
    lastColumn = 2 * floor(size(image, 2) / 2);
    rowPairs = reshape(1:lastRow, 2, []);
    columnPairs = reshape(1:lastColumn, 2, []);
    oddRows = rowPairs(1, :);
    evenRows = rowPairs(2, :);
    oddColumns = columnPairs(1, :);
    evenColumns = columnPairs(2, :);
    reduced = (image(oddRows, oddColumns) + image(evenRows, oddColumns) + ...
        image(oddRows, evenColumns) + image(evenRows, evenColumns)) ./ 4;
end

function [point, score, valid] = trackOnePoint(previousPyramid, currentPyramid, ...
        sourcePoint, priorDisplacement, patchRadius, searchRadius)
    levelCount = numel(previousPyramid);
    displacement = priorDisplacement ./ (2 .^ (levelCount - 1));
    score = -Inf;
    valid = false;
    for level = levelCount:-1:1
        if level < levelCount
            displacement = displacement .* 2;
        end
        scale = 2 .^ (level - 1);
        sourceAtLevel = imagePointAtScale(sourcePoint, scale);
        predictedAtLevel = sourceAtLevel + displacement;
        [matchedAtLevel, levelScore, levelValid] = bestPatchMatch( ...
            previousPyramid{level}, currentPyramid{level}, sourceAtLevel, ...
            predictedAtLevel, patchRadius, searchRadius);
        if ~levelValid
            point = sourcePoint + priorDisplacement;
            return;
        end
        displacement = matchedAtLevel - sourceAtLevel;
        score = levelScore;
        valid = true;
    end
    point = sourcePoint + displacement;
end

function point = imagePointAtScale(point, scale)
    point = (point - 0.5) ./ scale + 0.5;
end

function [bestPoint, bestScore, valid] = bestPatchMatch( ...
        previousImage, currentImage, sourcePoint, predictedPoint, ...
        patchRadius, searchRadius)
    sourceCenter = round(sourcePoint);
    predictedCenter = round(predictedPoint);
    [template, templateValid] = patchAt(previousImage, sourceCenter, patchRadius);
    bestPoint = predictedPoint;
    bestScore = -Inf;
    valid = false;
    if ~templateValid
        return;
    end
    template = template - mean(template(:));
    templateEnergy = sqrt(sum(template(:) .^ 2));
    % Constant: near-zero energy marks a flat patch whose displacement is not
    % observable; the threshold is numerical, not an image-intensity policy.
    minimumPatchEnergy = 1e-10;
    if templateEnergy <= minimumPatchEnergy
        return;
    end
    scoreGrid = NaN(2 .* searchRadius + 1);
    for yOffset = -searchRadius:searchRadius
        for xOffset = -searchRadius:searchRadius
            candidate = predictedCenter + [xOffset yOffset];
            [patch, patchValid] = patchAt(currentImage, candidate, patchRadius);
            if ~patchValid
                continue;
            end
            patch = patch - mean(patch(:));
            patchEnergy = sqrt(sum(patch(:) .^ 2));
            if patchEnergy <= minimumPatchEnergy
                continue;
            end
            correlation = sum(template(:) .* patch(:)) / ...
                (templateEnergy * patchEnergy);
            scoreGrid(yOffset + searchRadius + 1, ...
                xOffset + searchRadius + 1) = correlation;
            if correlation > bestScore
                bestScore = correlation;
                bestPoint = double(candidate);
                valid = true;
            end
        end
    end
    if valid
        gridCenter = round(bestPoint - predictedCenter) + searchRadius + 1;
        xOffset = parabolicPeakOffset(scoreGrid(gridCenter(2), :), gridCenter(1));
        yOffset = parabolicPeakOffset(scoreGrid(:, gridCenter(1)), gridCenter(2));
        bestPoint = bestPoint + [xOffset yOffset];
    end
end

function offset = parabolicPeakOffset(scores, index)
    offset = 0;
    if index <= 1 || index >= numel(scores)
        return;
    end
    lower = scores(index - 1);
    center = scores(index);
    upper = scores(index + 1);
    denominator = lower - 2 .* center + upper;
    if any(~isfinite([lower center upper denominator])) || denominator >= 0
        return;
    end
    offset = 0.5 .* (lower - upper) ./ denominator;
    % Constant: the fitted peak belongs to this grid interval; limiting the
    % correction prevents a shallow noisy parabola from crossing a neighbor.
    maximumSubpixelOffset = 0.5;
    offset = min(max(offset, -maximumSubpixelOffset), maximumSubpixelOffset);
end

function [patch, valid] = patchAt(image, center, radius)
    columns = center(1) + (-radius:radius);
    rows = center(2) + (-radius:radius);
    valid = min(columns) >= 1 && max(columns) <= size(image, 2) && ...
        min(rows) >= 1 && max(rows) <= size(image, 1);
    if valid
        patch = image(rows, columns);
    else
        patch = [];
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

function points = clampPoints(points, imageSize)
    points(:, 1) = min(max(points(:, 1), 1), imageSize(2));
    points(:, 2) = min(max(points(:, 2), 1), imageSize(1));
end

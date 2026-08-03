function [alignedImage, tformRigid, method, quality] = autoAlignMovingToReference(referenceImage, movingImage)
%AUTOALIGNMOVINGTOREFERENCE Estimate and apply a rigid transform.
%
% Usage:
%   [alignedImage, transform, method, quality] = ...
%       dic_preprocess.analysisRun.autoAlignMovingToReference( ...
%       referenceImage, movingImage)
%
% Inputs:
%   referenceImage - Numeric grayscale or RGB reference image. Its first two
%       dimensions define the output canvas.
%   movingImage - Numeric grayscale or RGB image to register rigidly.
%
% Outputs:
%   alignedImage - Original movingImage rotated and translated onto the
%       reference canvas, with linear interpolation and zero fill.
%   tformRigid - Three-by-three row-vector homogeneous rigid transform,
%       shown as transform in the usage syntax.
%   method - Character vector identifying the fixed coarse-to-fine method.
%   quality - Scalar structure containing angleDegrees, translationX,
%       translationY, score, overlapFraction, scoreMargin, and
%       translationPeakMargin for the accepted match.
%
% Description:
%   Each image is converted to normalized grayscale independently. The search
%   covers the full rotation circle at six-degree spacing, then refines the
%   best neighborhood at one-degree and quarter-degree spacing. Anti-aliased
%   previews and zero-padded amplitude-weighted phase correlation provide subpixel
%   translation estimates. Candidates are ranked with robust, overlap-aware
%   oriented structure at a finer resolution. The accepted rotation and
%   translation are applied to the original moving image. Scale and
%   deformation are not estimated; repeated texture and large nonoverlap can
%   still produce a poor fit.
%
% Failure Behavior:
%   dic_preprocess:AutoAlignmentFailed - No candidate has a finite oriented
%       structural match, including uniform or otherwise uninformative pairs.
%   The function does not assign a confidence score or reject an ambiguous
%   registration peak; low-texture or repeated-pattern inputs can return a
%   numerically valid but poor transform. Empty arrays, unsupported image
%   classes, or invalid channel shapes propagate image conversion/interpolation
%   errors.
%
% Example:
%   reference = zeros(16); reference(5:8, 6:9) = 1;
%   moving = circshift(reference, [2 -3]);
%   [aligned, transform, method] = ...
%       dic_preprocess.analysisRun.autoAlignMovingToReference( ...
%       reference, moving);
%   assert(isequal(size(aligned), size(reference)))
%   assert(isequal(size(transform), [3 3]) && contains(method, "phase-correlation"))
%
% See also dic_preprocess.analysisRun.alignMovingToReference,
%   dic_preprocess.analysisRun.applyRigidTransform

    fixedGray = normalizeGray(referenceImage);
    movingGray = normalizeGray(movingImage);

    [tformRigid, quality] = estimateRigidTransform(fixedGray, movingGray);
    alignedImage = dic_preprocess.analysisRun.applyRigidTransform( ...
        referenceImage, movingImage, tformRigid);
    method = ['toolbox-free coarse-to-fine rigid phase-correlation ' ...
        'registration with fine structural scoring'];
end

function gray = normalizeGray(imageData)
    if ndims(imageData) == 3
        rgb = labkit.image.ensureRgb(labkit.image.im2double(imageData));
        gray = labkit.image.rgb2gray(rgb);
    else
        gray = labkit.image.im2double(imageData);
    end
    values = gray(:);
    values = values(isfinite(values));
    if isempty(values)
        return;
    end
    values = sort(values);
    mn = percentileValue(values, .01);
    mx = percentileValue(values, .99);
    if ~(isfinite(mn) && isfinite(mx) && mx > mn)
        mn = values(1);
        mx = values(end);
    end
    if isfinite(mn) && isfinite(mx) && mx > mn
        gray = (gray - mn) ./ (mx - mn);
        gray = min(1, max(0, gray));
    end
end

function value = percentileValue(sortedValues, fraction)
    position = 1 + fraction * (numel(sortedValues) - 1);
    lower = floor(position);
    upper = ceil(position);
    weight = position - lower;
    value = (1 - weight) * sortedValues(lower) + ...
        weight * sortedValues(upper);
end

function [transform, quality] = estimateRigidTransform(fixedGray, movingGray)
    % A global-to-fine full-circle search supports camera reorientation while
    % keeping the expensive high-resolution scoring bounded. A 256-pixel
    % preview bounds translation work;
    % a finer 1024-pixel structural score avoids selecting angles from an
    % aliased DIC texture preview without changing the source-resolution
    % output transform.
    coarseAngleStepDegrees = 6;
    intermediateAngleStepDegrees = 1;
    fineAngleStepDegrees = .25;
    maximumTranslationFraction = .75;
    maximumPreviewDimension = 256;
    maximumScoreDimension = 1024;
    fixedSize = [size(fixedGray, 1), size(fixedGray, 2)];
    movingSize = [size(movingGray, 1), size(movingGray, 2)];
    sampleStep = max(1, ceil(max([fixedSize, movingSize]) / ...
        maximumPreviewDimension));
    fixedRows = 1:sampleStep:size(fixedGray, 1);
    fixedCols = 1:sampleStep:size(fixedGray, 2);
    scoreStep = max(1, ceil(max([fixedSize, movingSize]) / ...
        maximumScoreDimension));
    scoreRows = 1:scoreStep:size(fixedGray, 1);
    scoreCols = 1:scoreStep:size(fixedGray, 2);
    fixedTranslationImage = antiAliasForStep(fixedGray, sampleStep);
    movingTranslationImage = antiAliasForStep(movingGray, sampleStep);
    fixedScoreImage = antiAliasForStep(fixedGray, scoreStep);
    movingScoreImage = antiAliasForStep(movingGray, scoreStep);
    fixedPreview = fixedTranslationImage(fixedRows, fixedCols);
    fixedScorePreview = fixedScoreImage(scoreRows, scoreCols);
    fixedFeature = registrationFeature(fixedPreview);
    coarseAngles = -180:coarseAngleStepDegrees: ...
        180 - coarseAngleStepDegrees;
    [bestTransform, bestAngle, bestScore, bestDetails] = bestCandidate( ...
        coarseAngles, fixedGray, movingTranslationImage, movingScoreImage, ...
        fixedFeature, fixedScorePreview, fixedRows, fixedCols, sampleStep, ...
        scoreRows, scoreCols, maximumTranslationFraction);
    intermediateAngles = angleNeighborhood(bestAngle, ...
        coarseAngleStepDegrees, intermediateAngleStepDegrees);
    [intermediateTransform, intermediateAngle, intermediateScore, ...
            intermediateDetails] = bestCandidate( ...
        intermediateAngles, fixedGray, movingTranslationImage, ...
        movingScoreImage, fixedFeature, fixedScorePreview, fixedRows, ...
        fixedCols, sampleStep, scoreRows, scoreCols, ...
        maximumTranslationFraction);
    if intermediateScore >= bestScore
        bestTransform = intermediateTransform;
        bestAngle = intermediateAngle;
        bestScore = intermediateScore;
        bestDetails = intermediateDetails;
    end
    fineAngles = angleNeighborhood(bestAngle, ...
        intermediateAngleStepDegrees, fineAngleStepDegrees);
    [fineTransform, ~, fineScore, fineDetails] = bestCandidate( ...
        fineAngles, fixedGray, movingTranslationImage, movingScoreImage, ...
        fixedFeature, fixedScorePreview, fixedRows, fixedCols, sampleStep, ...
        scoreRows, scoreCols, maximumTranslationFraction);
    if fineScore >= bestScore
        bestTransform = fineTransform;
        bestScore = fineScore;
        bestDetails = fineDetails;
    end
    if ~isfinite(bestScore)
        error("dic_preprocess:AutoAlignmentFailed", ...
            "Automatic alignment could not find a finite structural match.");
    end
    transform = bestTransform;
    quality = struct( ...
        "angleDegrees", atan2d(transform(1, 2), transform(1, 1)), ...
        "translationX", transform(3, 1), ...
        "translationY", transform(3, 2), ...
        "score", bestScore, ...
        "overlapFraction", bestDetails.overlapFraction, ...
        "scoreMargin", bestDetails.scoreMargin, ...
        "translationPeakMargin", bestDetails.translationPeakMargin);
end

function angles = angleNeighborhood(centerAngle, radius, step)
    angles = centerAngle + (-radius:step:radius);
    angles = mod(angles + 180, 360) - 180;
    angles = unique(angles, "stable");
end

function [bestTransform, bestAngle, bestScore, bestDetails] = bestCandidate( ...
        angles, fixedGray, movingTranslationImage, movingScoreImage, ...
        fixedFeature, fixedScorePreview, fixedRows, fixedCols, sampleStep, ...
        scoreRows, scoreCols, maximumTranslationFraction)
    fixedCenter = ([size(fixedGray, 2), size(fixedGray, 1)] + 1) / 2;
    movingCenter = ([size(movingScoreImage, 2), ...
        size(movingScoreImage, 1)] + 1) / 2;
    bestScore = -inf;
    bestAngle = 0;
    bestTransform = eye(3);
    bestDetails = candidateDetails();
    candidateScores = -inf(size(angles));
    for angleIndex = 1:numel(angles)
        angle = angles(angleIndex);
        radians = angle * pi / 180;
        rotation = [cos(radians) sin(radians); ...
            -sin(radians) cos(radians)];
        centerTranslation = fixedCenter - movingCenter * rotation;
        centered = warpPreview( ...
            movingTranslationImage, rotation, centerTranslation, ...
            fixedRows, fixedCols);
        [rowShift, colShift, translationPeakMargin] = estimateTranslation( ...
            fixedFeature, registrationFeature(centered), ...
            maximumTranslationFraction);
        translation = centerTranslation + ...
            sampleStep * [colShift rowShift];
        warped = warpPreview( ...
            movingScoreImage, rotation, translation, scoreRows, scoreCols);
        [score, overlapFraction] = orientedAlignmentScore( ...
            fixedScorePreview, warped);
        candidateScores(angleIndex) = score;
        if score > bestScore
            bestScore = score;
            bestAngle = angle;
            bestTransform = [rotation [0; 0]; translation 1];
            bestDetails.overlapFraction = overlapFraction;
            bestDetails.translationPeakMargin = translationPeakMargin;
        end
    end
    finiteScores = sort(candidateScores(isfinite(candidateScores)), "descend");
    if numel(finiteScores) >= 2
        bestDetails.scoreMargin = finiteScores(1) - finiteScores(2);
    end
end

function value = candidateDetails()
    value = struct("overlapFraction", 0, "scoreMargin", 0, ...
        "translationPeakMargin", 0);
end

function preview = warpPreview(imageData, rotation, translation, rows, cols)
    [xGrid, yGrid] = meshgrid(cols, rows);
    source = ([xGrid(:), yGrid(:)] - translation) * rotation.';
    preview = interp2(double(imageData), ...
        reshape(source(:, 1), size(xGrid)), ...
        reshape(source(:, 2), size(yGrid)), 'linear', NaN);
end

function feature = registrationFeature(imageData)
    imageData(~isfinite(imageData)) = finiteMean(imageData);
    horizontal = [diff(imageData, 1, 2), zeros(size(imageData, 1), 1)];
    vertical = [diff(imageData, 1, 1); zeros(1, size(imageData, 2))];
    feature = hypot(horizontal, vertical);
end

function [rowShift, colShift, peakMargin] = estimateTranslation( ...
        fixedFeature, movingFeature, maximumTranslationFraction)
    fixedFeature = fixedFeature - finiteMean(fixedFeature);
    movingFeature = movingFeature - finiteMean(movingFeature);
    fixedFeature(~isfinite(fixedFeature)) = 0;
    movingFeature(~isfinite(movingFeature)) = 0;
    transformSize = 2 .* ...
        [size(fixedFeature, 1), size(fixedFeature, 2)];
    spectrum = fft2(fixedFeature, transformSize(1), transformSize(2)) .* ...
        conj(fft2(movingFeature, transformSize(1), transformSize(2)));
    magnitude = abs(spectrum);
    magnitude(magnitude == 0) = 1;
    % Retain part of the spectral amplitude so broad DIC texture contributes
    % to the peak instead of letting weak periodic frequencies dominate it.
    correlation = real(ifft2(spectrum ./ sqrt(magnitude)));
    rowValues = 0:size(correlation, 1)-1;
    colValues = 0:size(correlation, 2)-1;
    rowValues(rowValues > size(correlation, 1) / 2) = ...
        rowValues(rowValues > size(correlation, 1) / 2) - size(correlation, 1);
    colValues(colValues > size(correlation, 2) / 2) = ...
        colValues(colValues > size(correlation, 2) / 2) - size(correlation, 2);
    allowedRows = abs(rowValues) <= ...
        floor(maximumTranslationFraction * size(fixedFeature, 1));
    allowedCols = abs(colValues) <= ...
        floor(maximumTranslationFraction * size(fixedFeature, 2));
    correlation(~allowedRows, :) = -inf;
    correlation(:, ~allowedCols) = -inf;
    [~, idx] = max(correlation(:));
    [peakRow, peakCol] = ind2sub(size(correlation), idx);
    rowOffset = quadraticPeakOffset( ...
        correlation, peakRow, peakCol, 1);
    colOffset = quadraticPeakOffset( ...
        correlation, peakRow, peakCol, 2);
    rowShift = rowValues(peakRow) + rowOffset;
    colShift = colValues(peakCol) + colOffset;
    peakValue = correlation(peakRow, peakCol);
    sidelobes = correlation;
    rowWindow = max(1, peakRow - 2):min(size(correlation, 1), peakRow + 2);
    colWindow = max(1, peakCol - 2):min(size(correlation, 2), peakCol + 2);
    sidelobes(rowWindow, colWindow) = -inf;
    secondPeak = max(sidelobes(:));
    if isfinite(secondPeak)
        peakMargin = (peakValue - secondPeak) / max(abs(peakValue), eps);
    else
        peakMargin = 0;
    end
end

function offset = quadraticPeakOffset(values, row, col, dimension)
    offset = 0;
    if dimension == 1
        if row <= 1 || row >= size(values, 1)
            return;
        end
        previous = values(row - 1, col);
        center = values(row, col);
        following = values(row + 1, col);
    else
        if col <= 1 || col >= size(values, 2)
            return;
        end
        previous = values(row, col - 1);
        center = values(row, col);
        following = values(row, col + 1);
    end
    denominator = previous - 2 * center + following;
    if all(isfinite([previous center following])) && denominator < -eps
        offset = .5 * (previous - following) / denominator;
        offset = min(.5, max(-.5, offset));
    end
end

function filtered = antiAliasForStep(imageData, sampleStep)
    filtered = double(imageData);
    if sampleStep <= 1
        return;
    end
    kernelWidth = 2 * floor(sampleStep / 2) + 1;
    kernel = ones(1, kernelWidth) / kernelWidth;
    valid = isfinite(filtered);
    filtered(~valid) = 0;
    weights = conv2(conv2(double(valid), kernel, "same"), ...
        kernel.', "same");
    filtered = conv2(conv2(filtered, kernel, "same"), ...
        kernel.', "same");
    filtered = filtered ./ max(weights, eps);
    filtered(weights == 0) = NaN;
end

function value = finiteMean(imageData)
    values = imageData(isfinite(imageData));
    if isempty(values)
        value = 0;
    else
        value = mean(values);
    end
end

function [score, overlapFraction] = alignmentScore(fixedImage, movingImage)
    valid = isfinite(fixedImage) & isfinite(movingImage);
    overlapFraction = nnz(valid) / numel(valid);
    if overlapFraction < .2
        score = -inf;
        return;
    end
    fixedValues = fixedImage(valid);
    movingValues = movingImage(valid);
    fixedValues = fixedValues - mean(fixedValues);
    movingValues = movingValues - mean(movingValues);
    denominator = norm(fixedValues) * norm(movingValues);
    if denominator <= eps
        score = -inf;
        return;
    end
    globalScore = (fixedValues.' * movingValues) / denominator;
    tileScores = localCorrelationScores(fixedImage, movingImage, valid);
    if isempty(tileScores)
        robustScore = globalScore;
    else
        robustScore = median(tileScores);
    end
    score = .6 * globalScore + .4 * robustScore - ...
        .1 * (1 - overlapFraction);
end

function scores = localCorrelationScores(fixedImage, movingImage, valid)
    tileCount = 4;
    rowEdges = round(linspace(1, size(fixedImage, 1) + 1, tileCount + 1));
    colEdges = round(linspace(1, size(fixedImage, 2) + 1, tileCount + 1));
    scores = zeros(tileCount^2, 1);
    scoreCount = 0;
    for rowIndex = 1:tileCount
        rows = rowEdges(rowIndex):rowEdges(rowIndex + 1) - 1;
        for colIndex = 1:tileCount
            cols = colEdges(colIndex):colEdges(colIndex + 1) - 1;
            tileValid = valid(rows, cols);
            if nnz(tileValid) < max(4, ceil(.5 * numel(tileValid)))
                continue;
            end
            fixedTile = fixedImage(rows, cols);
            movingTile = movingImage(rows, cols);
            fixedValues = fixedTile(tileValid);
            movingValues = movingTile(tileValid);
            fixedValues = fixedValues - mean(fixedValues);
            movingValues = movingValues - mean(movingValues);
            denominator = norm(fixedValues) * norm(movingValues);
            if denominator > eps
                scoreCount = scoreCount + 1;
                scores(scoreCount, 1) = ...
                    (fixedValues.' * movingValues) / denominator;
            end
        end
    end
    scores = scores(1:scoreCount);
end

function [score, overlapFraction] = orientedAlignmentScore( ...
        fixedImage, movingImage)
    fixedHorizontal = [diff(fixedImage, 1, 2), ...
        zeros(size(fixedImage, 1), 1)];
    fixedVertical = [diff(fixedImage, 1, 1); ...
        zeros(1, size(fixedImage, 2))];
    movingHorizontal = [diff(movingImage, 1, 2), ...
        zeros(size(movingImage, 1), 1)];
    movingVertical = [diff(movingImage, 1, 1); ...
        zeros(1, size(movingImage, 2))];
    [horizontalScore, horizontalOverlap] = alignmentScore( ...
        fixedHorizontal, movingHorizontal);
    [verticalScore, verticalOverlap] = alignmentScore( ...
        fixedVertical, movingVertical);
    [magnitudeScore, magnitudeOverlap] = alignmentScore( ...
        hypot(fixedHorizontal, fixedVertical), ...
        hypot(movingHorizontal, movingVertical));
    componentScores = [horizontalScore, verticalScore, magnitudeScore];
    componentScores = componentScores(isfinite(componentScores));
    if isempty(componentScores)
        score = -inf;
    else
        score = mean(componentScores);
    end
    overlapFraction = min( ...
        [horizontalOverlap, verticalOverlap, magnitudeOverlap]);
end

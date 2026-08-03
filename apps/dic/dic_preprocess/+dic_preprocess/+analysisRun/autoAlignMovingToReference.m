function [alignedImage, tformRigid, method] = autoAlignMovingToReference(referenceImage, movingImage)
%AUTOALIGNMOVINGTOREFERENCE Estimate and apply a rigid transform.
%
% Usage:
%   [alignedImage, transform, method] = ...
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
%
% Description:
%   Each image is converted to normalized grayscale independently. The search
%   covers -30 through +30 degrees at three-degree spacing and refines the best
%   neighborhood at half-degree spacing. Each candidate evaluates a toolbox-
%   free, zero-padded phase-correlation translation on a response-limited
%   preview. The accepted rotation and translation are then applied to the
%   original moving image. Scale and deformation are not estimated; repeated
%   texture and large nonoverlap can still produce a poor fit.
%
% Failure Behavior:
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

    tformRigid = estimateRigidTransform(fixedGray, movingGray);
    alignedImage = dic_preprocess.analysisRun.applyRigidTransform( ...
        referenceImage, movingImage, tformRigid);
    method = 'toolbox-free coarse-to-fine rigid phase-correlation registration';
end

function gray = normalizeGray(imageData)
    if ndims(imageData) == 3
        rgb = labkit.image.ensureRgb(labkit.image.im2double(imageData));
        gray = labkit.image.rgb2gray(rgb);
    else
        gray = labkit.image.im2double(imageData);
    end
    values = gray(:);
    values = values(~isnan(values));
    if isempty(values)
        return;
    end
    mn = min(values);
    mx = max(values);
    if isfinite(mn) && isfinite(mx) && mx > mn
        gray = (gray - mn) ./ (mx - mn);
    end
end

function transform = estimateRigidTransform(fixedGray, movingGray)
    % DIC camera repositioning is expected to be modest. Searching this
    % bounded range and two resolution stages keep interactive registration
    % responsive while restoring the rotation capability lost by the
    % translation-only fallback. A 256-pixel preview bounds each candidate's
    % work without changing the source-resolution output transform.
    maximumExpectedRotationDegrees = 30;
    coarseAngleStepDegrees = 3;
    fineAngleStepDegrees = .5;
    maximumPreviewDimension = 256;
    fixedSize = [size(fixedGray, 1), size(fixedGray, 2)];
    movingSize = [size(movingGray, 1), size(movingGray, 2)];
    sampleStep = max(1, ceil(max([fixedSize, movingSize]) / ...
        maximumPreviewDimension));
    fixedRows = 1:sampleStep:size(fixedGray, 1);
    fixedCols = 1:sampleStep:size(fixedGray, 2);
    fixedPreview = fixedGray(fixedRows, fixedCols);
    fixedFeature = registrationFeature(fixedPreview);
    coarseAngles = -maximumExpectedRotationDegrees: ...
        coarseAngleStepDegrees:maximumExpectedRotationDegrees;
    [bestTransform, bestAngle, bestScore] = bestCandidate( ...
        coarseAngles, fixedGray, movingGray, fixedFeature, ...
        fixedRows, fixedCols, sampleStep);
    fineAngles = bestAngle + ...
        (-coarseAngleStepDegrees:fineAngleStepDegrees:coarseAngleStepDegrees);
    fineAngles = fineAngles(abs(fineAngles) <= maximumExpectedRotationDegrees);
    [fineTransform, ~, fineScore] = bestCandidate( ...
        fineAngles, fixedGray, movingGray, fixedFeature, ...
        fixedRows, fixedCols, sampleStep);
    if fineScore > bestScore
        bestTransform = fineTransform;
    end
    transform = bestTransform;
end

function [bestTransform, bestAngle, bestScore] = bestCandidate( ...
        angles, fixedGray, movingGray, fixedFeature, ...
        fixedRows, fixedCols, sampleStep)
    fixedCenter = ([size(fixedGray, 2), size(fixedGray, 1)] + 1) / 2;
    movingCenter = ([size(movingGray, 2), size(movingGray, 1)] + 1) / 2;
    bestScore = -inf;
    bestAngle = 0;
    bestTransform = eye(3);
    for angle = angles
        radians = angle * pi / 180;
        rotation = [cos(radians) sin(radians); ...
            -sin(radians) cos(radians)];
        centerTranslation = fixedCenter - movingCenter * rotation;
        centered = warpPreview( ...
            movingGray, rotation, centerTranslation, fixedRows, fixedCols);
        [rowShift, colShift] = estimateTranslation( ...
            fixedFeature, registrationFeature(centered));
        translation = centerTranslation + ...
            sampleStep * [colShift rowShift];
        warped = warpPreview( ...
            movingGray, rotation, translation, fixedRows, fixedCols);
        score = alignmentScore(fixedGray(fixedRows, fixedCols), warped);
        if score > bestScore
            bestScore = score;
            bestAngle = angle;
            bestTransform = [rotation [0; 0]; translation 1];
        end
    end
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

function [rowShift, colShift] = estimateTranslation(fixedFeature, movingFeature)
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
    allowedRows = abs(rowValues) <= floor(.45 * size(fixedFeature, 1));
    allowedCols = abs(colValues) <= floor(.45 * size(fixedFeature, 2));
    correlation(~allowedRows, :) = -inf;
    correlation(:, ~allowedCols) = -inf;
    [~, idx] = max(correlation(:));
    [peakRow, peakCol] = ind2sub(size(correlation), idx);
    rowShift = rowValues(peakRow);
    colShift = colValues(peakCol);
end

function value = finiteMean(imageData)
    values = imageData(isfinite(imageData));
    if isempty(values)
        value = 0;
    else
        value = mean(values);
    end
end

function score = alignmentScore(fixedImage, movingImage)
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
    score = (fixedValues.' * movingValues) / denominator;
end

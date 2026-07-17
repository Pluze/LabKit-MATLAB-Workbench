function [alignedImage, tformRigid, method] = autoAlignMovingToReference(referenceImage, movingImage)
%AUTOALIGNMOVINGTOREFERENCE Estimate and apply an integer translation.
%
% Usage:
%   [alignedImage, transform, method] = ...
%       dic_preprocess.analysisRun.autoAlignMovingToReference( ...
%       referenceImage, movingImage)
%
% Inputs:
%   referenceImage - Numeric grayscale or RGB reference image. Its first two
%       dimensions define the output canvas and correlation size.
%   movingImage - Numeric grayscale or RGB image to translate.
%
% Outputs:
%   alignedImage - Original movingImage translated onto the reference canvas,
%       with linear interpolation and zero fill.
%   tformRigid - Three-by-three row-vector homogeneous translation transform,
%       shown as transform in the usage syntax.
%   method - Character vector identifying the fixed phase-correlation method.
%
% Description:
%   Each image is converted to normalized grayscale independently. For shift
%   estimation only, moving grayscale data is resized to the reference size by
%   nearest-neighbor sampling. Phase correlation returns a whole-pixel circular
%   shift. Rotation, scale, deformation, repeated texture, and large nonoverlap
%   can produce a poor fit.
%
% Failure Behavior:
%   The function does not assign a confidence score or reject an ambiguous
%   phase-correlation peak; low-texture or repeated-pattern inputs can return a
%   numerically valid but poor translation. Empty arrays, unsupported image
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

    [rowShift, colShift] = estimateTranslation(fixedGray, movingGray);
    tformRigid = [1 0 0; 0 1 0; colShift rowShift 1];
    alignedImage = dic_preprocess.analysisRun.applyRigidTransform( ...
        referenceImage, movingImage, tformRigid);
    method = 'toolbox-free phase-correlation translation registration';
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

function [rowShift, colShift] = estimateTranslation(fixedGray, movingGray)
    targetSize = size(fixedGray);
    movingGray = resizeToMatch(movingGray, targetSize);
    fixedGray = fixedGray - finiteMean(fixedGray);
    movingGray = movingGray - finiteMean(movingGray);
    fixedGray(~isfinite(fixedGray)) = 0;
    movingGray(~isfinite(movingGray)) = 0;

    spectrum = fft2(fixedGray) .* conj(fft2(movingGray));
    magnitude = abs(spectrum);
    magnitude(magnitude == 0) = 1;
    correlation = real(ifft2(spectrum ./ magnitude));
    [~, idx] = max(correlation(:));
    [peakRow, peakCol] = ind2sub(size(correlation), idx);
    rowShift = peakRow - 1;
    colShift = peakCol - 1;
    if rowShift > floor(size(correlation, 1) / 2)
        rowShift = rowShift - size(correlation, 1);
    end
    if colShift > floor(size(correlation, 2) / 2)
        colShift = colShift - size(correlation, 2);
    end
end

function value = finiteMean(imageData)
    values = imageData(isfinite(imageData));
    if isempty(values)
        value = 0;
    else
        value = mean(values);
    end
end

function imageOut = resizeToMatch(imageIn, targetSize)
    if isequal(size(imageIn, 1), targetSize(1)) && ...
            isequal(size(imageIn, 2), targetSize(2))
        imageOut = imageIn;
        return;
    end
    rowIdx = nearestIndices(size(imageIn, 1), targetSize(1));
    colIdx = nearestIndices(size(imageIn, 2), targetSize(2));
    imageOut = imageIn(rowIdx, colIdx, :);
end

function idx = nearestIndices(inputLength, outputLength)
    if outputLength <= 1
        idx = 1;
        return;
    end
    positions = linspace(1, inputLength, outputLength);
    idx = min(max(round(positions), 1), inputLength);
end

function overlay = makeFalseColorOverlay(referenceImage, alignedImage)
%MAKEFALSECOLOROVERLAY Build a red/green registration preview.
%
% Usage:
%   overlay = dic_preprocess.analysisRun.makeFalseColorOverlay( ...
%       referenceImage, alignedImage)
%
% Inputs:
%   referenceImage - Numeric grayscale or RGB reference image.
%   alignedImage - Numeric grayscale or RGB moving image. A different height or
%       width is resized to the reference dimensions by nearest neighbor.
%
% Outputs:
%   overlay - Double RGB image the size of referenceImage. Red contains the
%       independently normalized moving image, green contains the independently
%       normalized reference, and blue is zero.
%
% Description:
%   Coincident structure appears yellow, moving-only structure red, and
%   reference-only structure green. Independent min/max grayscale normalization
%   emphasizes geometry rather than preserving absolute intensity calibration.
%
% Example:
%   reference = eye(5);
%   moving = circshift(reference, [0 1]);
%   overlay = dic_preprocess.analysisRun.makeFalseColorOverlay( ...
%       reference, moving);
%   assert(isequal(size(overlay), [5 5 3]))
%   assert(all(overlay(:,:,3) == 0, "all"))
%
% See also dic_preprocess.analysisRun.autoAlignMovingToReference

    refGray = normalizeGray(referenceImage);
    movGray = normalizeGray(alignedImage);
    if ~isequal(size(refGray), size(movGray))
        movGray = resizeNearest(movGray, size(refGray));
    end
    overlay = zeros([size(refGray), 3]);
    overlay(:, :, 1) = movGray;
    overlay(:, :, 2) = refGray;
end

function imageOut = resizeNearest(imageIn, targetSize)
    targetRows = max(1, round(targetSize(1)));
    targetCols = max(1, round(targetSize(2)));
    rowIdx = nearestIndices(size(imageIn, 1), targetRows);
    colIdx = nearestIndices(size(imageIn, 2), targetCols);
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

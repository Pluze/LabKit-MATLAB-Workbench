% Expected caller: DIC preprocess runner. Inputs are the current reference and
% moving images. Outputs are a toolbox-free phase-correlation aligned image, a
% 3x3 translation transform matrix, and a user-facing method label. Side
% effects: none.

function [alignedImage, tformRigid, method] = autoAlignMovingToReference(referenceImage, movingImage)
%AUTOALIGNMOVINGTOREFERENCE Automatically align moving image to reference image.

    origClass = class(movingImage);
    fixedGray = normalizeGray(referenceImage);
    movingGray = normalizeGray(movingImage);

    [rowShift, colShift] = estimateTranslation(fixedGray, movingGray);
    alignedImage = translateImage(movingImage, rowShift, colShift);
    alignedImage = cast(alignedImage, origClass);
    tformRigid = [1 0 0; 0 1 0; colShift rowShift 1];
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

function imageOut = translateImage(imageIn, rowShift, colShift)
    targetRows = size(imageIn, 1);
    targetCols = size(imageIn, 2);
    imageOut = zeros(size(imageIn), 'like', imageIn);
    srcRows = max(1, 1 - rowShift):min(targetRows, targetRows - rowShift);
    srcCols = max(1, 1 - colShift):min(targetCols, targetCols - colShift);
    dstRows = srcRows + rowShift;
    dstCols = srcCols + colShift;
    if isempty(srcRows) || isempty(srcCols)
        return;
    end
    imageOut(dstRows, dstCols, :) = imageIn(srcRows, srcCols, :);
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

% App-owned image measurement package helper. Expected caller: owning app callbacks
% and package tests. Inputs, outputs, and side effects are
% documented with the helper function below.
function [alignedImages, lines] = alignImages(images)
%ALIGNIMAGES Align focus-stack images for labkit_FocusStack_app.
%
% Expected caller:
%   labkit_FocusStack_app run callback and package tests.
%
% Inputs/outputs:
%   Cell array or numeric stack of images. Returns images aligned to the
%   middle stack image plus app-owned log/detail lines.
%
% Side effects:
%   None. This helper performs GUI-free registration only.

    images = focus_stack.analysisRun.normalizeImageCell(images);
    alignedImages = images;
    lines = {};
    if numel(images) < 2
        return;
    end
    lines = cell(1, numel(images));

    referenceIndex = round((numel(images) + 1) / 2);
    reference = images{referenceIndex};
    lineCount = 1;
    lines{lineCount} = sprintf('Registration reference image: %d.', referenceIndex);
    for k = 1:numel(images)
        if k == referenceIndex
            continue;
        end
        try
            [alignedImages{k}, method] = alignImageToReference(reference, images{k});
            lineCount = lineCount + 1;
            lines{lineCount} = sprintf('Registered image %d using %s.', k, method);
        catch ME
            alignedImages{k} = focus_stack.analysisRun.resizeImageToReference(images{k}, size(reference));
            lineCount = lineCount + 1;
            lines{lineCount} = sprintf('Image %d registration skipped: %s', k, ME.message);
        end
    end
    lines = lines(1:lineCount);
end

function [alignedImage, method] = alignImageToReference(referenceImage, movingImage)
    origClass = class(movingImage);
    movingImage = focus_stack.analysisRun.resizeImageToReference(movingImage, size(referenceImage));
    fixedGray = alignmentGray(referenceImage);
    movingGray = alignmentGray(movingImage);

    try
        [rowShift, colShift] = estimateTranslationByPhaseCorrelation( ...
            fixedGray, movingGray);
        alignedImage = translateImageByIntegerShift( ...
            movingImage, rowShift, colShift, backgroundFillValues(movingImage));
        alignedImage = cast(alignedImage, origClass);
        method = sprintf('FFT translation (row %+d, col %+d)', ...
            rowShift, colShift);
    catch registrationErr
        error('labkit_FocusStack_app:RegistrationFailed', ...
            'Base-MATLAB phase-correlation registration failed: %s', ...
            registrationErr.message);
    end
end

function gray = alignmentGray(imageData)
    gray = focus_stack.analysisRun.normalizeGray(imageData);
    lowpass = labkit.image.meanFilter2(gray, 31);
    gray = gray - lowpass;
    mx = max(abs(gray(:)));
    if mx > 0
        gray = gray ./ mx;
    end
end

function fillValues = backgroundFillValues(imageData)
    if ismatrix(imageData)
        border = [imageData(1, :), imageData(end, :), imageData(:, 1).', imageData(:, end).'];
        fillValues = median(double(border(:)));
        return;
    end

    fillValues = zeros(1, size(imageData, 3));
    for c = 1:size(imageData, 3)
        channel = imageData(:, :, c);
        border = [channel(1, :), channel(end, :), channel(:, 1).', channel(:, end).'];
        fillValues(c) = median(double(border(:)));
    end
end

function [rowShift, colShift] = estimateTranslationByPhaseCorrelation(fixedGray, movingGray)
    fixedGray = double(fixedGray);
    movingGray = double(movingGray);
    fixedGray = fixedGray - mean(fixedGray(:), 'omitnan');
    movingGray = movingGray - mean(movingGray(:), 'omitnan');
    fixedGray(~isfinite(fixedGray)) = 0;
    movingGray(~isfinite(movingGray)) = 0;

    crossPower = fft2(fixedGray) .* conj(fft2(movingGray));
    magnitude = abs(crossPower);
    normalized = crossPower ./ max(magnitude, eps);
    corrMap = real(ifft2(normalized));
    [~, peakIdx] = max(corrMap(:));
    [peakRow, peakCol] = ind2sub(size(corrMap), peakIdx);

    [rows, cols] = size(corrMap);
    rowShift = peakRow - 1;
    colShift = peakCol - 1;
    if rowShift > rows / 2
        rowShift = rowShift - rows;
    end
    if colShift > cols / 2
        colShift = colShift - cols;
    end
end

function imageOut = translateImageByIntegerShift(imageIn, rowShift, colShift, fillValues)
    rowShift = round(rowShift);
    colShift = round(colShift);
    imageOut = filledImageLike(imageIn, fillValues);

    rows = size(imageIn, 1);
    cols = size(imageIn, 2);
    dstRows = max(1, 1 + rowShift):min(rows, rows + rowShift);
    dstCols = max(1, 1 + colShift):min(cols, cols + colShift);
    srcRows = max(1, 1 - rowShift):min(rows, rows - rowShift);
    srcCols = max(1, 1 - colShift):min(cols, cols - colShift);
    if isempty(dstRows) || isempty(dstCols) || isempty(srcRows) || isempty(srcCols)
        return;
    end

    if ismatrix(imageIn)
        imageOut(dstRows, dstCols) = imageIn(srcRows, srcCols);
    else
        imageOut(dstRows, dstCols, :) = imageIn(srcRows, srcCols, :);
    end
end

function imageOut = filledImageLike(imageIn, fillValues)
    imageOut = zeros(size(imageIn), class(imageIn));
    if ismatrix(imageIn)
        imageOut(:) = cast(fillValues(1), class(imageIn));
        return;
    end

    for c = 1:size(imageIn, 3)
        imageOut(:, :, c) = cast(fillValues(min(c, numel(fillValues))), class(imageIn));
    end
end

function [alignedImages, lines] = alignFocusStackImages(images)
%ALIGNFOCUSSTACKIMAGES Align focus-stack images for labkit_FocusStack_app.
%
% Expected caller:
%   labkit_FocusStack_app run callback and __labkit_test__ handler.
%
% Inputs/outputs:
%   Cell array or numeric stack of images. Returns images aligned to the
%   middle stack image plus app-owned log/detail lines.
%
% Side effects:
%   None. This helper performs GUI-free registration only.

    images = normalizeImageCell(images);
    alignedImages = images;
    lines = {};
    if numel(images) < 2
        return;
    end

    referenceIndex = round((numel(images) + 1) / 2);
    reference = images{referenceIndex};
    lines{end+1} = sprintf('Registration reference image: %d.', referenceIndex); %#ok<AGROW>
    for k = 1:numel(images)
        if k == referenceIndex
            continue;
        end
        try
            [alignedImages{k}, method] = alignImageToReference(reference, images{k});
            lines{end+1} = sprintf('Registered image %d using %s.', k, method); %#ok<AGROW>
        catch ME
            alignedImages{k} = resizeImageToReference(images{k}, size(reference));
            lines{end+1} = sprintf('Image %d registration skipped: %s', k, ME.message); %#ok<AGROW>
        end
    end
end

function [alignedImage, method] = alignImageToReference(referenceImage, movingImage)
    origClass = class(movingImage);
    movingImage = resizeImageToReference(movingImage, size(referenceImage));
    fixedGray = alignmentGray(referenceImage);
    movingGray = alignmentGray(movingImage);

    try
        [alignedImage, method] = alignImageWithImregcorr( ...
            movingImage, movingGray, fixedGray);
        alignedImage = cast(alignedImage, origClass);
        return;
    catch registrationErr
        try
            [rowShift, colShift] = estimateTranslationByPhaseCorrelation( ...
                fixedGray, movingGray);
            alignedImage = translateImageByIntegerShift( ...
                movingImage, rowShift, colShift, backgroundFillValues(movingImage));
            alignedImage = cast(alignedImage, origClass);
            method = sprintf('FFT translation fallback (row %+d, col %+d)', ...
                rowShift, colShift);
            return;
        catch fallbackErr
            error('labkit_FocusStack_app:RegistrationFailed', ...
                'Image registration failed: %s Fallback failed: %s', ...
                registrationErr.message, fallbackErr.message);
        end
    end
end

function [alignedImage, method] = alignImageWithImregcorr(movingImage, movingGray, fixedGray)
    try
        tform = imregcorr(movingGray, fixedGray, 'similarity');
        method = 'phase-correlation similarity registration';
    catch similarityErr
        try
            tform = imregcorr(movingGray, fixedGray, 'rigid');
            method = 'phase-correlation rigid registration';
        catch rigidErr
            try
                tform = imregcorr(movingGray, fixedGray, 'translation');
                method = 'phase-correlation translation registration';
            catch translationErr
                error('labkit_FocusStack_app:RegistrationFailed', ...
                    'Similarity failed: %s Rigid failed: %s Translation failed: %s', ...
                    similarityErr.message, rigidErr.message, translationErr.message);
            end
        end
    end

    fixedRef = imref2d(size(fixedGray));
    alignedImage = imwarp(movingImage, tform, ...
        'OutputView', fixedRef, 'FillValues', backgroundFillValues(movingImage));
end

function gray = alignmentGray(imageData)
    gray = normalizeGray(imageData);
    lowpass = boxMean2(gray, 31);
    gray = gray - lowpass;
    mx = max(abs(gray(:)));
    if mx > 0
        gray = gray ./ mx;
    end
end

function fillValues = backgroundFillValues(imageData)
    if ndims(imageData) == 2
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

    if ndims(imageIn) == 2
        imageOut(dstRows, dstCols) = imageIn(srcRows, srcCols);
    else
        imageOut(dstRows, dstCols, :) = imageIn(srcRows, srcCols, :);
    end
end

function imageOut = filledImageLike(imageIn, fillValues)
    imageOut = zeros(size(imageIn), class(imageIn));
    if ndims(imageIn) == 2
        imageOut(:) = cast(fillValues(1), class(imageIn));
        return;
    end

    for c = 1:size(imageIn, 3)
        imageOut(:, :, c) = cast(fillValues(min(c, numel(fillValues))), class(imageIn));
    end
end

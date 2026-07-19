% Expected caller: labkit_ImageEnhance_app preview rendering. Inputs are original
% and enhanced images. Output is a display-only side-by-side RGB preview image
% with a narrow divider; source images are not modified.
function imageOut = beforeAfterImage(original, enhanced)

    original = normalizePreviewImage(original);
    enhanced = normalizePreviewImage(enhanced);
    if size(original, 1) ~= size(enhanced, 1) || size(original, 2) ~= size(enhanced, 2)
        enhanced = resizePreviewImage(enhanced, [size(original, 1), size(original, 2)]);
    end

    divider = ones(size(original, 1), 6, 3);
    imageOut = cat(2, original, divider, enhanced);
end

function imageOut = normalizePreviewImage(imageIn)
    imageOut = min(max(labkit.image.im2double(imageIn), 0), 1);
    if ndims(imageOut) == 2
        imageOut = repmat(imageOut, 1, 1, 3);
    end
end

function imageOut = resizePreviewImage(imageIn, targetSize)
    targetRows = targetSize(1);
    targetCols = targetSize(2);
    queryRows = linspace(1, size(imageIn, 1), targetRows);
    queryCols = linspace(1, size(imageIn, 2), targetCols);
    [colGrid, rowGrid] = meshgrid(queryCols, queryRows);
    imageOut = zeros(targetRows, targetCols, size(imageIn, 3));
    for channel = 1:size(imageIn, 3)
        imageOut(:, :, channel) = interp2( ...
            1:size(imageIn, 2), 1:size(imageIn, 1), ...
            imageIn(:, :, channel), colGrid, rowGrid, 'linear', NaN);
    end
    imageOut(~isfinite(imageOut)) = 0;
end

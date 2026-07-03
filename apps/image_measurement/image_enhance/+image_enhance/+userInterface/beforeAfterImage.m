% Expected caller: labkit_ImageEnhance_app preview rendering. Inputs are original
% and enhanced images. Output is a display-only side-by-side RGB preview image
% with a narrow divider; source images are not modified.
function imageOut = beforeAfterImage(original, enhanced)

    original = normalizePreviewImage(original);
    enhanced = normalizePreviewImage(enhanced);
    if size(original, 1) ~= size(enhanced, 1) || size(original, 2) ~= size(enhanced, 2)
        enhanced = imresize(enhanced, [size(original, 1), size(original, 2)]);
    end

    divider = ones(size(original, 1), 6, 3);
    imageOut = cat(2, original, divider, enhanced);
end

function imageOut = normalizePreviewImage(imageIn)
    imageOut = min(max(im2double(imageIn), 0), 1);
    if ndims(imageOut) == 2
        imageOut = repmat(imageOut, 1, 1, 3);
    end
end

% Expected caller: labkit_ImageMatch_app preview rendering. Inputs are original
% and matched images. Output is a display-only side-by-side RGB preview image
% with a narrow divider; source images are not modified.
function imageOut = beforeAfterImage(original, matchedImage)

    original = normalizePreviewImage(original);
    matchedImage = normalizePreviewImage(matchedImage);
    if size(original, 1) ~= size(matchedImage, 1) || size(original, 2) ~= size(matchedImage, 2)
        matchedImage = imresize(matchedImage, [size(original, 1), size(original, 2)]);
    end

    divider = ones(size(original, 1), 6, 3);
    imageOut = cat(2, original, divider, matchedImage);
end

function imageOut = normalizePreviewImage(imageIn)
    imageOut = min(max(im2double(imageIn), 0), 1);
    if ndims(imageOut) == 2
        imageOut = repmat(imageOut, 1, 1, 3);
    end
end

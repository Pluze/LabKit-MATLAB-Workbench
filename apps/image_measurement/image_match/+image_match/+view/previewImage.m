% Expected caller: labkit_ImageMatch_app preview rendering. Input is an image
% array and optional maximum display height. Output is RGB double preview data
% downsampled for responsive UI display; export data remains full resolution.
function imageOut = previewImage(imageIn, maxHeight)
%PREVIEWIMAGE Normalize and downsample display-only preview image data.

    if nargin < 2 || isempty(maxHeight)
        maxHeight = 1500;
    end
    imageOut = min(max(im2double(imageIn), 0), 1);
    if ndims(imageOut) == 2
        imageOut = repmat(imageOut, 1, 1, 3);
    elseif size(imageOut, 3) > 3
        imageOut = imageOut(:, :, 1:3);
    end

    if size(imageOut, 1) <= maxHeight
        return;
    end
    scale = double(maxHeight) ./ double(size(imageOut, 1));
    targetSize = max(1, round([size(imageOut, 1), size(imageOut, 2)] .* scale));
    imageOut = imresize(imageOut, targetSize);
end

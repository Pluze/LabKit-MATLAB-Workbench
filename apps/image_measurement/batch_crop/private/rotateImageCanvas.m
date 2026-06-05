% App-owned image rotation helper. Expected caller: batchCropImage. Inputs are
% image data, angle in degrees, and fill value. Output is a loose rotated
% canvas with background filled consistently for grayscale/RGB images.
function [canvas, mask] = rotateImageCanvas(imageData, angleDeg, fillValue)
%ROTATEIMAGECANVAS Rotate an image without resizing its pixel scale.
% Expected caller: batchCropImage. The output canvas may be larger than the
% input when angleDeg is nonzero. A rotated mask is used to replace default
% rotation background with the requested fill value.

    if nargin < 3
        fillValue = 0;
    end

    if abs(mod(double(angleDeg), 360)) < 1e-12
        canvas = imageData;
        mask = true(size(imageData, 1), size(imageData, 2));
        return;
    end

    canvas = imrotate(imageData, angleDeg, 'bilinear', 'loose');
    mask = imrotate(true(size(imageData, 1), size(imageData, 2)), ...
        angleDeg, 'nearest', 'loose');
    mask = logical(mask);
    canvas = applyFillOutsideMask(canvas, mask, fillValue);
end

function canvas = applyFillOutsideMask(canvas, mask, fillValue)
    fillValue = castFillValue(fillValue, canvas);
    outside = ~mask;
    if ndims(canvas) == 2
        canvas(outside) = fillValue;
        return;
    end

    for channel = 1:size(canvas, 3)
        plane = canvas(:, :, channel);
        plane(outside) = fillValue;
        canvas(:, :, channel) = plane;
    end
end

function value = castFillValue(fillValue, imageData)
    if islogical(imageData)
        value = logical(fillValue);
    else
        value = cast(fillValue, class(imageData));
    end
end

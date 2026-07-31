% App-owned fixed-size crop helper. Expected caller: cropImage. Inputs
% are a rotated canvas, center coordinates in canvas pixels, crop size, and
% scalar fill value. Output preserves class and pads out-of-bounds regions.
function cropped = cropCanvasFixedSize(canvas, centerXY, cropSize, fillValue)
%CROPCANVASFIXEDSIZE Crop a fixed pixel rectangle from a canvas.
% Expected caller: cropImage. Inputs are a 2-D or 3-D image canvas,
% centerXY as [x y], cropSize as [width height], and a scalar fill value.
% Output is exactly height-by-width pixels and has no file side effects.

    width = max(1, round(double(cropSize(1))));
    height = max(1, round(double(cropSize(2))));
    centerXY = double(centerXY(:)).';
    fillValue = castFillValue(fillValue, canvas);

    rowStart = round(centerXY(2) - (height - 1) / 2);
    colStart = round(centerXY(1) - (width - 1) / 2);
    rowEnd = rowStart + height - 1;
    colEnd = colStart + width - 1;

    canvasHeight = size(canvas, 1);
    canvasWidth = size(canvas, 2);
    srcRowStart = max(1, rowStart);
    srcRowEnd = min(canvasHeight, rowEnd);
    srcColStart = max(1, colStart);
    srcColEnd = min(canvasWidth, colEnd);

    if ismatrix(canvas)
        cropped = repmat(fillValue, height, width);
    else
        cropped = repmat(fillValue, height, width, size(canvas, 3));
    end

    if srcRowEnd < srcRowStart || srcColEnd < srcColStart
        return;
    end

    dstRowStart = srcRowStart - rowStart + 1;
    dstColStart = srcColStart - colStart + 1;
    dstRowEnd = dstRowStart + (srcRowEnd - srcRowStart);
    dstColEnd = dstColStart + (srcColEnd - srcColStart);
    cropped(dstRowStart:dstRowEnd, dstColStart:dstColEnd, :) = ...
        canvas(srcRowStart:srcRowEnd, srcColStart:srcColEnd, :);
end

function value = castFillValue(fillValue, imageData)
    if islogical(imageData)
        value = logical(fillValue);
    else
        value = cast(fillValue, class(imageData));
    end
end

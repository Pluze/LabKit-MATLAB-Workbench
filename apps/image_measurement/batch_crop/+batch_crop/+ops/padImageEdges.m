% App-owned edge-padding helper. Expected caller: batch-crop preview/export
% transforms and package tests. Inputs are an image array and a padding
% percent. Output preserves class and pads by reflecting the source image with
% a narrow edge-only blend to reduce visible seams.
function [padded, padding] = padImageEdges(imageData, paddingPercent)
%PADIMAGEEDGES Expand an image using reflected edge-continuous padding.

    validateImageData(imageData);
    percent = normalizePaddingPercent(paddingPercent);

    height = size(imageData, 1);
    width = size(imageData, 2);
    padX = round(width * percent / 100);
    padY = round(height * percent / 100);
    padding = struct( ...
        'percent', percent, ...
        'left', padX, ...
        'right', padX, ...
        'top', padY, ...
        'bottom', padY);

    if padX == 0 && padY == 0
        padded = imageData;
        return;
    end

    rowCoords = (1 - padY):(height + padY);
    colCoords = (1 - padX):(width + padX);
    rowIdx = reflectedSubscripts(rowCoords, height);
    colIdx = reflectedSubscripts(colCoords, width);

    if ndims(imageData) == 2
        padded = imageData(rowIdx, colIdx);
    else
        padded = imageData(rowIdx, colIdx, :);
    end

    if islogical(imageData)
        return;
    end

    padded = blendPaddingTowardEdge(padded, imageData, rowCoords, colCoords, padding);
end

function validateImageData(imageData)
    if isempty(imageData) || ~(isnumeric(imageData) || islogical(imageData)) || ndims(imageData) > 3
        error('labkit_BatchImageCrop_app:InvalidImage', ...
            'Image data must be a nonempty numeric or logical 2-D or 3-D image array.');
    end
end

function percent = normalizePaddingPercent(paddingPercent)
    if nargin < 1 || isempty(paddingPercent)
        percent = 0;
        return;
    end

    percent = double(paddingPercent(1));
    if ~isfinite(percent)
        error('labkit_BatchImageCrop_app:InvalidPaddingPercent', ...
            'Padding percent must be finite.');
    end
    percent = min(max(percent, 0), 50);
end

function idx = reflectedSubscripts(coords, count)
    if count <= 1
        idx = ones(size(coords));
        return;
    end

    period = 2 * count - 2;
    folded = mod(coords - 1, period) + 1;
    idx = folded;
    over = folded > count;
    idx(over) = period - folded(over) + 2;
end

function padded = blendPaddingTowardEdge(padded, imageData, rowCoords, colCoords, padding)
    height = size(imageData, 1);
    width = size(imageData, 2);
    [colGrid, rowGrid] = meshgrid(colCoords, rowCoords);

    inside = colGrid >= 1 & colGrid <= width & rowGrid >= 1 & rowGrid <= height;
    outsideDistance = max(max(1 - colGrid, colGrid - width), ...
        max(1 - rowGrid, rowGrid - height));
    outsideDistance(inside) = 0;

    maxPad = max([padding.left, padding.right, padding.top, padding.bottom]);
    blendWidth = min(maxPad, max(1, round(min(height, width) * 0.04)));
    alpha = smoothstep(min(1, outsideDistance ./ (blendWidth + 1)));
    alpha(inside) = 0;

    clampRows = min(max(rowGrid, 1), height);
    clampCols = min(max(colGrid, 1), width);
    if ndims(imageData) == 2
        padded = blendPlane(padded, imageData, alpha, inside, clampRows, clampCols);
    else
        blended = padded;
        for channel = 1:size(imageData, 3)
            blended(:, :, channel) = blendPlane(padded(:, :, channel), ...
                imageData(:, :, channel), alpha, inside, clampRows, clampCols);
        end
        padded = blended;
    end
end

function weights = smoothstep(x)
    weights = x .* x .* (3 - 2 .* x);
end

function plane = blendPlane(paddedPlane, sourcePlane, alpha, inside, clampRows, clampCols)
    edgeLinear = sub2ind(size(sourcePlane), clampRows, clampCols);
    edgePlane = double(sourcePlane(edgeLinear));
    reflected = double(paddedPlane);
    blended = alpha .* reflected + (1 - alpha) .* edgePlane;
    blended(inside) = reflected(inside);
    plane = castPlane(blended, sourcePlane);
end

function plane = castPlane(values, sourcePlane)
    if isinteger(sourcePlane)
        className = class(sourcePlane);
        minValue = double(intmin(className));
        maxValue = double(intmax(className));
        values = min(max(round(values), minValue), maxValue);
        plane = cast(values, className);
    else
        plane = cast(values, class(sourcePlane));
    end
end

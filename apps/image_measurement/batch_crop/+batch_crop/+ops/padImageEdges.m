% App-owned edge-padding helper. Expected caller: batch-crop preview/export
% transforms and package tests. Inputs are an image array and a padding
% percent. Output preserves class and pads from edge-continuous pixels with a
% small, clipped reflected residual so large padding does not mirror high
% contrast source content into the synthetic area.
function [padded, padding] = padImageEdges(imageData, paddingPercent)
%PADIMAGEEDGES Expand an image using edge-continuous low-artifact padding.

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
    clampedRows = min(max(rowCoords, 1), height);
    clampedCols = min(max(colCoords, 1), width);

    if ndims(imageData) == 2
        reflected = imageData(rowIdx, colIdx);
        edgeBase = imageData(clampedRows, clampedCols);
    else
        reflected = imageData(rowIdx, colIdx, :);
        edgeBase = imageData(clampedRows, clampedCols, :);
    end

    if islogical(imageData)
        padded = edgeBase;
        return;
    end

    padded = blendClippedResidual(edgeBase, reflected, imageData, rowCoords, colCoords, padding);
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

function padded = blendClippedResidual(edgeBase, reflected, imageData, rowCoords, colCoords, padding)
    height = size(imageData, 1);
    width = size(imageData, 2);
    [colGrid, rowGrid] = meshgrid(colCoords, rowCoords);

    inside = colGrid >= 1 & colGrid <= width & rowGrid >= 1 & rowGrid <= height;
    outsideDistance = max(max(1 - colGrid, colGrid - width), ...
        max(1 - rowGrid, rowGrid - height));
    outsideDistance(inside) = 0;

    residualWeight = residualBlendWeights(outsideDistance, inside, padding, height, width);

    if ndims(imageData) == 2
        padded = blendPlane(edgeBase, reflected, imageData, residualWeight, inside);
    else
        blended = edgeBase;
        for channel = 1:size(imageData, 3)
            blended(:, :, channel) = blendPlane(edgeBase(:, :, channel), ...
                reflected(:, :, channel), imageData(:, :, channel), residualWeight, inside);
        end
        padded = blended;
    end
end

function weights = residualBlendWeights(outsideDistance, inside, padding, height, width)
    maxPad = max([padding.left, padding.right, padding.top, padding.bottom]);
    if maxPad == 0
        weights = zeros(size(outsideDistance));
        return;
    end

    fadeInWidth = max(1, min(maxPad, round(min(height, width) * 0.02)));
    fadeOutWidth = max(fadeInWidth + 1, round(maxPad * 0.65));
    fadeIn = smoothstep(min(1, max(0, outsideDistance - 1) ./ fadeInWidth));
    fadeOut = 1 - smoothstep(min(1, max(0, outsideDistance - fadeInWidth) ./ fadeOutWidth));
    weights = 0.18 .* fadeIn .* fadeOut;
    weights(inside) = 0;
end

function weights = smoothstep(x)
    weights = x .* x .* (3 - 2 .* x);
end

function plane = blendPlane(edgeBasePlane, reflectedPlane, sourcePlane, residualWeight, inside)
    edgeBase = double(edgeBasePlane);
    residual = double(reflectedPlane) - edgeBase;
    residualLimit = robustResidualLimit(sourcePlane);
    residual = min(max(residual, -residualLimit), residualLimit);
    blended = edgeBase + residualWeight .* residual;
    blended(inside) = double(sourcePlane);
    plane = castPlane(blended, sourcePlane);
end

function limit = robustResidualLimit(sourcePlane)
    values = double(sourcePlane(:));
    dynamicRange = max(values) - min(values);
    if dynamicRange == 0
        limit = 0;
        return;
    end

    limit = max(eps, 0.06 * dynamicRange);
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

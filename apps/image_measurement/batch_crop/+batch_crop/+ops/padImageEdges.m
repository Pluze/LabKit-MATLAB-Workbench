% App-owned edge-padding helper. Expected caller: batch-crop preview/export
% transforms and package tests. Inputs are an image array and a padding
% percent. Output preserves class and pads from edge-continuous pixels that
% fade into reflected texture so crop previews stay visually continuous.
function [padded, padding] = padImageEdges(imageData, paddingPercent)
%PADIMAGEEDGES Expand an image using edge-blended reflected texture.

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
        'bottom', padY, ...
        'repairWidthX', edgeRepairWidth(width, padX), ...
        'repairWidthY', edgeRepairWidth(height, padY));

    if padX == 0 && padY == 0
        padded = imageData;
        return;
    end

    rowCoords = (1 - padY):(height + padY);
    colCoords = (1 - padX):(width + padX);
    repaired = repairImageBorder(imageData, padding.repairWidthY, padding.repairWidthX);
    rowIdx = reflectedSubscripts(rowCoords, height);
    colIdx = reflectedSubscripts(colCoords, width);

    if ndims(imageData) == 2
        padded = repaired(rowIdx, colIdx);
    else
        padded = repaired(rowIdx, colIdx, :);
    end
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
    percent = min(max(percent, 0), 200);
end

function width = edgeRepairWidth(count, padSize)
    if padSize <= 0 || count <= 4
        width = 0;
        return;
    end

    width = min([96, padSize, max(8, round(count * 0.06)), floor(count / 2)]);
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

function repaired = repairImageBorder(imageData, rowWidth, colWidth)
    if islogical(imageData) || (rowWidth == 0 && colWidth == 0)
        repaired = imageData;
        return;
    end

    if ndims(imageData) == 2
        repaired = repairPlane(imageData, rowWidth, colWidth);
    else
        repaired = imageData;
        for channel = 1:size(imageData, 3)
            repaired(:, :, channel) = repairPlane(imageData(:, :, channel), rowWidth, colWidth);
        end
    end
end

function plane = repairPlane(inputPlane, rowWidth, colWidth)
    values = double(inputPlane);
    repaired = values;
    height = size(values, 1);
    width = size(values, 2);

    if colWidth > 0
        leftCols = 1:colWidth;
        leftTargets = 2 * colWidth:-1:(colWidth + 1);
        weights = edgeRepairWeights(colWidth);
        repaired(:, leftCols) = blendColumns(values(:, leftCols), values(:, leftTargets), weights);

        rightCols = (width - colWidth + 1):width;
        rightTargets = (width - colWidth):-1:(width - 2 * colWidth + 1);
        repaired(:, rightCols) = blendColumns(values(:, rightCols), values(:, rightTargets), fliplr(weights));
    end

    if rowWidth > 0
        topRows = 1:rowWidth;
        topTargets = 2 * rowWidth:-1:(rowWidth + 1);
        weights = edgeRepairWeights(rowWidth).';
        repaired(topRows, :) = blendRows(repaired(topRows, :), repaired(topTargets, :), weights);

        bottomRows = (height - rowWidth + 1):height;
        bottomTargets = (height - rowWidth):-1:(height - 2 * rowWidth + 1);
        repaired(bottomRows, :) = blendRows(repaired(bottomRows, :), ...
            repaired(bottomTargets, :), flipud(weights));
    end

    plane = castPlane(repaired, inputPlane);
end

function values = blendColumns(edgeValues, sourceValues, weights)
    values = (1 - weights) .* edgeValues + weights .* sourceValues;
end

function values = blendRows(edgeValues, sourceValues, weights)
    values = (1 - weights) .* edgeValues + weights .* sourceValues;
end

function weights = edgeRepairWeights(width)
    x = linspace(1, 0, width);
    weights = x .* x .* (3 - 2 .* x);
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

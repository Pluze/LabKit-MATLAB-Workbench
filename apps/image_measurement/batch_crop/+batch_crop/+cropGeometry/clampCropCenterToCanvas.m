% Expected caller: batch_crop run callbacks and crop/export helpers. Inputs
% are a prepareCropCanvas geometry struct, candidate original-image [x y]
% center, and [cropWidth cropHeight]. Output is the minimally shifted
% original-image center whose crop rectangle fits inside the current valid
% image mask when possible, falling back to canvas bounds when no complete
% mask-covered placement exists.
function centerXY = clampCropCenterToCanvas(geometry, centerXY, cropSize)
%CLAMPCROPCENTERCANVAS Shift crop center so the ROI stays on valid image pixels.

    centerXY = double(centerXY(:)).';
    if numel(centerXY) ~= 2 || any(~isfinite(centerXY))
        centerXY = [(geometry.sourceWidth + 1) / 2, ...
            (geometry.sourceHeight + 1) / 2];
    end
    cropSize = double(cropSize(:)).';
    if numel(cropSize) ~= 2 || any(~isfinite(cropSize)) || any(cropSize < 1)
        error('labkit_BatchImageCrop_app:InvalidCropSize', ...
            'Crop size must be a positive [width height] pair.');
    end

    canvasXY = nearestValidCanvasCenter(geometry, ...
        batch_crop.cropGeometry.originalToCanvas(geometry, centerXY), cropSize);
    centerXY = batch_crop.cropGeometry.canvasToOriginal(geometry, canvasXY);
end

function canvasXY = nearestValidCanvasCenter(geometry, canvasXY, cropSize)
    scale = geometryScale(geometry);
    cropWidth = max(1, round(double(cropSize(1)) * scale));
    cropHeight = max(1, round(double(cropSize(2)) * scale));
    mask = currentMask(geometry);
    coverage = cachedTopLeftCoverage(mask, cropWidth, cropHeight);
    if ~isempty(coverage)
        targetCol = min(max(round(canvasXY(1) - (cropWidth - 1) / 2), 1), ...
            size(coverage, 2));
        targetRow = min(max(round(canvasXY(2) - (cropHeight - 1) / 2), 1), ...
            size(coverage, 1));
        area = cropWidth * cropHeight;
        [row, col, found] = nearestTrue(coverage == area, targetRow, targetCol);
        if ~found
            bestCoverage = max(coverage, [], "all");
            [row, col, found] = nearestTrue(coverage == bestCoverage, ...
                targetRow, targetCol);
        end
        if found
            canvasXY = [double(col) + (cropWidth - 1) / 2, ...
                double(row) + (cropHeight - 1) / 2];
            return;
        end
    end

    bounds = maskBounds(mask);
    canvasXY(1) = clampCenterAxis(canvasXY(1), cropWidth, bounds(1), bounds(2));
    canvasXY(2) = clampCenterAxis(canvasXY(2), cropHeight, bounds(3), bounds(4));
end

function [row, col, found] = nearestTrue(tf, targetRow, targetCol)
    row = NaN;
    col = NaN;
    found = false;
    if isempty(tf) || ~any(tf, "all")
        return;
    end
    if tf(targetRow, targetCol)
        row = targetRow;
        col = targetCol;
        found = true;
        return;
    end

    maxRadius = max([targetRow - 1, targetCol - 1, ...
        size(tf, 1) - targetRow, size(tf, 2) - targetCol]);
    radius = 1;
    while radius <= maxRadius
        rowStart = max(1, targetRow - radius);
        rowEnd = min(size(tf, 1), targetRow + radius);
        colStart = max(1, targetCol - radius);
        colEnd = min(size(tf, 2), targetCol + radius);
        window = tf(rowStart:rowEnd, colStart:colEnd);
        if any(window, "all")
            [rows, cols] = find(window);
            rows = rows + rowStart - 1;
            cols = cols + colStart - 1;
            distances = (double(rows) - targetRow) .^ 2 + ...
                (double(cols) - targetCol) .^ 2;
            [~, idx] = min(distances);
            row = rows(idx);
            col = cols(idx);
            found = true;
            return;
        end
        radius = min(maxRadius + 1, radius * 2);
    end
end

function scale = geometryScale(geometry)
    scale = 1;
    if isfield(geometry, 'coordinateScale') && isfinite(double(geometry.coordinateScale)) && ...
            double(geometry.coordinateScale) > 0
        scale = double(geometry.coordinateScale);
    end
end

function mask = currentMask(geometry)
    if isfield(geometry, 'mask') && ~isempty(geometry.mask)
        mask = logical(geometry.mask);
    else
        mask = true(size(geometry.canvas, 1), size(geometry.canvas, 2));
    end
    if ~ismatrix(mask)
        mask = mask(:, :, 1);
    end
    if ~any(mask, "all")
        mask = true(size(geometry.canvas, 1), size(geometry.canvas, 2));
    end
end

function coverage = cachedTopLeftCoverage(mask, cropWidth, cropHeight)
    persistent cacheMask cacheCropWidth cacheCropHeight cacheCoverage
    if ~isempty(cacheCoverage) && isequal(cacheCropWidth, cropWidth) && ...
            isequal(cacheCropHeight, cropHeight) && isequal(cacheMask, mask)
        coverage = cacheCoverage;
        return;
    end
    coverage = topLeftCoverage(mask, cropWidth, cropHeight);
    cacheMask = mask;
    cacheCropWidth = cropWidth;
    cacheCropHeight = cropHeight;
    cacheCoverage = coverage;
end

function coverage = topLeftCoverage(mask, cropWidth, cropHeight)
    [height, width] = size(mask);
    if cropWidth > width || cropHeight > height
        coverage = zeros(0, 0);
        return;
    end

    sat = cumsum(cumsum(double(mask), 1), 2);
    sat = [zeros(1, size(sat, 2) + 1); zeros(size(sat, 1), 1), sat];
    sums = sat((1 + cropHeight):end, (1 + cropWidth):end) - ...
        sat(1:(end - cropHeight), (1 + cropWidth):end) - ...
        sat((1 + cropHeight):end, 1:(end - cropWidth)) + ...
        sat(1:(end - cropHeight), 1:(end - cropWidth));
    coverage = sums;
end

function bounds = maskBounds(mask)
    [rows, cols] = find(mask);
    if isempty(rows)
        bounds = [1, size(mask, 2), 1, size(mask, 1)];
        return;
    end
    bounds = [min(cols), max(cols), min(rows), max(rows)];
end

function value = clampCenterAxis(value, cropLength, minEdge, maxEdge)
    minCenter = double(minEdge) + (cropLength - 1) / 2;
    maxCenter = double(maxEdge) - (cropLength - 1) / 2;
    if minCenter > maxCenter
        value = (double(minEdge) + double(maxEdge)) / 2;
        return;
    end
    value = min(max(double(value), minCenter), maxCenter);
end

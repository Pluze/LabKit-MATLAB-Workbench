% App-owned preview/export transform helper. Expected caller: batch-crop app
% callbacks, cropImage, and package tests. Inputs are source image data and
% options with angleDeg, paddingPercent, and optional fillValue. Output is a
% struct containing the padded/rotated canvas and original-coordinate transform
% metadata; source coordinates remain based on the unpadded image.
function geometry = prepareCropCanvas(imageData, opts)
%PREPARECROPCANVAS Build the padded rotation canvas and coordinate transform.

    if nargin < 2
        opts = struct();
    end

    angleDeg = double(optionValue(opts, 'angleDeg', 0));
    paddingPercent = double(optionValue(opts, 'paddingPercent', 0));
    fillValue = batch_crop.cropGeometry.whiteFillValue(imageData, opts);

    sourceHeight = size(imageData, 1);
    sourceWidth = size(imageData, 2);
    [canvasSource, coordinateScale] = previewSourceImage(imageData, ...
        paddingPercent, opts);
    [padded, padding] = batch_crop.cropGeometry.padImageEdges(canvasSource, paddingPercent);

    if isIdentityRotation(angleDeg)
        canvas = padded;
        mask = true(size(padded, 1), size(padded, 2));
        rotation = struct( ...
            'identity', true, ...
            'angleDeg', angleDeg, ...
            'centerX', NaN, ...
            'centerY', NaN, ...
            'minX', NaN, ...
            'minY', NaN);
    else
        [canvas, mask, rotation] = batch_crop.cropGeometry.rotateCanvas(padded, angleDeg, fillValue);
        rotation.identity = false;
    end

    geometry = struct( ...
        'canvas', canvas, ...
        'mask', mask, ...
        'angleDeg', angleDeg, ...
        'paddingPercent', padding.percent, ...
        'padding', padding, ...
        'coordinateScale', coordinateScale, ...
        'sourceWidth', sourceWidth, ...
        'sourceHeight', sourceHeight, ...
        'previewSourceWidth', size(canvasSource, 2), ...
        'previewSourceHeight', size(canvasSource, 1), ...
        'paddedWidth', size(padded, 2), ...
        'paddedHeight', size(padded, 1), ...
        'fillValue', fillValue, ...
        'rotation', rotation);
end

function [canvasSource, coordinateScale] = previewSourceImage(imageData, paddingPercent, opts)
    maxCanvasPixels = double(optionValue(opts, 'maxCanvasPixels', Inf));
    if ~isfinite(maxCanvasPixels) || maxCanvasPixels <= 0
        canvasSource = imageData;
        coordinateScale = 1;
        return;
    end

    expansion = estimatedPaddingExpansion(paddingPercent);
    [canvasSource, info] = labkit.image.previewBudget(imageData, ...
        "MaxPixels", maxCanvasPixels, ...
        "Expansion", expansion);
    coordinateScale = info.coordinateScale;
end

function expansion = estimatedPaddingExpansion(paddingPercent)
    percent = min(max(double(paddingPercent), 0), 200);
    expansion = (1 + 2 * percent / 100) ^ 2;
end

function tf = isIdentityRotation(angleDeg)
    tf = abs(mod(double(angleDeg), 360)) < 1e-12;
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end

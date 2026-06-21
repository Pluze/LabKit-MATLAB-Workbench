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
    fillValue = batch_crop.ops.whiteFillValue(imageData, opts);

    [padded, padding] = batch_crop.ops.padImageEdges(imageData, paddingPercent);
    sourceHeight = size(imageData, 1);
    sourceWidth = size(imageData, 2);

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
        [canvas, mask, rotation] = batch_crop.ops.rotateCanvas(padded, angleDeg, fillValue);
        rotation.identity = false;
    end

    geometry = struct( ...
        'canvas', canvas, ...
        'mask', mask, ...
        'angleDeg', angleDeg, ...
        'paddingPercent', padding.percent, ...
        'padding', padding, ...
        'sourceWidth', sourceWidth, ...
        'sourceHeight', sourceHeight, ...
        'paddedWidth', size(padded, 2), ...
        'paddedHeight', size(padded, 1), ...
        'fillValue', fillValue, ...
        'rotation', rotation);
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

% App-owned microscope image crop helper. Expected caller: batch-crop app
% callbacks and package tests. Inputs are an image array and crop options.
% Output is a result struct with the cropped image and crop metadata.
function result = cropImage(imageData, opts)
%CROPIMAGE Rotate an image canvas and crop a fixed pixel rectangle.
% Expected caller: labkit_BatchImageCrop_app and batch_crop package tests.
% Inputs are an image array and opts with cropWidth, cropHeight, angleDeg,
% centerXY, fillMode, or fillValue. Output preserves image class and returns
% exactly cropHeight-by-cropWidth pixels, padding when the crop crosses canvas
% bounds. This helper does not resize the image and has no file side effects.

    if nargin < 2
        opts = struct();
    end
    validateImageData(imageData);

    cropWidth = requiredPositiveInteger(opts, 'cropWidth');
    cropHeight = requiredPositiveInteger(opts, 'cropHeight');
    angleDeg = double(optionValue(opts, 'angleDeg', 0));
    fillValue = fillValueForImage(imageData, opts);

    [canvas, mask] = batch_crop.ops.rotateCanvas(imageData, angleDeg, fillValue);
    centerXY = optionValue(opts, 'centerXY', []);
    if isempty(centerXY) || numel(centerXY) ~= 2 || any(~isfinite(double(centerXY)))
        centerXY = [(size(canvas, 2) + 1) / 2, (size(canvas, 1) + 1) / 2];
    else
        centerXY = double(centerXY(:)).';
    end

    cropped = batch_crop.ops.cropCanvasFixedSize(canvas, centerXY, [cropWidth, cropHeight], fillValue);

    result = batch_crop.state.emptyResult();
    result.ok = true;
    result.status = "cropped";
    result.image = cropped;
    result.rotationDeg = angleDeg;
    result.centerX = centerXY(1);
    result.centerY = centerXY(2);
    result.cropWidth = cropWidth;
    result.cropHeight = cropHeight;
    result.canvasWidth = size(canvas, 2);
    result.canvasHeight = size(canvas, 1);
    result.message = "OK";
end

function validateImageData(imageData)
    if isempty(imageData) || ~(isnumeric(imageData) || islogical(imageData)) || ndims(imageData) > 3
        error('labkit_BatchImageCrop_app:InvalidImage', ...
            'Image data must be a nonempty numeric or logical 2-D or 3-D image array.');
    end
end

function value = requiredPositiveInteger(opts, name)
    raw = optionValue(opts, name, []);
    if isempty(raw) || ~isscalar(raw) || ~isfinite(double(raw)) || double(raw) < 1
        error('labkit_BatchImageCrop_app:InvalidCropSize', ...
            'Crop %s must be a positive pixel count.', name);
    end
    value = max(1, round(double(raw)));
end

function value = fillValueForImage(imageData, opts)
    if isfield(opts, 'fillValue') && ~isempty(opts.fillValue)
        value = double(opts.fillValue(1));
        return;
    end

    mode = lower(char(string(optionValue(opts, 'fillMode', 'Black'))));
    if strcmp(mode, 'white')
        if islogical(imageData)
            value = 1;
        elseif isinteger(imageData)
            value = double(intmax(class(imageData)));
        else
            maxPixel = max(double(imageData(:)));
            if maxPixel > 1
                value = 255;
            else
                value = 1;
            end
        end
    else
        value = 0;
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end

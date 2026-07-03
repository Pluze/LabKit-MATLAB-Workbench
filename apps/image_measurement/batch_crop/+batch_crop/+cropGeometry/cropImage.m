% App-owned microscope image crop helper. Expected caller: batch-crop app
% callbacks and package tests. Inputs are an image array and crop options.
% Output is a result struct with the cropped image and crop metadata.
function result = cropImage(imageData, opts)
%CROPIMAGE Pad/rotate an image canvas and crop a fixed pixel rectangle.
% Expected caller: labkit_BatchImageCrop_app and batch_crop package tests.
% Inputs are an image array and opts with cropWidth, cropHeight, angleDeg,
% centerXY in original-image coordinates, paddingPercent, or fillValue.
% Output preserves image class and returns exactly cropHeight-by-cropWidth
% pixels, padding when the crop crosses canvas bounds. This helper does not
% resize the source image and has no file side effects.

    if nargin < 2
        opts = struct();
    end
    validateImageData(imageData);

    cropWidth = requiredPositiveInteger(opts, 'cropWidth');
    cropHeight = requiredPositiveInteger(opts, 'cropHeight');
    angleDeg = double(optionValue(opts, 'angleDeg', 0));
    paddingPercent = double(optionValue(opts, 'paddingPercent', 0));

    geometry = batch_crop.cropGeometry.prepareCropCanvas(imageData, struct( ...
        'angleDeg', angleDeg, ...
        'paddingPercent', paddingPercent, ...
        'fillValue', optionValue(opts, 'fillValue', [])));
    centerXY = optionValue(opts, 'centerXY', []);
    if isempty(centerXY) || numel(centerXY) ~= 2 || any(~isfinite(double(centerXY)))
        centerXY = [(size(imageData, 2) + 1) / 2, (size(imageData, 1) + 1) / 2];
    else
        centerXY = double(centerXY(:)).';
    end
    centerXY = batch_crop.cropGeometry.clampCropCenterToCanvas(geometry, centerXY, ...
        [cropWidth, cropHeight]);

    canvasCenterXY = batch_crop.cropGeometry.originalToCanvas(geometry, centerXY);
    cropped = batch_crop.cropGeometry.cropCanvasFixedSize(geometry.canvas, canvasCenterXY, ...
        [cropWidth, cropHeight], geometry.fillValue);

    result = batch_crop.appState.emptyResult();
    result.ok = true;
    result.status = "cropped";
    result.image = cropped;
    result.rotationDeg = angleDeg;
    result.paddingPercent = geometry.paddingPercent;
    result.centerX = centerXY(1);
    result.centerY = centerXY(2);
    result.cropWidth = cropWidth;
    result.cropHeight = cropHeight;
    result.sourceWidth = size(imageData, 2);
    result.sourceHeight = size(imageData, 1);
    result.scaleMode = "Pixels";
    result.nativeCropWidth = cropWidth;
    result.nativeCropHeight = cropHeight;
    result.outputWidth = cropWidth;
    result.outputHeight = cropHeight;
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

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end

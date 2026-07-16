function result = cropImage(imageData, opts)
%CROPIMAGE Rotate and crop an image at a fixed pixel size.
%
% Usage:
%   result = batch_crop.cropGeometry.cropImage(imageData, opts)
%
% Description:
%   Adds optional padding, rotates the resulting canvas, and extracts a crop
%   centered at a point expressed in the original image coordinate system.
%   The crop always has the requested pixel dimensions. Areas outside the
%   transformed canvas use the selected fill value. This function does not
%   resize the crop, display graphics, or write files.
%
% Inputs:
%   imageData - Nonempty numeric or logical image. Accepted sizes are M-by-N
%       and M-by-N-by-C. The output preserves its class and channel count.
%   opts - Scalar structure containing the crop options below.
%
% Options:
%   cropWidth - Required positive pixel count. Noninteger values are rounded.
%   cropHeight - Required positive pixel count. Noninteger values are rounded.
%   angleDeg - Counterclockwise canvas rotation in degrees. Default: 0.
%   centerXY - Crop center [x y] in original-image pixel coordinates, where x
%       is the column and y is the row. Invalid or empty input selects the
%       geometric image center. The center is limited so the requested crop
%       remains representable on the prepared canvas. Default: [].
%   paddingPercent - Padding added around each source edge as a percentage of
%       the corresponding source dimension. Negative values are treated as
%       zero by the canvas preparation code. Default: 0.
%   fillValue - Scalar or channel-compatible value used outside the rotated
%       image. Empty input selects the app's white value for imageData.
%       Default: [].
%
% Outputs:
%   result - Scalar crop result structure. result.image is exactly
%       cropHeight-by-cropWidth-by-C. result.centerX and centerY retain the
%       effective center in original-image coordinates. rotationDeg,
%       paddingPercent, sourceWidth, sourceHeight, cropWidth, cropHeight,
%       nativeCropWidth, nativeCropHeight, outputWidth, and outputHeight
%       describe the operation. scaleMode is "Pixels", ok is true, status is
%       "cropped", and message is "OK".
%
% Errors:
%   labkit_BatchImageCrop_app:InvalidImage - imageData is empty, nonnumeric,
%       nonlogical, or has more than three dimensions.
%   labkit_BatchImageCrop_app:InvalidCropSize - cropWidth or cropHeight is
%       absent, nonfinite, nonscalar, or smaller than one.
%
% Example:
%   imageData = reshape(uint8(1:100), 10, 10);
%   opts = struct("cropWidth", 4, "cropHeight", 3, "centerXY", [5 6]);
%   result = batch_crop.cropGeometry.cropImage(imageData, opts);
%   assert(result.ok && isequal(size(result.image), [3 4]))
%
% See also batch_crop.cropGeometry.cropScaledImage,
%   batch_crop.cropGeometry.scalePlan

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

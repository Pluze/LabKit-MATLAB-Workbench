function result = cropScaledImage(imageData, opts, plan, itemIndex)
%CROPSCALEDIMAGE Crop one calibrated image to a common physical output scale.
%
% Usage:
%   result = batch_crop.cropGeometry.cropScaledImage(imageData, opts, plan)
%   result = batch_crop.cropGeometry.cropScaledImage(imageData, opts, plan, itemIndex)
%
% Description:
%   Uses the selected item's native crop dimensions from scalePlan, delegates
%   rotation and cropping to batch_crop.cropGeometry.cropImage, then resamples
%   the crop to the plan's common output dimensions. Resampling uses bilinear
%   interpolation independently for every channel and preserves image class.
%   The function has no graphics or file side effects.
%
% Inputs:
%   imageData - Nonempty numeric or logical M-by-N or M-by-N-by-C image.
%   opts - Crop option structure accepted by cropImage. cropWidth and
%       cropHeight are replaced by the native dimensions selected by plan.
%   plan - Scalar structure returned by batch_crop.cropGeometry.scalePlan.
%   itemIndex - Positive index selecting nativeCropWidth,
%       nativeCropHeight, sourcePixelsPerUnit, resampleFactor, and warnings
%       for imageData. Default: 1.
%
% Options:
%   angleDeg - Counterclockwise canvas rotation in degrees. Default: 0.
%   centerXY - Crop center [x y] in original-image pixel coordinates. Empty or
%       invalid input selects the image center. Default: [].
%   paddingPercent - Padding around the source before rotation, as a percentage
%       of each source dimension. Default: 0.
%   fillValue - Value used outside the rotated image. Empty selects the app's
%       white value for imageData. Default: [].
%
% Outputs:
%   result - cropImage result updated for physical mode. result.image has
%       plan.outputHeight rows and plan.outputWidth columns. cropWidth and
%       cropHeight describe that output; nativeCropWidth and nativeCropHeight
%       describe the pre-resampling crop. scaleUnit, sourcePixelsPerUnit,
%       targetPixelsPerUnit, resampleFactor, and scaleWarning come from plan.
%
% Example:
%   imageData = reshape(uint8(1:100), 10, 10);
%   opts = struct("centerXY", [5 5]);
%   plan = struct("nativeCropWidth", 4, "nativeCropHeight", 4, ...
%       "outputWidth", 8, "outputHeight", 6, "unit", "um", ...
%       "sourcePixelsPerUnit", 2, "targetPixelsPerUnit", 4, ...
%       "resampleFactor", 2, "warnings", "");
%   result = batch_crop.cropGeometry.cropScaledImage(imageData, opts, plan);
%   assert(isequal(size(result.image), [6 8]))
%
% See also batch_crop.cropGeometry.cropImage,
%   batch_crop.cropGeometry.scalePlan

    if nargin < 4
        itemIndex = 1;
    end
    nativeWidth = plan.nativeCropWidth(itemIndex);
    nativeHeight = plan.nativeCropHeight(itemIndex);
    outputWidth = plan.outputWidth;
    outputHeight = plan.outputHeight;

    cropOpts = opts;
    cropOpts.cropWidth = nativeWidth;
    cropOpts.cropHeight = nativeHeight;
    result = batch_crop.cropGeometry.cropImage(imageData, cropOpts);
    if size(result.image, 2) ~= outputWidth || size(result.image, 1) ~= outputHeight
        result.image = resizeImage(result.image, [outputHeight, outputWidth]);
    end

    result.cropWidth = outputWidth;
    result.cropHeight = outputHeight;
    result.scaleMode = "Physical";
    result.scaleUnit = plan.unit;
    result.sourcePixelsPerUnit = plan.sourcePixelsPerUnit(itemIndex);
    result.targetPixelsPerUnit = plan.targetPixelsPerUnit;
    result.resampleFactor = plan.resampleFactor(itemIndex);
    result.nativeCropWidth = nativeWidth;
    result.nativeCropHeight = nativeHeight;
    result.outputWidth = outputWidth;
    result.outputHeight = outputHeight;
    result.scaleWarning = plan.warnings(itemIndex);
end

function out = resizeImage(imageData, outputSize)
    inHeight = size(imageData, 1);
    inWidth = size(imageData, 2);
    y = linspace(1, inHeight, outputSize(1));
    x = linspace(1, inWidth, outputSize(2));
    [xq, yq] = meshgrid(x, y);
    out = zeros([outputSize, size(imageData, 3)], 'like', imageData);
    for c = 1:size(imageData, 3)
        channel = double(imageData(:, :, c));
        resized = interp2(channel, xq, yq, 'linear');
        out(:, :, c) = cast(resized, class(imageData));
    end
end

% App-owned physical-scale crop helper. Expected caller: batch-crop export
% and tests. Inputs are one image, crop options, and a per-image scale plan.
% Output is a crop result whose image is resized to the planned output pixels.
function result = cropScaledImage(imageData, opts, plan, itemIndex)
%CROPSCALEDIMAGE Crop native physical ROI and resample to target output size.

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
    if exist('imresize', 'file') == 2
        out = imresize(imageData, outputSize, 'bicubic');
        return;
    end

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

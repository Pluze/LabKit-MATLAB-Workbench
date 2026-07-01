% Expected caller: labkit_ImageEnhance_app preview rendering. Input is an image
% array and optional maximum display height. Output is RGB double preview data
% downsampled for responsive UI display plus display-to-source scale; export
% data remains full resolution.
function [imageOut, scale] = previewImage(imageIn, maxHeight)
%PREVIEWIMAGE Normalize and downsample display-only preview image data.

    if nargin < 2 || isempty(maxHeight)
        maxHeight = 1500;
    end
    imageOut = labkit.image.toRgbDouble(imageIn);
    [imageOut, scale] = labkit.image.resizeToFit(imageOut, ...
        "MaxHeight", maxHeight);
end

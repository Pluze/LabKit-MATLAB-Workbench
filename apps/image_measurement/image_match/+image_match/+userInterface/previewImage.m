% Expected caller: labkit_ImageMatch_app preview rendering. Input is an image
% array and optional maximum display height. Output is RGB double preview data
% downsampled for responsive UI display; export data remains full resolution.
function imageOut = previewImage(imageIn, maxHeight)
%PREVIEWIMAGE Normalize and downsample display-only preview image data.

    if nargin < 2 || isempty(maxHeight)
        maxHeight = 1500;
    end
    imageOut = labkit.image.ensureRgb(labkit.image.im2double(imageIn));
    imageOut = min(max(imageOut, 0), 1);
    imageOut = labkit.image.resizeToFit(imageOut, "MaxHeight", maxHeight);
end

function imageOut = toRgbDouble(imageIn)
%TORGBDOUBLE Normalize image data to RGB double in [0, 1].
%
% App-facing contract:
%   imageOut = labkit.image.toRgbDouble(imageIn)
%
% Inputs:
%   imageIn - numeric image data. Grayscale images are expanded to RGB, RGB
%       images are preserved, and channels beyond RGB are ignored.
%
% Outputs:
%   imageOut - double image data clamped to [0, 1]. Empty input returns [].

    if isempty(imageIn)
        imageOut = [];
        return;
    end
    imageOut = labkit.image.toDouble(imageIn);
    if ndims(imageOut) == 2
        imageOut = repmat(imageOut, 1, 1, 3);
    elseif size(imageOut, 3) > 3
        imageOut = imageOut(:, :, 1:3);
    end
    imageOut = min(max(imageOut, 0), 1);
end

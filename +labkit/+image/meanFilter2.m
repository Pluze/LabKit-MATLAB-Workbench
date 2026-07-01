function imageOut = meanFilter2(imageIn, windowSize)
%MEANFILTER2 Apply normalized 2-D mean filtering with edge correction.
%
% App-facing contract:
%   imageOut = labkit.image.meanFilter2(imageIn, windowSize)
%
% Inputs:
%   imageIn - 2-D image data or 3-D image stack/channels.
%   windowSize - scalar neighborhood width. Values are rounded and clamped
%       to at least 1.
%
% Outputs:
%   imageOut - double same-size local mean. Edge pixels are normalized by the
%       number of contributing samples, matching conv2 same-size behavior.

    windowSize = max(1, round(double(windowSize)));
    if ndims(imageIn) <= 2
        imageOut = meanFilterPlane(imageIn, windowSize);
        return;
    end

    imageOut = zeros(size(imageIn));
    for channel = 1:size(imageIn, 3)
        imageOut(:, :, channel) = meanFilterPlane(imageIn(:, :, channel), windowSize);
    end
end

function planeOut = meanFilterPlane(planeIn, windowSize)
    kernel = ones(windowSize, windowSize);
    numerator = conv2(double(planeIn), kernel, 'same');
    denominator = conv2(ones(size(planeIn)), kernel, 'same');
    planeOut = numerator ./ max(denominator, eps);
end

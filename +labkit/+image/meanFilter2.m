function imageOut = meanFilter2(imageIn, windowSize)
%MEANFILTER2 Apply normalized 2-D mean filtering with edge correction.
%
% Usage:
%   imageOut = labkit.image.meanFilter2(imageIn, windowSize)
%
% Description:
%   Replaces each sample with the arithmetic mean of the rectangular
%   neighborhood that overlaps the image. At an edge or corner, the divisor
%   is reduced to the number of available samples instead of assuming zero
%   padding. Each channel of a 3-D image is filtered independently.
%
%   windowSize is rounded to an integer and limited to at least 1. Both odd
%   and even widths are accepted; conv2 determines the alignment of an even
%   window. Input is converted to double for calculation. NaN values are not
%   omitted and therefore propagate to neighborhoods that include them.
%
% Inputs:
%   imageIn - 2-D image matrix or 3-D image with channels in dimension 3.
%   windowSize - Numeric scalar neighborhood width in pixels.
%
% Outputs:
%   imageOut - Double array with the same size as imageIn.
%
% Example:
%   impulse = [0 0 0; 0 1 0; 0 0 0];
%   smoothed = labkit.image.meanFilter2(impulse, 3);

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

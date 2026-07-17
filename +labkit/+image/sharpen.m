function imageOut = sharpen(imageIn, amountPct, radiusPx)
%SHARPEN Apply generic unsharp-mask sharpening.
%
% Usage:
%   imageOut = labkit.image.sharpen(imageIn, amountPct, radiusPx)
%
% Description:
%   Converts imageIn to clamped RGB double and constructs an unsharp mask by
%   subtracting a square local mean from the image. The detail mask is scaled
%   by 2*amountPct/100 and added to the original. Each RGB channel is treated
%   independently, and the result is clamped to [0,1].
%
%   radiusPx selects an odd mean-filter width of 2*round(radius)+1, with a
%   minimum width of 3 pixels. This function uses a box blur rather than a
%   Gaussian blur, so radius describes neighborhood size rather than a
%   Gaussian standard deviation.
%
% Inputs:
%   imageIn - Numeric or logical grayscale, RGB, or multichannel image.
%   amountPct - Numeric scalar effect strength in percent. Negative values
%               are treated as 0.
%   radiusPx - Numeric scalar blur radius in pixels. Values below 0.5 are
%              treated as 0.5 before rounding.
%
% Outputs:
%   imageOut - M-by-N-by-3 double image with values in [0,1].
%
% Failure Behavior:
%   Unsupported image classes or channel shapes propagate errors from
%   im2double or ensureRgb. amountPct and radiusPx must be numeric scalars;
%   incompatible values raise the originating conversion or indexing error.
%
% Example:
%   imageIn = zeros(9);
%   imageIn(3:7, 3:7) = 0.6;
%   imageOut = labkit.image.sharpen(imageIn, 50, 1);
%
% See also labkit.image.meanFilter2,
%   labkit.image.localContrast

    imageIn = labkit.image.ensureRgb(labkit.image.im2double(imageIn));
    imageIn = min(max(imageIn, 0), 1);
    amount = max(0, double(amountPct)) / 100;
    radius = max(0.5, double(radiusPx));
    windowSize = max(3, 2 * round(radius) + 1);
    blurred = labkit.image.meanFilter2(imageIn, windowSize);
    imageOut = imageIn + amount .* 2.0 .* (imageIn - blurred);
    imageOut = min(max(imageOut, 0), 1);
end

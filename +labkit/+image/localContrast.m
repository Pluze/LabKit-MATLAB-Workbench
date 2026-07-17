function imageOut = localContrast(imageIn, amountPct, radiusPx)
%LOCALCONTRAST Enhance local value-channel contrast with a mean-filter mask.
%
% Usage:
%   imageOut = labkit.image.localContrast(imageIn, amountPct, radiusPx)
%
% Description:
%   Converts imageIn to clamped RGB double and operates on the HSV value
%   channel. A square local mean with width 2*radius+1 forms the low-frequency
%   reference. The difference between the value channel and that mean is
%   multiplied by 1.5*amountPct/100 and added back before clipping.
%
%   Hue and saturation are preserved by the adjustment. At image boundaries,
%   the local mean uses only available pixels. This is a lightweight local
%   contrast operation, not adaptive histogram equalization.
%
% Inputs:
%   imageIn - Numeric or logical grayscale, RGB, or multichannel image.
%   amountPct - Numeric scalar effect strength in percent. Negative values
%               are treated as 0.
%   radiusPx - Numeric scalar neighborhood radius in pixels. The value is
%              rounded and limited to at least 1.
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
%   imageIn = repmat(linspace(0.2, 0.8, 20), 10, 1);
%   imageOut = labkit.image.localContrast(imageIn, 40, 3);
%
% See also labkit.image.meanFilter2,
%   labkit.image.sharpen

    imageIn = labkit.image.ensureRgb(labkit.image.im2double(imageIn));
    imageIn = min(max(imageIn, 0), 1);
    amount = max(0, double(amountPct)) / 100;
    radius = max(1, round(double(radiusPx)));
    hsvImage = rgb2hsv(imageIn);
    valueChannel = hsvImage(:, :, 3);
    blurred = labkit.image.meanFilter2(valueChannel, 2 * radius + 1);
    hsvImage(:, :, 3) = valueChannel + amount .* 1.5 .* (valueChannel - blurred);
    hsvImage(:, :, 3) = min(max(hsvImage(:, :, 3), 0), 1);
    imageOut = min(max(hsv2rgb(hsvImage), 0), 1);
end

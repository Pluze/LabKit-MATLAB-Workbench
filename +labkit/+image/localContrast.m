function imageOut = localContrast(imageIn, amountPct, radiusPx)
%LOCALCONTRAST Enhance local value-channel contrast with a mean-filter mask.
%
% App-facing contract:
%   imageOut = labkit.image.localContrast(imageIn, amountPct, radiusPx)
%
% Inputs:
%   imageIn - numeric image data, normalized internally with toRgbDouble.
%   amountPct - nonnegative effect strength in percent.
%   radiusPx - local neighborhood radius in pixels.
%
% Outputs:
%   imageOut - RGB double image clamped to [0, 1].

    imageIn = labkit.image.toRgbDouble(imageIn);
    amount = max(0, double(amountPct)) / 100;
    radius = max(1, round(double(radiusPx)));
    hsvImage = rgb2hsv(imageIn);
    valueChannel = hsvImage(:, :, 3);
    blurred = labkit.image.meanFilter2(valueChannel, 2 * radius + 1);
    hsvImage(:, :, 3) = valueChannel + amount .* 1.5 .* (valueChannel - blurred);
    hsvImage(:, :, 3) = min(max(hsvImage(:, :, 3), 0), 1);
    imageOut = min(max(hsv2rgb(hsvImage), 0), 1);
end

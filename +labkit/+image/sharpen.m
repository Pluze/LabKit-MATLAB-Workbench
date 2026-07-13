function imageOut = sharpen(imageIn, amountPct, radiusPx)
%SHARPEN Apply generic unsharp-mask sharpening.
%
% App-facing contract:
%   imageOut = labkit.image.sharpen(imageIn, amountPct, radiusPx)
%
% Inputs:
%   imageIn - numeric image data, normalized internally to RGB double.
%   amountPct - nonnegative effect strength in percent.
%   radiusPx - blur radius in pixels.
%
% Outputs:
%   imageOut - RGB double image clamped to [0, 1].

    imageIn = labkit.image.ensureRgb(labkit.image.im2double(imageIn));
    imageIn = min(max(imageIn, 0), 1);
    amount = max(0, double(amountPct)) / 100;
    radius = max(0.5, double(radiusPx));
    windowSize = max(3, 2 * round(radius) + 1);
    blurred = labkit.image.meanFilter2(imageIn, windowSize);
    imageOut = imageIn + amount .* 2.0 .* (imageIn - blurred);
    imageOut = min(max(imageOut, 0), 1);
end

function imageOut = adjustHueSaturation(imageIn, hueDeg, saturationPct)
%ADJUSTHUESATURATION Apply HSV hue and saturation adjustment.
%
% Usage:
%   imageOut = labkit.image.adjustHueSaturation(imageIn, hueDeg, saturationPct)
%
% Description:
%   Converts imageIn to clamped RGB double and then to HSV. hueDeg rotates the
%   hue circle and wraps at 360 degrees. Saturation is multiplied by
%   1 + saturationPct/100 and limited to [0,1]. The HSV value channel is not
%   changed directly.
%
%   A saturationPct of -100 or less produces grayscale. Positive saturation
%   increases colorfulness until individual saturation values reach 1.
%
% Inputs:
%   imageIn - Numeric or logical grayscale, RGB, or multichannel image.
%   hueDeg - Numeric scalar hue rotation in degrees. Values outside one turn
%            are wrapped.
%   saturationPct - Numeric scalar percent change in HSV saturation.
%
% Outputs:
%   imageOut - M-by-N-by-3 double image with values in [0,1].
%
% Example:
%   imageIn = cat(3, ones(2), 0.4*ones(2), zeros(2));
%   imageOut = labkit.image.adjustHueSaturation(imageIn, 30, 25);

    imageIn = labkit.image.ensureRgb(labkit.image.im2double(imageIn));
    imageIn = min(max(imageIn, 0), 1);
    hsvImage = rgb2hsv(imageIn);
    hsvImage(:, :, 1) = mod(hsvImage(:, :, 1) + double(hueDeg) / 360, 1);
    hsvImage(:, :, 2) = hsvImage(:, :, 2) .* (1 + double(saturationPct) / 100);
    hsvImage(:, :, 2) = min(max(hsvImage(:, :, 2), 0), 1);
    imageOut = min(max(hsv2rgb(hsvImage), 0), 1);
end

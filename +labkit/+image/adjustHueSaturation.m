function imageOut = adjustHueSaturation(imageIn, hueDeg, saturationPct)
%ADJUSTHUESATURATION Apply HSV hue and saturation adjustment.
%
% App-facing contract:
%   imageOut = labkit.image.adjustHueSaturation(imageIn, hueDeg, saturationPct)
%
% Inputs:
%   imageIn - numeric image data, normalized internally with toRgbDouble.
%   hueDeg - hue rotation in degrees.
%   saturationPct - saturation scale delta in percent.
%
% Outputs:
%   imageOut - RGB double image clamped to [0, 1].

    hsvImage = rgb2hsv(labkit.image.toRgbDouble(imageIn));
    hsvImage(:, :, 1) = mod(hsvImage(:, :, 1) + double(hueDeg) / 360, 1);
    hsvImage(:, :, 2) = hsvImage(:, :, 2) .* (1 + double(saturationPct) / 100);
    hsvImage(:, :, 2) = min(max(hsvImage(:, :, 2), 0), 1);
    imageOut = min(max(hsv2rgb(hsvImage), 0), 1);
end

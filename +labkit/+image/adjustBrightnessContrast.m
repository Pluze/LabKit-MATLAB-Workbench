function imageOut = adjustBrightnessContrast(imageIn, brightnessPct, contrastPct)
%ADJUSTBRIGHTNESSCONTRAST Apply simple brightness and contrast adjustment.
%
% App-facing contract:
%   imageOut = labkit.image.adjustBrightnessContrast(imageIn, brightnessPct, contrastPct)
%
% Inputs:
%   imageIn - numeric image data, normalized internally to RGB double.
%   brightnessPct - brightness offset in percent of full scale.
%   contrastPct - contrast scale delta in percent around midpoint 0.5.
%
% Outputs:
%   imageOut - RGB double image clamped to [0, 1].

    imageIn = labkit.image.ensureRgb(labkit.image.im2double(imageIn));
    imageIn = min(max(imageIn, 0), 1);
    brightness = double(brightnessPct) / 100;
    contrastScale = max(0, 1 + double(contrastPct) / 100);
    imageOut = (imageIn - 0.5) .* contrastScale + 0.5 + brightness;
    imageOut = min(max(imageOut, 0), 1);
end

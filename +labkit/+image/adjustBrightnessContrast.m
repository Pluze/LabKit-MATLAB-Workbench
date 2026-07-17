function imageOut = adjustBrightnessContrast(imageIn, brightnessPct, contrastPct)
%ADJUSTBRIGHTNESSCONTRAST Apply simple brightness and contrast adjustment.
%
% Usage:
%   imageOut = labkit.image.adjustBrightnessContrast(imageIn, brightnessPct, contrastPct)
%
% Description:
%   Converts imageIn to clamped RGB double, then applies a linear adjustment
%   around mid-gray. For normalized input x, the calculation is
%   (x - 0.5)*(1 + contrastPct/100) + 0.5 + brightnessPct/100. A contrast
%   scale below zero is limited to zero, and final values are clamped to
%   [0,1].
%
%   Positive brightness shifts every channel upward. Positive contrast moves
%   values away from 0.5; negative contrast moves them toward 0.5. A
%   contrastPct of -100 produces a flat mid-gray image before the brightness
%   offset is applied.
%
% Inputs:
%   imageIn - Numeric or logical grayscale, RGB, or multichannel image.
%   brightnessPct - Numeric scalar offset as percent of normalized full scale.
%   contrastPct - Numeric scalar percent change in contrast around 0.5.
%
% Outputs:
%   imageOut - M-by-N-by-3 double image with values in [0,1].
%
% Failure Behavior:
%   Unsupported image classes or channel shapes propagate errors from
%   im2double or ensureRgb. brightnessPct and contrastPct must participate in
%   scalar numeric arithmetic; incompatible MATLAB values raise the
%   originating conversion or array-size error.
%
% Example:
%   imageIn = reshape(linspace(0, 1, 12), 3, 4);
%   imageOut = labkit.image.adjustBrightnessContrast(imageIn, 10, 20);
%
% See also labkit.image.adjustHueSaturation,
%   labkit.image.grayWorldWhiteBalance,
%   labkit.image.im2double

    imageIn = labkit.image.ensureRgb(labkit.image.im2double(imageIn));
    imageIn = min(max(imageIn, 0), 1);
    brightness = double(brightnessPct) / 100;
    contrastScale = max(0, 1 + double(contrastPct) / 100);
    imageOut = (imageIn - 0.5) .* contrastScale + 0.5 + brightness;
    imageOut = min(max(imageOut, 0), 1);
end

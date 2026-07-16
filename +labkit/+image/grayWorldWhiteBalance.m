function imageOut = grayWorldWhiteBalance(imageIn, strengthPct, temperaturePct)
%GRAYWORLDWHITEBALANCE Apply generic gray-world white balance.
%
% Usage:
%   imageOut = labkit.image.grayWorldWhiteBalance(imageIn, strengthPct, temperaturePct)
%
% Description:
%   Estimates one gain per RGB channel so that the three channel means move
%   toward their common mean. strengthPct blends between the original image
%   and the fully balanced result. This is the gray-world assumption: over a
%   representative scene, the average reflected color is expected to be
%   neutral.
%
%   temperaturePct adds a small red offset and subtracts the same blue offset
%   after gain correction. Positive values produce a warmer result; negative
%   values produce a cooler result. The temperature offset is 0.08 times the
%   normalized percentage. Final values are clamped to [0,1].
%
% Inputs:
%   imageIn - Numeric or logical grayscale, RGB, or multichannel image.
%   strengthPct - Numeric scalar blend percentage. Values below 0 become 0;
%                 values above 100 become 100.
%   temperaturePct - Numeric scalar warm/cool adjustment in percent. Use 0
%                    for neutral gray-world balancing.
%
% Outputs:
%   imageOut - M-by-N-by-3 double image with values in [0,1].
%
% Example:
%   imageIn = cat(3, 0.3*ones(4), 0.5*ones(4), 0.7*ones(4));
%   imageOut = labkit.image.grayWorldWhiteBalance(imageIn, 100, 0);

    imageIn = labkit.image.ensureRgb(labkit.image.im2double(imageIn));
    imageIn = min(max(imageIn, 0), 1);
    strength = min(max(double(strengthPct) / 100, 0), 1);
    temperature = double(temperaturePct) / 100;
    channelMean = squeeze(mean(imageIn, [1 2]));
    grayMean = mean(channelMean);
    gains = grayMean ./ max(channelMean, eps);
    gains = reshape(gains, 1, 1, []);
    balanced = imageIn .* gains;
    balanced(:, :, 1) = balanced(:, :, 1) + 0.08 * temperature;
    balanced(:, :, 3) = balanced(:, :, 3) - 0.08 * temperature;
    imageOut = (1 - strength) .* imageIn + strength .* balanced;
    imageOut = min(max(imageOut, 0), 1);
end

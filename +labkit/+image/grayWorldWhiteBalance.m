function imageOut = grayWorldWhiteBalance(imageIn, strengthPct, temperaturePct)
%GRAYWORLDWHITEBALANCE Apply generic gray-world white balance.
%
% App-facing contract:
%   imageOut = labkit.image.grayWorldWhiteBalance(imageIn, strengthPct, temperaturePct)
%
% Inputs:
%   imageIn - numeric image data, normalized internally with toRgbDouble.
%   strengthPct - blend strength from 0 to 100.
%   temperaturePct - optional warm/cool red-blue offset in percent.
%
% Outputs:
%   imageOut - RGB double image clamped to [0, 1].

    imageIn = labkit.image.toRgbDouble(imageIn);
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

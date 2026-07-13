function gray = toLuma(imageIn)
%TOLUMA Convert image data to a luminance plane without toolbox dependencies.
%
% App-facing contract:
%   gray = labkit.image.toLuma(imageIn)
%
% Inputs:
%   imageIn - numeric grayscale or color image data. Integer images are
%       normalized to double through labkit.image.toDouble. Color channels
%       beyond RGB are ignored.
%
% Outputs:
%   gray - double luminance plane. Grayscale inputs are returned as
%       labkit.image.toDouble output. RGB inputs use the Rec.601 luma weights
%       used by MATLAB rgb2gray: [0.2989 0.5870 0.1140].

    if isempty(imageIn)
        gray = [];
        return;
    end
    imageIn = labkit.image.toDouble(imageIn);
    if ndims(imageIn) == 2 || size(imageIn, 3) == 1
        gray = imageIn(:, :, 1);
        return;
    end

    % Rec.601 luma coefficients match MATLAB rgb2gray while avoiding the
    % Image Processing Toolbox dependency.
    rec601LumaWeights = [0.2989 0.5870 0.1140];
    rgb = imageIn(:, :, 1:3);
    gray = rec601LumaWeights(1) .* rgb(:, :, 1) + ...
        rec601LumaWeights(2) .* rgb(:, :, 2) + ...
        rec601LumaWeights(3) .* rgb(:, :, 3);
end

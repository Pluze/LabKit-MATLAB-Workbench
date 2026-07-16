function gray = rgb2gray(rgb)
%RGB2GRAY Convert RGB data using MATLAB's rgb2gray call contract.
%
% Usage:
%   gray = labkit.image.rgb2gray(rgb)
%
% Description:
%   Converts an RGB image with the ITU-R BT.601 luma coefficients 0.2989,
%   0.5870, and 0.1140 for red, green, and blue. The output retains the input
%   numeric class. Integer results therefore use MATLAB's normal cast and
%   rounding behavior.
%
%   For an M-by-3 colormap, each row is converted to one luma value and that
%   value is repeated across three columns. This preserves the colormap shape
%   while removing color. The function does not clamp floating-point input.
%
% Inputs:
%   rgb - Real, nonsparse M-by-N-by-3 RGB image or M-by-3 colormap of class
%         uint8, uint16, int16, single, or double.
%
% Outputs:
%   gray - M-by-N grayscale image or M-by-3 grayscale colormap with the same
%          numeric class as rgb.
%
% Errors:
%   labkit:image:rgb2gray:InvalidShape - rgb is neither an RGB image nor an
%                                       M-by-3 colormap.
%
% Example:
%   rgb = cat(3, ones(2), zeros(2), zeros(2));
%   gray = labkit.image.rgb2gray(rgb);

    narginchk(1, 1);
    validateattributes(rgb, {'uint8', 'uint16', 'int16', 'single', 'double'}, ...
        {'real', 'nonsparse'}, mfilename, 'rgb');
    isColorMap = ismatrix(rgb) && size(rgb, 2) == 3;
    isRgbImage = ndims(rgb) == 3 && size(rgb, 3) == 3;
    if ~(isColorMap || isRgbImage)
        error('labkit:image:rgb2gray:InvalidShape', ...
            'Input must be an M-by-N-by-3 RGB image or an M-by-3 colormap.');
    end

    % Constant: ITU-R BT.601 luma coefficients are the documented MATLAB rgb2gray
    % transform; naming the source keeps these scientific constants auditable.
    rec601LumaWeights = [0.2989 0.5870 0.1140];
    if isColorMap
        converted = double(rgb) * rec601LumaWeights(:);
        converted = repmat(converted, 1, 3);
    else
        converted = rec601LumaWeights(1) .* double(rgb(:, :, 1)) + ...
            rec601LumaWeights(2) .* double(rgb(:, :, 2)) + ...
            rec601LumaWeights(3) .* double(rgb(:, :, 3));
    end
    gray = cast(converted, 'like', rgb);
end

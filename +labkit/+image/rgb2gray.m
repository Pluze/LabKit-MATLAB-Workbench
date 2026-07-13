function gray = rgb2gray(rgb)
%RGB2GRAY Convert RGB data using MATLAB's rgb2gray call contract.
%
% App-facing contract:
%   grayImage = labkit.image.rgb2gray(rgbImage)
%   grayMap = labkit.image.rgb2gray(rgbColorMap)
%
% Inputs:
%   rgb - M-by-N-by-3 RGB image or M-by-3 colormap of class uint8, uint16,
%       int16, single, or double.
%
% Outputs:
%   gray - grayscale image or colormap with the same numeric class as rgb.
%       Conversion uses the Rec.601 luma weights used by MATLAB rgb2gray.

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

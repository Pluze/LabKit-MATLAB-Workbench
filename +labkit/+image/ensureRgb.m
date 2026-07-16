function rgb = ensureRgb(imageData)
%ENSURERGB Return image data with exactly three color channels.
%
% Usage:
%   rgb = labkit.image.ensureRgb(imageData)
%
% Description:
%   Converts grayscale image arrays to RGB by copying the same values into
%   the red, green, and blue channels. RGB input passes through unchanged,
%   and input with more than three channels keeps only the first three. This
%   is useful for removing an alpha or auxiliary channel after image import.
%
%   The function does not change numeric values, normalize intensity, or
%   convert the input class. Empty input is returned with its original empty
%   shape.
%
% Inputs:
%   imageData - Nonsparse numeric or logical M-by-N grayscale, M-by-N-by-1
%               grayscale, M-by-N-by-3 RGB, or M-by-N-by-C array with C
%               greater than three.
%
% Outputs:
%   rgb - Array with the same class and first two dimensions as imageData.
%         Nonempty output has exactly three channels.
%
% Errors:
%   labkit:image:ensureRgb:InvalidChannelCount - Nonempty 3-D input has two
%                                               color channels.
%
% Example:
%   gray = uint8([0 64; 128 255]);
%   rgb = labkit.image.ensureRgb(gray);

    narginchk(1, 1);
    validateattributes(imageData, {'numeric', 'logical'}, {'nonsparse'}, ...
        mfilename, 'imageData');
    if isempty(imageData)
        rgb = imageData;
        return;
    end
    if ismatrix(imageData) || size(imageData, 3) == 1
        rgb = repmat(imageData(:, :, 1), 1, 1, 3);
    elseif size(imageData, 3) >= 3
        rgb = imageData(:, :, 1:3);
    else
        error('labkit:image:ensureRgb:InvalidChannelCount', ...
            'Image data must have one, three, or more than three channels.');
    end
end

function rgb = ensureRgb(imageData)
%ENSURERGB Return image data with exactly three color channels.
%
% App-facing contract:
%   rgb = labkit.image.ensureRgb(imageData)
%
% Inputs:
%   imageData - numeric or logical M-by-N grayscale, M-by-N-by-1 grayscale,
%       M-by-N-by-3 RGB, or M-by-N-by-C data with C greater than three.
%
% Outputs:
%   rgb - data with the same class and first two dimensions as imageData.
%       Grayscale is replicated across three channels and channels after the
%       first three are dropped. Values and numeric class are not changed.

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

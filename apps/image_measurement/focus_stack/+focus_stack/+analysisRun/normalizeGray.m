% App-owned image measurement package helper. Expected caller: owning app callbacks
% and package tests. Inputs, outputs, and side effects are
% documented with the helper function below.
function gray = normalizeGray(imageData)
%NORMALIZEGRAY Convert focus-stack image data to normalized grayscale.
%
% Expected caller:
%   labkit_FocusStack_app private fusion and registration helpers.
%
% Inputs/outputs:
%   Numeric image data, including RGB or 4-D stack slices. Returns a double
%   grayscale image normalized to [0, 1] when possible.
%
% Side effects:
%   None.

    if ndims(imageData) == 4
        imageData = imageData(:, :, :, 1);
    end
    imageData = labkit.image.im2double(imageData);
    if ismatrix(imageData) || size(imageData, 3) == 1
        gray = imageData(:, :, 1);
    else
        gray = labkit.image.rgb2gray(labkit.image.ensureRgb(imageData));
    end
    values = gray(:);
    values = values(isfinite(values));
    if isempty(values)
        gray(:) = 0;
        return;
    end
    mn = min(values);
    mx = max(values);
    if mx > mn
        gray = (gray - mn) ./ (mx - mn);
    else
        gray(:) = 0;
    end
end

% App-owned image measurement package helper. Expected caller: owning app callbacks
% and package tests. Inputs, outputs, and side effects are
% documented with the helper function below.
function imageOut = resizeImageToSize(imageIn, targetSize)
%RESIZEIMAGETOSIZE Resize focus-stack image data to an explicit size.
%
% Expected caller:
%   labkit_FocusStack_app private fusion helpers.
%
% Inputs/outputs:
%   Numeric image data and target size vector. Returns resized image data,
%   preserving a singleton third dimension when one is present in the input.
%
% Side effects:
%   None.

    targetRows = targetSize(1);
    targetCols = targetSize(2);
    if isequal(size(imageIn, 1), targetRows) && isequal(size(imageIn, 2), targetCols)
        imageOut = imageIn;
        return;
    end
    imageOut = resizeLinear(imageIn, [targetRows targetCols]);
    if ndims(imageIn) == 3 && size(imageIn, 3) == 1 && ismatrix(imageOut)
        imageOut = reshape(imageOut, targetRows, targetCols, 1);
    end
end

function imageOut = resizeLinear(imageIn, targetSize)
    targetRows = targetSize(1);
    targetCols = targetSize(2);
    queryRows = linspace(1, size(imageIn, 1), targetRows);
    queryCols = linspace(1, size(imageIn, 2), targetCols);
    [colGrid, rowGrid] = meshgrid(queryCols, queryRows);
    imageOut = zeros(targetRows, targetCols, size(imageIn, 3));
    for channel = 1:size(imageIn, 3)
        imageOut(:, :, channel) = interp2( ...
            1:size(imageIn, 2), 1:size(imageIn, 1), ...
            double(imageIn(:, :, channel)), colGrid, rowGrid, ...
            'linear', NaN);
    end
    imageOut(~isfinite(imageOut)) = 0;
    if isfloat(imageIn)
        imageOut = cast(imageOut, class(imageIn));
    else
        imageOut = cast(round(imageOut), class(imageIn));
    end
end

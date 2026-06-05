% App-private image measurement helper. Expected caller: owning app callbacks
% and workflow tests. Inputs, outputs, and side effects are
% documented with the helper function below.
function imageOut = resizeImageToSize(imageIn, targetSize)
%RESIZEIMAGETOSIZE Resize focus-stack image data to an explicit size.
%
% Expected caller:
%   labkit_FocusStack_app private fusion helpers.
%
% Inputs/outputs:
%   Numeric image data and target size vector. Returns resized image data,
%   preserving singleton channel shape where the previous implementation did.
%
% Side effects:
%   None.

    targetRows = targetSize(1);
    targetCols = targetSize(2);
    if isequal(size(imageIn, 1), targetRows) && isequal(size(imageIn, 2), targetCols)
        imageOut = imageIn;
        return;
    end
    imageOut = imresize(imageIn, [targetRows targetCols], 'bilinear');
    if ndims(imageIn) == 3 && size(imageIn, 3) == 1 && ndims(imageOut) == 2
        imageOut = reshape(imageOut, targetRows, targetCols, 1);
    end
end

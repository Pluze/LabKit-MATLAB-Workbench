% App-private image measurement helper. Expected caller: owning app callbacks
% and workflow tests. Inputs, outputs, and side effects are
% documented with the helper function below.
function imageOut = resizeImageToReference(imageIn, referenceSize)
%RESIZEIMAGETOREFERENCE Resize focus-stack image data to a reference frame.
%
% Expected caller:
%   labkit_FocusStack_app private fusion and registration helpers.
%
% Inputs/outputs:
%   Numeric image data and a reference size vector. Returns the image resized
%   to the reference height and width.
%
% Side effects:
%   None.

    targetSize = referenceSize(1:2);
    if isequal(size(imageIn, 1), targetSize(1)) && isequal(size(imageIn, 2), targetSize(2))
        imageOut = imageIn;
        return;
    end
    imageOut = imresize(imageIn, targetSize);
end

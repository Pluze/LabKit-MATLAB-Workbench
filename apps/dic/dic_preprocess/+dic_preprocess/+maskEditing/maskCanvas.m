% Expected caller: DIC preprocess actions/presenter and unit tests. Inputs are the
% current mask image and reference image. Output is the active uint8 mask canvas,
% initialized to the reference image height and width when empty. Side effects:
% none.

function canvas = maskCanvas(maskImage, referenceImage)
%MASKCANVAS Return the active DIC preprocess ROI mask canvas.

    if isempty(maskImage)
        canvas = zeros(size(referenceImage, 1), size(referenceImage, 2), 'uint8');
    else
        canvas = maskImage;
    end
end

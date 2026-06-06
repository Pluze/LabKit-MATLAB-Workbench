% Expected caller: DIC preprocess runner. Inputs are app UI handles, current
% reference image, current mask image, and title. Side effects: draws the mask
% canvas preview in the bottom axes.

function drawMaskCanvas(ui, referenceImage, maskImage, titleText)
%DRAWMASKCANVAS Render the DIC preprocess ROI mask canvas.

    if isempty(maskImage)
        maskImage = zeros(size(referenceImage, 1), size(referenceImage, 2), 'uint8');
    end
    dic_preprocess.ui.showImage(ui.bottomAxes, ...
        dic_preprocess.ops.maskRgb(maskImage), titleText);
end
